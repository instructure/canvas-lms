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

# It's faster to just test this one file, but later, comment these out
# and run it through Normandy. 
# require 'rubygems'
# require 'spec'
# require "#{File.dirname(__FILE__)}/../../lib/stats"
# class Object
#   def returning(value)
#     yield(value)
#     value
#   end
# end

# include Stats

describe Stats do
  # context Counter do
  #   
  #   before do
  #     @a = [1,2,4,6,9]
  #     @c = Counter.new(@a)
  #   end
  #   
  #   it "should be able to initialize with an array" do
  #     lambda{Counter.new(@a)}.should_not raise_error
  #   end
  #   
  #   it "should be able to receive a new value" do
  #     @c << 18
  #     @c.size.should eql(6)
  #     @c[18].should eql(1)
  #   end
  #   
  #   it "should be able to add one enumerable to another" do
  #     @c.add_all [1,2,3]
  #     @c[1].should eql(2)
  #     @c[2].should eql(2)
  #     @c[3].should eql(1)
  #   end
  #   
  #   it "should know the number of unique values in the counter" do
  #     @c.size.should eql(5)
  #     @c << 1
  #     @c.size.should eql(5)
  #     @c << 18
  #     @c.size.should eql(6)
  #   end
  #   
  #   it "should have an iterator over the unique values" do
  #     @c.add_all [1,2,3]
  #     keys = @a | [1,2,3]
  #     @c.each {|key| keys.should be_include(key)}
  #   end
  #   
  #   it "should have an iterator over the counts" do
  #     @c = Counter.new [2,2,4,4,4,4,6,6,6,6,6,6]
  #     values = [2,4,6]
  #     found = []
  #     @c.each_count do |v|
  #       values.should be_include(v)
  #       found << v
  #     end
  #     found.sort.should eql([2,4,6])
  #   end
  #   
  #   it "should have a key, value iterator" do
  #     @c = Counter.new [2,2,4,4,4,4,6,6,6,6,6,6]
  #     values = [2,4,6]
  #     found = []
  #     @c.each_with_count do |k, v|
  #       values.should be_include(k)
  #       values.should be_include(v)
  #       found << v
  #     end
  #     found.sort.should eql([2,4,6])
  #   end
  #   
  #   it "should offer the total count of the object" do
  #     @c.count.should eql(5)
  #     @c << 1
  #     @c.count.should eql(6)
  #     @c.size.should eql(5)
  #   end
  #   
  #   it "should offer the highest mode with max_count" do
  #     @c.add_all [1,1,1]
  #     @c.max_count.should eql(4)
  #   end
  #   
  #   it "should offer a count histogram" do
  #     @c.add_all [1,1,1, 8, 8]
  #     @c.count_histogram.should be_is_a(Histogram)
  #   end
  #   
  #   it "should be filterable with delete_if" do
  #     @c.delete_if {|k, v| k == 1}
  #     @c[1].should be_nil
  #   end
  # 
  #   # I may have ruined that part.
  #   # it "should offer the t-value for each item in the list" do
  #   #   @c = Counter.new [1,2,2,3,3,3,4,4,4,4]
  #   #   found = []
  #   #   expected = [2.68328157299975,0.894427190999916,-0.894427190999916, -2.68328157299975]
  #   #   @c.each_t_value {|t| found << t}
  #   #   found.each_with_index do |e, i|
  #   #     e.should be_close(expected[i], 0.00001)
  #   #   end
  #   # end
  #   
  #   it "should offer the mean and standard deviation of the collection" do
  #     @c = Counter.new [1.0, 2.0, 3.0, 4.0]
  #     @c.mean.should eql(2.5)
  #     @c.standard_deviation.should be_close( 0.612372435695794, 0.000000001)
  #   end
  # end
end
