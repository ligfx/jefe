require 'jefe'
require 'jefe/version'

class Jefe::CLI < Thor
	
	class_option :procfile, :type => :string, :aliases => "-f", :desc => "Default: Procfile"
	
	desc "start [COMMAND...]", "Start the application"
	
	method_option :env, :type => :string, :aliases => "-e", :desc => "Specify an environment file to load, defaults to .env"
  method_option :port,        :type => :numeric, :aliases => "-p"
  method_option :concurrency, :type => :string,  :aliases => "-c", :banner => '"alpha=5,bar=3"'

	def start(*args)
		error("#{procfile} does not exist") unless File.exists? procfile
		
		engine = Jefe.new
		engine.load File.read(procfile)
		engine.printer = Jefe::ColorPrinter.new
		engine.backend = Jefe::EM.new(engine.printer)
		
		names = args.empty? ? engine.process_types.keys : args
		trap("INT") do
			puts
			engine.stop
		end
		engine.start concurrency(names), port
	end
	
	def help(*args)
		puts "Jefe #{Jefe::VERSION}, the featherweight Procfile manager"
		puts
		super
	end
	
private
	
	def port
		options[:port] || 5000
	end
	
	def concurrency names
		if options[:concurrency]
			options[:concurrency].split(",").reduce({}) do |tot, kv|
				k, v = kv.split "="
				tot[k] = v.to_i
				tot
			end
		else
			names.reduce({}) do |tot, name|
				tot[name] = 1
				tot
			end
		end
	end
	
	def procfile
		options[:procfile] || "Procfile"
	end
	
	def error(message)
		puts "ERROR: #{message}"
		exit 1
	end
	
end
