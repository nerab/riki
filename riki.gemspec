# -*- encoding: utf-8 -*-
require File.expand_path('../lib/riki/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nicholas E. Rabenau"]
  gem.email         = ["nerab@gmx.net"]
  gem.description   = %q{MediaWiki client}
  gem.summary       = %q{riki is a Ruby MediaWiki client}
  gem.homepage      = 'http://github.com/nerab/riki'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "riki"
  gem.require_paths = ["lib"]
  gem.version       = Riki::VERSION

  gem.add_runtime_dependency('rest-client', '~> 1.6')
  gem.add_runtime_dependency('libxml-ruby', '~> 2.3')
  gem.add_runtime_dependency('activesupport', '~> 3.2')
  gem.add_runtime_dependency('rack', '~> 1.4')
  gem.add_development_dependency('vcr', '~> 2.0')
  gem.add_development_dependency('webmock', '~> 1.8')
end
