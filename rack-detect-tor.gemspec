Gem::Specification.new do |s|
  s.name        = 'rack-detect-tor'
  s.version     = '0.0.2'
  s.licenses    = ['MIT']
  s.summary     = 'Rack middleware for detecting Tor exits'
  s.description = 'Rack middleware for detecting Tor exits'
  s.authors     = ['Warren Guy']
  s.email       = 'warren@guy.net.au'
  s.homepage    = 'https://github.com/warrenguy/rack-detect-tor'

  s.files       = Dir['README.md', 'LICENSE', 'lib/*']

  s.add_dependency 'rack'
  s.add_dependency 'eventmachine'
end
