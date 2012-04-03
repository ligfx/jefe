class Jefe::Loader
	attr_reader :process_types
	def initialize(file)
		@process_types = Hash[file.lines.map &method(:decompose_line)]
	end
	def decompose_line line
		if line =~ /^([A-Za-z0-9_]+):\s*(.+)$/
			[$1, $2]
		else
			raise ArgumentError
		end
	end
	def scale(concurrency, port)
		tasks = []
		if concurrency.empty?
			concurrency = Hash[process_types.keys.map { |name| [name, 1] }]
		end
		concurrency.each do |(name, num)|
			num.times do |i|
				env = { "PORT" => (port + i) }
				command = @process_types[name].gsub(/\$(\w+)/) { env[$1] || ENV[$1] }
				tasks.push ["#{name}.#{i}", command]
			end
			port += 100
		end
		tasks
	end
end