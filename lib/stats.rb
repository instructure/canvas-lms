#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# Adapted from Chris Eppstein's LameStats.  Fixed some errors and wrote my own specs.
module Stats
  class Counter
    include Enumerable
    
    # Takes an optional enumerable argument.
    def initialize(enumerable = nil)
      @hash = Hash.new
      @counts = 0
      @total = 0
      add_all(enumerable) unless enumerable.nil?
    end
    
    # Adds an element in the hash and increments the global count.
    def add_with_count(key,c)
      @hash[key] = (@hash[key] || 0) + c
      @counts += c
      @total += key
    end
    protected :add_with_count
    
    # Adds an enumerable to this object
    def add_all(enumerable)
      enumerable.each {|key| self << key }
    end
    
    # Pushes a new object into the list
    def <<(key)
      add_with_count(key,1)
    end
    alias :push :<<
    
    # The number of unique objects
    def size
      @hash.map{|k, c| c}.sum
    end
    
    # Offers access to the unique values in the collection
    def unique_values
      @hash.keys
    end
    
    # The number of items matching key or nil
    def [](key)
      @hash[key]
    end
    
    # Iterate the unique values of the list only
    def each
      @hash.each_key { |k|
        yield k
      }
    end
    
    def all
      res = []
      @hash.each{|k, c|
        c.times { res << k }
      }
      res
    end
    
    # Delete from the hash all entries found by the block.
    # Example deletes all entries where there is only one value found:
    # @c.delete_if {|k, v| v < 1 }
    def delete_if
      @hash.delete_if do |k,v|
        returning(yield(k,v)) do |deleted|
          @counts -= v if deleted
        end
      end
    end
    
    # The first item
    def first
      [(k = @hash.keys.first),@hash[k]]
    end
    
    # The last item
    def last
      [(k = @hash.keys.last),@hash[k]]
    end
    
    # Iterates over the counts of each value only
    def each_count
      @hash.each_value { |v|
        yield v
      }
    end
    
    # Key, value iterator over each unique value and its count
    def each_with_count
      each { |k|
        yield k, self[k]
      }
    end
    
    # The count of entries, not unique entries
    def count
      @counts
    end
    
    # The cached total entries in the object
    def total
      return @total
    end
    alias :total_entries :total
    
    # The highest count of any one item
    def max_count
      @hash.values.max
    end
    
    def mean
      size > 0 ? total.to_f / size : 0
    end
    
    def variance
      if size > 0
        all.map {|value|
          diff = value - mean
          diff*diff
        }.sum / size.to_f
      else
        0
      end
    end
    
    def standard_deviation
      Math::sqrt(variance)
    end
    
  end
  
end