# -*-ruby-*-

require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'

gem 'rdoc'
require 'rdoc/task'

require_relative 'lib/falsework/meta'
include Falsework

require_relative 'test/rake_git'

#
# Generate dynamic targets
#
require_relative 'test/rake_erb_templates'

ERB_DYN_SKELETON = erb_skeletons(Meta::NAME, 'ruby-naive')
ERB_DYN_SKELETON.each {|k, v|
  file k => [v] do |t|
    erb_make(Meta::NAME, 'ruby-naive', t.name, t.prerequisites[0])
  end
}

desc "Generate some erb templates for ruby-naive template"
task naive: ERB_DYN_SKELETON.keys

CLOBBER.concat ERB_DYN_SKELETON.keys
#pp CLOBBER

#
# Gem staff
#

spec = Gem::Specification.new {|i|
  i.name = Meta::NAME
  i.version = `bin/#{i.name} -V`
  i.summary = "A primitive scaffold generator for writing CLI programs in Ruby"
  i.description = i.summary + '.'
  i.author = Meta::AUTHOR
  i.email = Meta::EMAIL
  i.homepage = Meta::HOMEPAGE
  
  i.platform = Gem::Platform::RUBY
  i.required_ruby_version = '>= 1.9.2'
  i.files = git_ls('.')
  i.files.concat ERB_DYN_SKELETON.keys.map {|i| i.sub(/#{Dir.pwd}\//, '') }

  i.executables = FileList['bin/*'].gsub(/^bin\//, '')
  
  i.test_files = FileList['test/test_*.rb']
  
  i.rdoc_options << '-m' << 'doc/README.rdoc'
  i.extra_rdoc_files = FileList['doc/*']

  i.add_dependency('git', '>=  1.2.5')
  i.add_dependency('open4', '>= 1.2.0')
}

Gem::PackageTask.new(spec).define

task default: [:naive, :repackage]

RDoc::Task.new('html') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb']
  i.rdoc_files.exclude("lib/**/templates/**/*")
end

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

task test: [:naive]
