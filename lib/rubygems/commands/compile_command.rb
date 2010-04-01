require 'rubygems/command'
require 'rubygems/compiler'

class Gem::Commands::CompileCommand < Gem::Command
	def initialize
		super 'compile', 'Create binary gems from gems with extensions',
			:platform => Gem::Platform::CURRENT,
			:fat => ""

		add_option('-p', '--platform PLATFORM', 'Output platform name') do |value, options|
			options[:platform] = value
		end

		add_option('-f', '--fat VERSION:RUBY,...', 'Create fat binary (e.g. --fat 1.8:ruby,1.9:ruby19)') do |value, options|
			options[:fat] = value
		end
	end

	def arguments # :nodoc:
		"GEMFILE       name of gem to compile"
	end

	def usage # :nodoc:
		"#{program_name} GEMFILE"
	end

	def execute
    gem = options[:args].shift

    unless gem then
			raise Gem::CommandLineError,
						"Please specify a gem name or file on the command line"
    end

		fat_commands = {}
		options[:fat].split(',').each do |ver_cmd|
			ver, cmd = ver_cmd.split(':', 2)
			unless ver =~ /^\d+\.\d+$/ then
				raise Gem::CommandLineError,
							"Invalid version string #{ver.dump}"
			end
			fat_commands[ver] = cmd
		end

		Gem::Compiler.compile(gem, options[:platform], fat_commands)
	end
end

