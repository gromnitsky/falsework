module Falsework
  module Utils
    extend self

    def self.all_set? t
      return false unless t
      
      if t.is_a?(Array)
        return false if t.size == 0
        
        t.each {|i|
          return false unless i
          return false if i.to_s.strip.size == 0
        }
      end
      
      return false if t.to_s.strip.size == 0
      true
    end
    
    
  end
end
