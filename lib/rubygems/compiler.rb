require 'rubygems/format'
require 'rubygems/ext'
require 'rubygems/builder'
require 'rubygems/exceptions'
require 'rubygems/user_interaction'
require 'fileutils'
require 'shellwords'

class Gem::Compiler

	extend Gem::UserInteraction

	def self.compile(gem, platform = Gem::Platform::CURRENT, fat_commands = {})
		gem_dir = "#{File.basename(gem)}.build"
		gem_dir = File.expand_path(gem_dir)

		format = Gem::Format.from_file_by_path(gem)

		spec = format.spec

		if spec.extensions.empty?
			raise Gem::Exception, "There are no extensions to build."
		end

		if spec.platform != Gem::Platform::RUBY
			raise Gem::Exception, "The package seems to be built already."
		end

		format.file_entries.each do |entry, file_data|
			path = entry['path'].untaint
			path = File.expand_path File.join(gem_dir, path)

			FileUtils.rm_rf(path) if File.exists?(path)
			FileUtils.mkdir_p File.dirname(path)

			File.open(path, "wb") do |out|
				out.write file_data
			end

			FileUtils.chmod entry['mode'], path

			say path if Gem.configuration.really_verbose
		end

		ran_rake = false
		start_dir = Dir.pwd
		built_paths = []

		spec.extensions.each do |extension|
			break if ran_rake
			results = []

			builder = case extension
								when /extconf/ then
									Gem::Ext::ExtConfBuilder
								when /configure/ then
									Gem::Ext::ConfigureBuilder
								when /rakefile/i, /mkrf_conf/i then
									ran_rake = true
									Gem::Ext::RakeBuilder
								else
									results = ["No builder for extension '#{extension}'"]
									raise results.last
								end

			begin
				dest_path = File.join(gem_dir, File.dirname(extension))
				Dir.chdir dest_path

				if fat_commands.empty?
					results = builder.build(extension, gem_dir, dest_path, results)

					built_paths.concat Dir.glob("#{dest_path}/**/*")

				else
					ext_files = []

					fat_commands.each_pair do |version, command|
						version_path = File.join(dest_path, version)

						script = <<-EOF
require "rubygems/ext"; puts #{builder}.build(#{extension.dump},#{gem_dir.dump},#{version_path.dump}, [])
						EOF
						script.strip!

						result = `#{command} -e '#{script}'`
						results << result
						if $? != 0
							raise result
						end

						paths = Dir.glob("#{version_path}/**/*")
						files = paths.map {|path| path[File.join(version_path,'').length..-1] }
						ext_files.concat files

						built_paths.concat paths

						FileUtils.rm Dir.glob("**/*.o")    # FIXME
					end

					ext_files.uniq.each do |ext_name|
						ext_basename = ext_name.sub(/\.[^\.]*$/, '')
						rb_path = File.join(dest_path, "#{ext_basename}.rb")
						File.open(rb_path, "w") do |f|
							f.write <<-EOF
require File.join File.dirname(__FILE__), RUBY_VERSION.match(/\\d+\\.\\d+/)[0], #{ext_basename.dump}
							EOF
						end
						built_paths << rb_path
					end

				end

				say results.join("\n") if Gem.configuration.really_verbose

			rescue => ex
				results = results.join "\n"

				File.open('gem_make.out', 'wb') {|f| f.puts results }

				message = <<-EOF
ERROR: Failed to build gem native extension.

				#{results}

Results logged to #{File.join(Dir.pwd, 'gem_make.out')}
				EOF

				raise Gem::Exception, message
			ensure
				Dir.chdir start_dir
			end
		end

		spec.extensions = []

		built_files = built_paths.map {|path| path[File.join(gem_dir,'').length..-1] }
		built_files.reject! {|path| path =~ /\.o$/ }  # FIXME

		spec.files = (spec.files + built_files).sort.uniq
		spec.platform = platform if platform

		Dir.chdir gem_dir
		begin
			out_fname = Gem::Builder.new(spec).build
			FileUtils.mv(out_fname, start_dir)
		ensure
			Dir.chdir start_dir
		end
	end
end

