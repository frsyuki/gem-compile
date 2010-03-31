require 'rubygems/command'
require 'rubygems/compiler'

class Gem::Commands::CompileCommand < Gem::Command
	def initialize
		super 'compile', 'Create binary gems from gems with extensions',
			:platform => Gem::Platform::CURRENT

		add_option('-p', '--platform PLATFORM', 'Output platform name') do |value, options|
			options[:platform] = value
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

		Gem::Compiler.compile(gem, options[:platform])
	end
end

