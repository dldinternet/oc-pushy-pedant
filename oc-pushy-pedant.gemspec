Gem::Specification.new do |s|
  s.name        = 'oc-pushy-pedant'
  s.version     = '1.0.9'
  s.date        = '2014-12-04'
  s.summary     = "API tests for Opscode's Private Chef Pushy Server"
  s.description = "API tests for Opscode's Private Chef Pushy Server; requires Pedant to actually run"
  s.authors     = ["Doug Triggs", "John Keiser"]
  s.email       = 'doug@opscode.com'
  s.files       = Dir['spec/**/*_spec.rb'] + Dir['lib/**/*.rb']
  s.homepage    = 'http://opscode.com'
  s.require_paths = ['spec', 'lib']
end
