# -*- encoding: utf-8 -*-
require File.expand_path('../lib/omniauth/cas/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Derek Lindahl"]
  gem.email         = ["dlindahl@customink.com"]
  # gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{CAS Strategy for OmniAuth}
  gem.homepage      = "https://github.com/dlindahl/omniauth-cas"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "omniauth-cas"
  gem.require_paths = ["lib"]
  gem.version       = Omniauth::Cas::VERSION

  gem.add_dependency 'omniauth', '~> 1.0'

  gem.add_development_dependency 'simplecov', '~> 0.5.4'
  gem.add_development_dependency 'rspec', '~> 2.7'
  gem.add_development_dependency 'rack-test', '~> 0.6'

  gem.add_development_dependency 'awesome_print'

end
