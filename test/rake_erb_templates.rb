#!/usr/bin/env ruby
# -*-ruby-*-

require_relative '../lib/falsework/mould'

# Search for all files in the project (except .git directory) for the line
#
# /^..? :erb:/
#
# in first 4 lines. If the line is found, the file is considered a
# skeleton for a template. Return a hash {target:template}
def erb_skeletons(local_prj, template)
  line_max = 4
  target = File.absolute_path("lib/#{local_prj}/templates/#{template}")
  r = {}
  skiplist = ['/.git[^i]?', "lib/#{local_prj}/templates", '/html', '/pkg',
              '/test/templates', 'rake_erb_templates.rb']

  Falsework::Mould.traverse('.') {|i|
    next if File.directory?(i)
    next if File.symlink?(i)
    if skiplist.index {|ign| i.match(/\/?#{ign}\/?/) }
#      puts "skipped: #{i}"
     next
    end
#    puts "looking into: #{i}"
    
    File.open(i) {|fp|
      n = 0
      while n < line_max && line = fp.gets
#        puts line
        if line =~ /^..? :erb:/
          t = i.sub(/^.+?\//, '')
          r[target + '/' + t.sub(/#{local_prj}/, '%%@project%%') + '.erb'] = t
          break
        end
        n += 1
      end
    }
  }
  
  r
end

def erb_make(local_prj, template, target, tmplt)
  raw = File.read(tmplt)
  raw.gsub!(/#{local_prj}/, '<%= @project %>')
  raw.gsub!(/#{local_prj.capitalize}/, '<%= @project.capitalize %>')

  mark = <<-EOF

# Don't remove this: <%= #{local_prj.capitalize}::Meta::NAME %>/<%= #{local_prj.capitalize}::Meta::VERSION %>/#{template}/<%= DateTime.now %>
  EOF
  File.open(target, 'w+') {
    |fp| fp.puts raw + ERB.new(mark).result(binding)
  }
end


pp erb_skeletons(Falsework::Meta::NAME, 'naive') if __FILE__ == $0
