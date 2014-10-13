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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')
require 'lib/stats'

describe Stats do
  context Stats::Counter do
    def check_stats_with_matchers(c, empty, size, max, min, sum, mean, var, stddev, histogram)
      expect(c.empty?).to empty
      expect(c.size).to size
      expect(c.count).to size
      expect(c.max).to max
      expect(c.min).to min
      expect(c.sum).to sum
      expect(c.total).to sum
      expect(c.mean).to mean
      expect(c.avg).to mean
      expect(c.var).to var
      expect(c.variance).to var
      expect(c.stddev).to stddev
      expect(c.standard_deviation).to stddev
      expect(c.histogram).to histogram
    end

    def check_stats(c, size, max, min, sum, mean, var, histogram)
      check_stats_with_matchers c,
                                (size > 0 ? be_falsey : be_truthy),
                                eql(size),
                                eql(max),
                                eql(min),
                                eql(sum),
                                be_within(0.0000000001).of(mean),
                                be_within(0.0000000001).of(var),
                                be_within(0.0000000001).of(Math::sqrt(var)),
                                eql(histogram)
    end

    it "should be able to initialize with an array" do
      expect{Stats::Counter.new([1,2,4,6,9])}.not_to raise_error
    end
    
    it "should return some basic statistics" do
      c = Stats::Counter.new([1,2,4,9])
      check_stats(c, 4, 9, 1, 16, 4.0, 9.5, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1}})
      c << 6
      check_stats(c, 5, 9, 1, 22, 4.4, 8.24, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1}})
      c << -1
      check_stats(c, 6, 9, -1, 21, 3.5, 139.0/6 - 12.25, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1}})
      c << 3
      check_stats(c, 7, 9, -1, 24, 24.0/7, 148.0/7 - 576.0/49, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1,3.0=>1}})
      c << 21
      check_stats(c, 8, 21, -1, 45, 5.625, 41.984375, {:bin_width => 1.0, :bin_base => 0.0, :data =>{1.0=>1,2.0=>1,4.0=>1,9.0=>1,6.0=>1,-1.0=>1,3.0=>1,21.0=>1}})
    end

    it "should determine standard deviation" do
      c = Stats::Counter.new([9, 2, 5, 4, 12, 7, 8, 11, 9, 3, 7, 4, 12, 5, 4, 10, 9, 6, 9, 4])
      stddev = c.stddev
      expect('%.2f' % stddev).to eq '2.98'

      c = Stats::Counter.new([0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 0.30000000000000004, 
                              0.30000000000000004, 0.30000000000000004])
      stddev = c.stddev
      expect('%.2f' % stddev).to eq '0.00'

      c = Stats::Counter.new
      expect(c.stddev).to be_nil
    end

    it "should return the right things with no values" do
      c = Stats::Counter.new
      check_stats_with_matchers c,
                                be_truthy,
                                eql(0),
                                be_nil,
                                be_nil,
                                eql(0),
                                be_nil,
                                be_nil,
                                be_nil,
                                eql({:bin_width => 1.0, :bin_base => 0.0, :data =>{}})
                                
      c << -5
      check_stats(c, 1, -5, -5, -5, -5.0, 0,{:bin_width => 1.0, :bin_base => 0.0, :data =>{-5.0=>1}})
      c << 5
      check_stats(c, 2, 5, -5, 0, 0.0, 25.0,{:bin_width => 1.0, :bin_base => 0.0, :data =>{-5.0=>1,5.0=>1}})
    end

    it "should support .each, .<<, and .push" do
      c = Stats::Counter.new([1,2,3])
      test = []
      c.each { |item| test << item }
      c << 4
      c.push 5
      c.each { |item| test << item }
      expect(test).to eq [1,2,3,1,2,3,4,5]
    end
    
    it "should put negative numbers in the proper bin in histograms" do
      c = Stats::Counter.new([-1, -0.5, 0, 0.5, 1])
      h = c.histogram
      expect(h).to eq({:bin_width => 1.0, :bin_base => 0.0, :data =>{-1.0=>2, 0.0=>2, 1.0=>1 }})
    end
    
    it "should work with strange bin widths in histogram" do
      c = Stats::Counter.new([-7,-3,0,1,2,3,4,5,6])
      h = c.histogram(bin_width = 2.5, bin_base = 0.0)
      expect(h).to eq({:bin_width=>2.5, :bin_base=>0.0, :data=>{0.0=>3, -5.0=>1, 5.0=>2, -7.5=>1, 2.5=>2}})
    end
    
    it "should work with strange bin bases in histogram" do
      c = Stats::Counter.new([-7,-3,0,1,2,3,4,5,6])
      h = c.histogram(bin_width = 2.5, bin_base = 1.5)
      expect(h).to eq({:bin_width=>2.5, :bin_base=>1.5, :data=>{1.5=>2, 4.0=>3, -3.5=>1, -8.5=>1, -1.0=>2}})
    end
    
    it "should return quarties properly" do
      c = Stats::Counter.new([6,4,2,-7,0,1,3,5,-3,20])
      q = c.quartiles
      expect(q).to eq [-0.75, 2.5, 5.25]
    end
    
    it "should return nils for quartiles when there is no data" do
      c = Stats::Counter.new([])
      q = c.quartiles
      expect(q).to eq [nil, nil, nil]
    end
    
    it "should return a single number for quartiles if that is the only thing in the data" do
      c = Stats::Counter.new([5])
      q = c.quartiles
      expect(q).to eq [5, 5, 5]
    end
    
    it "should return properly for a dataset of length 3" do
       c = Stats::Counter.new([1,2,10])
       q = c.quartiles
       expect(q).to eq [1, 2, 10]
    end

    it "should return properly for a dataset of length 2" do
       c = Stats::Counter.new([1,10])
       q = c.quartiles
       expect(q).to eq [1, 5.5, 10]
    end
    
    
  end
end
