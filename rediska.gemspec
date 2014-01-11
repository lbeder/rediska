$:.push File.expand_path('../lib', __FILE__)
require 'rediska/version'

Gem::Specification.new do |s|
  s.name        = 'rediska'
  s.version     = Rediska::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Leonid Beder']
  s.email       = ['leonid.beder@gmail.com']
  s.license     = 'MIT'
  s.homepage    = 'https://github.com/lbeder/rediska'
  s.summary     = 'A light-weighted redis driver for testing, development, and minimal environments'
  s.description = 'A light-weighted redis driver for testing, development, and minimal environments,
    which supports various data storage strategies.'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency     'redis', '~> 3.0.0'
  s.add_development_dependency 'rspec', '~> 2.14'
  s.add_development_dependency 'coveralls'
  s.add_development_dependency 'rake'
end
