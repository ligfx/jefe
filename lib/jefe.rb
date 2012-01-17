require 'eventmachine'
require 'pty'
require 'term/ansicolor'
require 'thor'

class Jefe
	def initialize
		@process_types = {}
	end
	attr_accessor :backend, :printer, :process_types
	def load file
		file.split("\n").each do |line|
			if line =~ /^([A-Za-z0-9_]+):\s*(.+)$/
				add_process_type $1, $2
			end
		end
	end
	def add_process_type name, command
		@process_types[name] = command
	end
	
	def start concurrency, port		
		processes = []
		concurrency.each do |(name, num)|
			num.times do |i|
				env = { "PORT" => (port + i) }
				command = self.process_types[name].gsub(/\$(\w+)/) { env[$1] || ENV[$1] }
				processes.push ["#{name}.#{i}", command]
			end
			port += 100
		end
		
		self.printer.out "system", "starting"
		self.backend.start do |b|
			processes.each do |(name, command)|
				self.printer.out name, "starting #{command}"
				b.add name, command
			end
		end
		
	end
	
	def stop
		self.printer.out "system", "stopping"
		self.backend.stop
	end
end

class Jefe::ColorPrinter
	Color = Term::ANSIColor
	COLORS = [:cyan, :yellow, :green, :magenta, :red]
	def initialize
		@colors ||= {"system" => :white}
		@longest_seen = 0
	end
	def out name, command
		type = name.match(/^([A-Za-z0-9_]+).\d+$/) ? $1 : name
		@colors[type] = COLORS.shift.tap {|c| COLORS.push c} unless @colors[type]
		color = @colors[type]
		@longest_seen = name.size if name.size > @longest_seen
		puts "#{Color.send color} #{Time.now.strftime '%H:%M:%S'} #{name}#{' ' * (@longest_seen - name.length)} | #{Color.reset}#{command.chomp}"
	end
end

class Jefe::EM
	def initialize(printer)
		@printer = printer
		@connections = []
	end
	
	def start
		EM.run do
			yield self
		end
	end
	
	def add name, command
		PTY.spawn(command) do |output, input, pid|
			input.close
			
			EM.attach output, ProcessHandler do |c|
				c.init name, pid, @printer
				bind(c)
			end
		end
	end
	
	def stop
		@connections.each &:stop
		EM.stop
	end
	
	def bind c
		@connections.push c
		c.engine = self
	end
	
	def unbind c
		@connections.delete c
		stop if @connections.empty?
	end
	
	class ProcessHandler < EM::Connection
		include EM::Protocols::LineText2
		attr_accessor :engine, :name, :pid, :printer
		
		def init name, pid, printer
			self.name = name
			self.pid = pid
			self.printer = printer
			
			out "started with pid #{self.pid}"
		end
		
		def receive_line data
			out data
		end
		
		def unbind
			out "process terminated"
			self.engine.unbind self
		end
		
		def out msg
			self.printer.out self.name, msg
		end
		
		def to_s
			"#{self.name} in pid #{self.pid}"
		end
		
		def stop
			self.printer.out "system", "killing #{self}"
			Process.kill("INT", self.pid)
		end
	end
end