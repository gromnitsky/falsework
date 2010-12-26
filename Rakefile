# -*-ruby-*-

require 'rake'
require 'rake/gempackagetask'
require 'rake/clean'
require 'rake/rdoctask'
require 'rake/testtask'

require_relative 'test/rake_git'
NAME = 'falsework'

#
# Generate dynamic targets
#
require_relative 'test/rake_erb_templates'

ERB_DYN_SKELETON = erb_skeletons(NAME, 'naive')
ERB_DYN_SKELETON.each {|k, v|
  file k => [v] do |t|
    erb_make(NAME, 'naive', t.name, t.prerequisites[0])
  end
}

desc "Generate some erb templates for naive template"
task naive: ERB_DYN_SKELETON.keys

CLOBBER.concat ERB_DYN_SKELETON.keys
#pp CLOBBER

#
# Gem staff
#

spec = Gem::Specification.new {|i|
  i.name = NAME
  i.version = `bin/#{i.name} -V`
  i.summary = "A primitive scaffold generator for writing CLI programs in Ruby."
  i.author = 'Alexander Gromnitsky'
  i.email = 'alexander.gromnitsky@gmail.com'
  i.homepage = "http://github.com/gromnitsky/#{i.name}"
  i.platform = Gem::Platform::RUBY
  i.required_ruby_version = '>= 1.9.2'
  i.files = git_ls('.')
  i.files.concat ERB_DYN_SKELETON.keys.map {|i| i.sub(/#{Dir.pwd}\//, '') }

  i.executables = FileList['bin/*'].gsub(/^bin\//, '')
  i.default_executable = i.name
  
  i.test_files = FileList['test/test_*.rb']
  
  i.rdoc_options << '-m' << 'doc/README.rdoc'
  i.extra_rdoc_files = FileList['doc/*']

  i.add_dependency('git', '>=  1.2.5')
  i.add_dependency('open4', '>= 1.0.1')
}

Rake::GemPackageTask.new(spec).define

task default: [:naive, :repackage]

Rake::RDocTask.new('doc') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb']
  i.rdoc_files.exclude("lib/**/templates")
end

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

task test: [:naive]
