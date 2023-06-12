# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
    alias_method :total, :sum

    def initialize(enumerable = [])
      @items = []
      @cache = {}
      @max = nil
      @min = nil
      @sum = 0
      @sum_of_squares = 0
      enumerable.each { |item| self << item }
    end

    def each(&)
      @items.each(&)
    end

    def <<(item)
      raise "invalid value" if item.nil?

      @cache = {}
      @items << item
      if @max.nil? || @min.nil?
        @max = @min = item
      elsif item > @max
        @max = item
      elsif item < @min
        @min = item
      end
      @sum += item
      @sum_of_squares += item**2
    end
    alias_method :push, :<<

    def size
      @items.size
    end
    alias_method :count, :size
    def empty?
      @items.empty?
    end

    def mean
      @items.empty? ? nil : (sum.to_f / @items.size)
    end
    alias_method :avg, :mean

    # population variance
    def var
      return nil if @items.empty?

      results = (sum_of_squares.to_f / @items.size) - (mean**2)
      [0, results].max
    end
    alias_method :variance, :var

    # population standard deviation
    def stddev
      @items.empty? ? nil : Math.sqrt(variance)
    end
    alias_method :standard_deviation, :stddev

    def quartiles
      # returns the 1st quartile, 2nd quartile (median),
      # and 3rd quartile for the data

      # NOTE: methodology for determining quartiles
      # is not universally agreed upon (oddly enough)
      # this method picks medians and gets
      # results that are universally agreed upon.
      # the method also give good results for quartiles
      # when the sample size is small.  When it is large
      # then any old method will be close enough, but
      # this one is very good
      # method is summarized well here:
      # http://www.stat.yale.edu/Courses/1997-98/101/numsum.htm
      if @items.empty?
        return [nil, nil, nil]
      end

      sorted_items = @items.sort
      vals = []

      # 1st Q
      n = ((sorted_items.length + 1) / 4.0) - 1
      if n < 0
        # n must be in [0,n]
        n = 0
      end
      weight = 1.0 - (n - n.to_i)
      n = n.to_i
      vals << get_weighted_nth(sorted_items, n, weight)

      # 2nd Q
      n = ((sorted_items.length + 1) / 2.0) - 1
      weight = 1.0 - (n - n.to_i)
      n = n.to_i
      vals << get_weighted_nth(sorted_items, n, weight)

      # 3rd Q
      n = ((sorted_items.length + 1) * 3.0 / 4.0) - 1
      if n > sorted_items.length - 1
        # n must be in [0,n]
        n = sorted_items.length - 1
      end
      weight = 1.0 - (n - n.to_i)
      n = n.to_i
      vals << get_weighted_nth(sorted_items, n, weight)

      vals
    end

    def histogram(bin_width = 1.0, bin_base = 0.0)
      # returns a hash representing a histogram
      # divides @items into bin_width sized bins
      # and counts how many items fall into each bin
      # set bin_base to center off something other than zero
      # this would usually be the median for a bell curve

      # need floats for the math to work
      bin_width = Float(bin_width)
      bin_base = Float(bin_base)
      ret_val = { bin_width:, bin_base: }
      bins = {}
      @items.each do |i|
        bin = (((i - bin_base) / bin_width).floor * bin_width) + bin_base
        bins[bin] = if bins.key?(bin)
                      bins[bin] + 1
                    else
                      1
                    end
      end
      ret_val[:data] = bins
      ret_val
    end

    private

    def get_weighted_nth(sorted_items, n, weight)
      n1 = sorted_items[n].to_f
      val = n1 * weight
      unless n == sorted_items.length - 1
        n2 = sorted_items[n + 1].to_f
        val += n2 * (1 - weight)
      end
      val
    end
  end
end
