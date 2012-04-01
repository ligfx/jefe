class Jefe::Loader
	attr_reader :process_types
	def initialize(file)
		@process_types = {}
		file.split("\n").each do |line|
			if line =~ /^([A-Za-z0-9_]+):\s*(.+)$/
				@process_types[$1] = $2
			else
				raise ArgumentError
			end
		end
	end
	def tasks(concurrency, port)
		tasks = []
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