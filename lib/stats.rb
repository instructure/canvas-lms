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

module Stats
  class Counter
    attr_reader :max, :min, :sum, :sum_of_squares
    alias :total :sum
    
    def initialize(enumerable=[])
      @items = []
      @cache = {}
      @max = nil
      @min = nil
      @sum = 0
      @sum_of_squares = 0
      enumerable.each { |item| self << item }
    end
    
    def each
      @items.each {|i| yield i}
    end
    
    def <<(item)
      raise "invalid value" if item.nil?
      @cache = {}
      @items << item
      if @max.nil? || @min.nil?
        @max = @min = item
      else
        if item > @max
          @max = item
        elsif item < @min
          @min = item
        end
      end
      @sum += item
      @sum_of_squares += item**2
    end
    alias :push :<<
    
    def size; @items.size; end
    alias :count :size
    def empty?; @items.size == 0; end
    def sum_of_squares; @sum_of_squares; end
    def mean; @items.empty? ? nil : (sum.to_f / @items.size); end
    alias :avg :mean
    
    # population variance
    def var
      @items.empty? ? nil : (sum_of_squares.to_f / @items.size) - (mean**2)
    end
    alias :variance :var
    
    # population standard deviation
    def stddev; @items.empty? ? nil : Math::sqrt(variance); end
    alias :standard_deviation :stddev
    
    def histogram(bin_width=1.0,bin_base=0.0)
      # returns a hash representing a histogram
      # divides @items into bin_width sized bins
      # and counts how many items fall into each bin
      # set bin_base to center off something other than zero
      # this would usually be the median for a bell curve
      
      # need floats for the math to work
      bin_width = Float(bin_width)
      bin_base = Float(bin_base)
      ret_val = {:bin_width => bin_width, :bin_base => bin_base}
      bins = {}
      @items.each do |i|
        bin = ((i-bin_base)/bin_width).floor * bin_width + bin_base
        if bins.has_key?(bin)
          bins[bin] = bins[bin] +1
        else
          bins[bin] = 1
        end
      end
      ret_val[:data] = bins
      ret_val
    end  
  end
end