require 'eventmachine'
require 'jefe/emitter'
require 'micromachine'
require 'pty'

class Jefe::EM
	include Jefe::Emitter

	def initialize(printer)
		@printer = printer
		@fsm = MicroMachine.new(:started).tap do |m|
			m.when(:stop, :started => :stopped)
		end
	end
	
	def start
		@printer.out "system", "starting"
		EM.run do
			yield self
		end
	end

	def stop
		if @fsm.trigger(:stop)
			@printer.out "system", "stopping"
			emit(:stop)
			EM.stop
		end
	end
	
	def add name, command
		@printer.out name, "starting #{command}"

		PTY.spawn(command) do |output, input, pid|
			input.close
			
			@printer.out(name, "started with pid #{pid}")

			c = EM.attach output, ProcessHandler
			m = MicroMachine.new(:started).tap do |m|
				m.when(:stop, :started => :stopped)
			end

			c.on(:data) do |data|
				@printer.out(name, data)
			end

			c.on(:unbind) do
				@printer.out(name, "process terminated")
				m.trigger(:stop)
				self.stop
			end
			
			self.on(:stop) do
				if m.trigger(:stop)
					@printer.out("system", "killing #{name} in #{pid}")
					Process.kill("INT", pid)
				end
			end
		end
	end

	class ProcessHandler < EM::Connection
		include EM::Protocols::LineText2
		include Jefe::Emitter
		
		emits(:data, :from => :receive_line)
		emits(:unbind)
	end
end