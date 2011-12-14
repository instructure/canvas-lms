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

describe "spec_helper" do

  context "encompass" do
    it "should check values" do
      root = { :key1 => :value1, :key2 => :value2 }
      root.should_not encompass({ :key1 => "value1", :key2 => "value2" })
      root.should encompass({ :key1 => :value1, :key2 => :value2 })
      [root].should_not encompass([{ :key1 => "value1", :key2 => "value2" }])
      [root].should encompass([{ :key1 => :value1, :key2 => :value2 }])
    end

    it "should check array length" do
      root = [{ :key1 => :value1, :key2 => :value2 },
              { :key1 => :value1, :key2 => :value2 },
              { :key1 => :value1, :key2 => :value2 }]
      root.should encompass([{ :key1 => :value1, :key2 => :value2 },
                             { :key1 => :value1, :key2 => :value2 },
                             { :key1 => :value1, :key2 => :value2 }])
      root.should_not encompass([{ :key1 => :value1, :key2 => :value2 },
                                 { :key1 => :value1, :key2 => :value2 }])
      root.should_not encompass([{ :key1 => :value1, :key2 => :value2 },
                                 { :key1 => :value1, :key2 => :value2 },
                                 { :key1 => :value1, :key2 => :value2 },
                                 { :key1 => :value1, :key2 => :value2 }])
    end

    it "should support comparing dictionaries with different types of things" do
      thing_to_check = { :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }
      { :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }.should encompass(thing_to_check)
      { :mkey1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 2, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "mkey2" => 2.0, 3 => :val3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "key2" => 2.1, 3 => :val3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "key2" => 2.0, 2 => :val3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "key2" => 2.0, 3 => :mval3, 4.0 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "key2" => 2.0, 3 => :val3, 4.1 => "val4" }.should_not encompass(thing_to_check)
      { :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "mval4" }.should_not encompass(thing_to_check)
      [{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }].should encompass([thing_to_check])
      [{ :mkey1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 2, "key2" => 2.0, 3 => :val3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "mkey2" => 2.0, 3 => :val3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "key2" => 2.1, 3 => :val3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "key2" => 2.0, 2 => :val3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "key2" => 2.0, 3 => :mval3, 4.0 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.1 => "val4" }].should_not encompass([thing_to_check])
      [{ :key1 => 1, "key2" => 2.0, 3 => :val3, 4.0 => "mval4" }].should_not encompass([thing_to_check])
    end

    it "should support dictionary encompassing" do
      root = { :key1 => :val1, :key2 => :val2, :key3 => :val3 }
      root.should encompass({ :key1 => :val1, :key2 => :val2 })
      root.should encompass({ :key1 => :val1, :key3 => :val3 })
      root.should encompass({ :key2 => :val2, :key3 => :val3 })
      root.should encompass({ :key1 => :val1 })
      root.should encompass({ :key2 => :val2 })
      root.should encompass({ :key3 => :val3 })
      root.should_not encompass({ :key1 => :val1, :key2 => :val2, :key4 => :val4 })
      root.should_not encompass({ :key1 => :val1, :key3 => :val3, :key4 => :val4 })
      root.should_not encompass({ :key2 => :val2, :key3 => :val3, :key4 => :val4 })
      root.should_not encompass({ :key1 => :val1, :key4 => :val4 })
      root.should_not encompass({ :key2 => :val2, :key4 => :val4 })
      root.should_not encompass({ :key3 => :val3, :key4 => :val4 })
      root.should_not encompass({ :key1 => :val2, :key2 => :val2 })
      root.should_not encompass({ :key1 => :val2, :key3 => :val3 })
      root.should_not encompass({ :key2 => :val2, :key3 => :val1 })
      root.should_not encompass({ :key1 => :val2 })
      root.should_not encompass({ :key2 => :val3 })
      root.should_not encompass({ :key3 => :val1 })
    end

    it "should support array encompassing" do
      root = [{:key1 => :val1, :key2 => :val2}, {:key3 => :val3, :key4 => :val4}]
      root.should encompass([{:key1 => :val1}, {:key3 => :val3, :key4 => :val4}])
      root.should encompass([{:key2 => :val2}, {:key3 => :val3}])
      root.should encompass([{:key1 => :val1}, {:key4 => :val4}])
      root.should encompass([{:key2 => :val2}, {:key4 => :val4}])
      root.should encompass([{:key2 => :val2, :key1 => :val1}, {:key4 => :val4}])
      root.should_not encompass([{:key2 => :val1}, {:key4 => :val4}])
      root.should_not encompass([{:key2 => :val1}, {:key4 => :val3}])
      root.should_not encompass([{:key2 => :val2}, {:key4 => :val3}])
      root.should_not encompass([{:key2 => :val2}, {:key4 => :val3}, {:key1 => :val2}])
      root.should_not encompass([{:key4 => :val4}, {:key2 => :val2}])
      root.should_not encompass([{:key2 => :val2}])
      root.should_not encompass([{:key2 => :val2, :key3 => :val3}, {:key4 => :val4}])
    end

  end

end
