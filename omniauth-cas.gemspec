# frozen_string_literal: true

require File.expand_path('lib/omniauth/cas/version', __dir__)

Gem::Specification.new do |gem|
  gem.authors       = ['Derek Lindahl']
  gem.email         = ['dlindahl@customink.com']
  gem.summary       = 'CAS Strategy for OmniAuth'
  gem.description   = gem.summary
  gem.homepage      = 'https://github.com/dlindahl/omniauth-cas'

  gem.files         = Dir.glob('{CHANGELOG.md,LICENSE,README.md,lib/**/*.rb}', File::FNM_DOTMATCH)
  gem.name          = 'omniauth-cas'
  gem.require_paths = ['lib']
  gem.version       = OmniAuth::Cas::VERSION

  gem.metadata = {
    'bug_tracker_uri' => 'https://github.com/dlindahl/omniauth-cas/issues',
    'changelog_uri' => 'https://github.com/dlindahl/omniauth-cas/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://dlindahl.github.io/omniauth-cas/',
    'homepage_uri' => 'https://github.com/dlindahl/omniauth-cas',
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/dlindahl/omniauth-cas',
    'wiki_uri' => 'https://github.com/dlindahl/omniauth-cas/wiki'
  }

  gem.required_ruby_version = '>= 3.0'

  gem.add_dependency 'addressable', '~> 2.8'
  gem.add_dependency 'nokogiri',    '~> 1.12'
  gem.add_dependency 'omniauth',    '>= 1.9', '< 3.0'
end
