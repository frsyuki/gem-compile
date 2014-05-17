require 'rubygems/format'
require 'rubygems/ext'
require 'rubygems/builder'
require 'rubygems/exceptions'
require 'rubygems/user_interaction'
require 'fileutils'
require 'shellwords'

class Gem::Compiler

	extend Gem::UserInteraction

	def self.compile(gem, platform = Gem::Platform::CURRENT, fat_commands = {}, add_files = [])
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

		dest_path = File.join(gem_dir, spec.require_paths.first)
		FileUtils.rm_rf(dest_path) if File.exists?(dest_path)

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
				build_dir = File.join(gem_dir, File.dirname(extension))
				extension = File.expand_path(extension)
				Dir.chdir build_dir

				if fat_commands.empty?
					results = builder.build(extension, gem_dir, dest_path, results)

				else
					ext_files = []

					fat_commands.each_pair do |version, command|
						dest_version_path = File.join(dest_path, version)

						script = %'require "rubygems/ext"; puts #{builder}.build(#{extension.dump},#{gem_dir.dump},#{dest_version_path.dump}, [])'

						result = `#{command} -e '#{script}'`
						results << result
						raise result if $? != 0

						FileUtils.rm Dir.glob("**/*.o")    # FIXME
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

		unless fat_commands.empty?
			fat_ext_files = fat_commands.keys.uniq.map do |version|
				dest_version_path = File.join(dest_path, version)
				fat_ext_paths = Dir.glob("#{dest_version_path}/**/*")
				fat_ext_paths.map {|path| path[File.join(dest_version_path,'').length..-1] }
			end.flatten.uniq

			fat_ext_files.uniq.each do |ext_file|
				ext_name = ext_file.sub(/\.[^\.]*$/, '')
				rb_path = File.join(dest_path, "#{ext_name}.rb")
				File.open(rb_path, "w") do |f|
					f.write <<-EOF
require File.join File.dirname(__FILE__), RUBY_VERSION.match(/\\d+\\.\\d+/)[0], #{ext_name.dump}
					EOF
				end
			end
		end

		built_paths = Dir.glob("#{dest_path}/**/*")
		built_files = built_paths.map {|path| path[File.join(gem_dir,'').length..-1] }
		built_files.reject! {|path| path =~ /\.o$/ }  # FIXME

		result_add_files = []

		Dir.chdir gem_dir
		begin
			add_files.each do |f_or_d|
				if File.file? f_or_d
					result_add_files << f_or_d
				else
					Find.find(f_or_d) do |fpath|
						result_add_files << fpath if File.file? fpath
					end
				end
			end
		ensure
			Dir.chdir start_dir
		end

		spec.files = (spec.files + built_files + result_add_files).sort.uniq
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

