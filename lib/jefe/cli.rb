require 'thor'

require 'jefe/color_printer'
require 'jefe/em'
require 'jefe/loader'
require 'jefe/version'

class Jefe::CLI < Thor
	
	class_option :procfile, :type => :string, :aliases => "-f", :desc => "Default: Procfile"
	
	desc "start [COMMAND...]", "Start the application"
	default_task :start
	
	method_option :env, :type => :string, :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
	method_option :port,        :type => :numeric, :aliases => "-p"
	method_option :concurrency, :type => :string,  :aliases => "-c", :banner => '"alpha=5,bar=3"'

	def start(*args)
		if ! File.exists? procfile
			help
			error("#{procfile} does not exist")
		end
		
		loader = Jefe::Loader.new File.read procfile
		engine = Jefe::EM.new(Jefe::ColorPrinter.new)
		
		trap("INT") do
			puts
			engine.stop
		end
		engine.start do
			loader.scale(concurrency_options(args), port).each do |(name, command)|
				engine.add name, command
			end
		end
	end
	
	def help(*args)
		puts "Jefe #{Jefe::VERSION}, the featherweight Procfile manager"
		puts "By default, calling `jefe' acts as `jefe start'. Your other options are:"
		puts
		super
	end
	
private
	
	def port
		options[:port] || 5000
	end
	
	def concurrency_options names
		ret = {}
		options[:concurrency].to_s.split(",").each do |kv|
			k, v = kv.split "="
			ret[k] = v.to_i
		end
		ret
	end
	
	def procfile
		options[:procfile] || "Procfile"
	end
	
	def error(message)
		puts "ERROR: #{message}"
		exit 1
	end
	
end
