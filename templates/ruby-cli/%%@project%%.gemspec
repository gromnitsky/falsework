# -*-ruby-*-

require File.expand_path('../lib/<%= @project %>/meta', __FILE__)
include <%= @camelcase %>

Gem::Specification.new do |gem|
  gem.authors       = [Meta::AUTHOR]
  gem.email         = [Meta::EMAIL]
  gem.description   = 'TO DO: write a description'
  gem.summary       = gem.description + '.'
  gem.homepage      = Meta::HOMEPAGE

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^test/test_.+\.rb})
  gem.name          = Meta::NAME
  gem.version       = Meta::VERSION

  gem.required_ruby_version = '>= 1.9.2'
  gem.extra_rdoc_files      = gem.files.grep(%r{^doc/})
  gem.rdoc_options << '-m' << 'doc/README.rdoc'

  gem.add_dependency "open4", "~> 1.3.0"
  gem.add_dependency "rdoc", "~> 4.0.0"
  gem.add_dependency "bundler", ">= 1.3"
end
