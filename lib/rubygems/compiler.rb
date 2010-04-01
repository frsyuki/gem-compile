require 'rubygems/format'
require 'rubygems/ext'
require 'rubygems/builder'
require 'rubygems/exceptions'
require 'rubygems/user_interaction'
require 'fileutils'

class Gem::Compiler

	extend Gem::UserInteraction

	def self.compile(gem, platform = Gem::Platform::CURRENT)
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
		dest_paths = []

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
									nil
								end

			begin
				dest_path = File.join(gem_dir, File.dirname(extension))
				dest_paths << dest_path
				Dir.chdir dest_path
				results = builder.build(extension, gem_dir, dest_path, results)

				say results.join("\n") if Gem.configuration.really_verbose

			rescue => ex
				results = results.join "\n"

				File.open('gem_make.out', 'wb') { |f| f.puts results }

				message = <<-EOF
ERROR: Failed to build gem native extension."

				#{results}

Results logged to #{File.join(Dir.pwd, 'gem_make.out')}
				EOF

				raise Gem::Exception, message
			ensure
				Dir.chdir start_dir
			end
		end

		spec.extensions = []

		basedir = File.join gem_dir, ""
		built_files = dest_paths.map do |dest_path|
			Dir.glob("#{dest_path}/**/*").map {|path| path[basedir.length..-1] }
		end.flatten.uniq
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

