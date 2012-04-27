# -*-ruby-*-
require File.expand_path('../lib/falsework/meta', __FILE__)
include Falsework

Gem::Specification.new do |gem|
  gem.authors       = [Meta::AUTHOR]
  gem.email         = [Meta::EMAIL]
  gem.description   = 'A primitive scaffold generator for writing CLI programs in Ruby'
  gem.summary       = gem.description + '.'
  gem.homepage      = Meta::HOMEPAGE

  gem.files         = `git ls-files`.split($\)
  gem.files.concat File.read('dynamic.ruby-cli').split("\n")
  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^test/test_.+\.rb})
  gem.name          = Meta::NAME
  gem.version       = Meta::VERSION

  gem.required_ruby_version = '>= 1.9.2'
  gem.extra_rdoc_files      = gem.files.grep(%r{^doc/})
  gem.rdoc_options << '-m' << 'doc/README.rdoc' << '-x' << 'lib/.+/templates/'
  
  gem.add_dependency "open4", "~> 1.3.0"
  gem.add_dependency "rdoc", "~> 3.12"
  gem.add_dependency "bundler", "~> 1.1.3"
  gem.add_dependency "git", "~>1.2.5"

  gem.add_development_dependency "fakefs", "~> 0.4.0"
end
