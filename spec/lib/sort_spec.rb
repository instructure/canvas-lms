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

describe CanvasSort::First do
  it "should be equal to itself" do
    CanvasSort::First.should == CanvasSort::First
  end

  it "should be less than any string" do
    CanvasSort::First.should < ""
    CanvasSort::First.should < "a"
  end

  it "should be less than any string, commutatively" do
    "".should > CanvasSort::First
    "a".should > CanvasSort::First
  end

  it "should be less than any number" do
    CanvasSort::First.should < 0
    CanvasSort::First.should < -1
    CanvasSort::First.should < 1
  end

  it "should be less than any number, commutatively" do
    0.should > CanvasSort::First
    -1.should > CanvasSort::First
    1.should > CanvasSort::First
  end

  it "should be less than any time or time with zone" do
    CanvasSort::First.should < Time.now
    CanvasSort::First.should < Time.at(0)
    CanvasSort::First.should < Time.at(-1)
    CanvasSort::First.should < Time.zone.now
  end

  it "should be less than any time or time with zone, commutatively" do
    Time.now.should > CanvasSort::First
    Time.at(0).should > CanvasSort::First
    Time.at(-1).should > CanvasSort::First
    Time.zone.now.should > CanvasSort::First
  end

  it "should sort with a few strings" do
    [CanvasSort::Last, 'a', CanvasSort::First, 'b'].sort.should == [CanvasSort::First, 'a', 'b', CanvasSort::Last]
  end

  it "should sort with a few numbers" do
    [CanvasSort::Last, 1, CanvasSort::First, 2].sort.should == [CanvasSort::First, 1, 2, CanvasSort::Last]
  end

  it "should sort with a few times" do
    a = 5.seconds.ago
    b = Time.now
    [CanvasSort::Last, a, CanvasSort::First, b].sort.should == [CanvasSort::First, a, b, CanvasSort::Last]
  end

  it "should work with Array#min" do
    [1, 2, CanvasSort::First].min.should == CanvasSort::First
  end
end
