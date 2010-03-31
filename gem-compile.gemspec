Gem::Specification.new do |s|
	s.platform = Gem::Platform::RUBY
	s.name = "gem-compile"
	s.version = "0.0.2"
	s.summary = "gem-compile, create binary gems from gems with extensions"
	s.author = "FURUHASHI Sadayuki"
	s.email = "frsyuki@users.sourceforge.jp"
	s.homepage = "http://github.com/frsyuki/gem-compile"
	s.has_rdoc = false
	s.extra_rdoc_files = ["README.md", "AUTHORS"]
	s.require_paths = ["lib"]
	s.files = Dir["lib/**/*", "bin/**/*"]
	s.bindir = 'bin'
end
