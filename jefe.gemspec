spec = Gem::Specification.new do |s|
	s.name = "jefe"
	s.version = "1.0.0"
	s.summary = "The featherweight Procfile manager"
	s.description = "Through the magic of Thor and EventMachine, we give you the equivalent to Foreman in just 200 lines of sweet unadulterated Ruby."
	
	s.author = "Michael Maltese"
	s.email = "michael.maltese@pomona.edu"
	s.homepage = "http://github.com/mikemaltese/jefe"

	s.add_dependency "eventmachine"
	s.add_dependency "term-ansicolor"
	s.add_dependency "thor"

	s.executable = "jefe"
	s.require_path = ["lib"]
	s.files = Dir['lib/**/*'] + Dir['bin/*'] + ["README.md"]
end