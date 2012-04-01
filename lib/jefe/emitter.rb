module Jefe::Emitter
	def self.included(klass)
		klass.extend(ClassMethods)
	end
	def callbacks
		@callbacks ||= {}
	end
	def on(name, &cb)
		callbacks[name] ||= []
		callbacks[name] << cb
	end
	def emit(name, *args)
		callbacks[name] ||= []
		callbacks[name].each { |cb| cb.call(*args) }
	end
	module ClassMethods
		def emits(name, opts={})
			from = opts[:from] || name
			define_method(from) do |*args|
				emit(name, *args)
			end
		end
	end
end