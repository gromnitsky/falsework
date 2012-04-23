# -*-ruby-*-

require 'rake/clean'
require 'rake/testtask'
require 'bundler/gem_tasks'
gem 'rdoc'
require 'rdoc/task'

# Generate dynamic targets
require_relative 'test/rake_erb_templates'

ERB_DYN_SKELETON = erb_skeletons(Meta::NAME, 'ruby-cli')
ERB_DYN_SKELETON.each {|k, v|
  file k => [v] do |t|
    erb_make(Meta::NAME, 'ruby-cli', t.name, t.prerequisites[0])
  end
}

desc "Generate ruby-cli dynamic files"
file 'dynamic.ruby-cli' => ERB_DYN_SKELETON.keys do |t|
  File.open(t.name, 'w+') {|fp|
    ERB_DYN_SKELETON.keys.map {|i|
      fp.puts i.sub(/#{Dir.pwd}\//, '')
    }
  }
end

# add rubi-cli dynamic files to a clobber target
CLOBBER.concat ERB_DYN_SKELETON.keys

task default: [:test]

RDoc::Task.new('html') do |i|
  i.main = 'doc/README.rdoc'
  i.rdoc_files = FileList['doc/*', 'lib/**/*.rb']
  i.rdoc_files.exclude 'lib/**/templates/**/*'
end

Rake::TestTask.new do |i|
  i.test_files = FileList['test/test_*.rb']
end

task test: ['dynamic.ruby-cli']
task build: ['dynamic.ruby-cli']
