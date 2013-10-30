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

describe SortFirst do
  it "should be equal to itself" do
    SortFirst.should == SortFirst
  end

  it "should be less than any string" do
    SortFirst.should < ""
    SortFirst.should < "a"
  end

  it "should be less than any string, commutatively" do
    "".should > SortFirst
    "a".should > SortFirst
  end

  it "should be less than any number" do
    SortFirst.should < 0
    SortFirst.should < -1
    SortFirst.should < 1
  end

  it "should be less than any number, commutatively" do
    0.should > SortFirst
    -1.should > SortFirst
    1.should > SortFirst
  end

  it "should be less than any time or time with zone" do
    SortFirst.should < Time.now
    SortFirst.should < Time.at(0)
    SortFirst.should < Time.at(-1)
    SortFirst.should < Time.zone.now
  end

  it "should be less than any time or time with zone, commutatively" do
    Time.now.should > SortFirst
    Time.at(0).should > SortFirst
    Time.at(-1).should > SortFirst
    Time.zone.now.should > SortFirst
  end

  it "should sort with a few strings" do
    [SortLast, 'a', SortFirst, 'b'].sort.should == [SortFirst, 'a', 'b', SortLast]
  end

  it "should sort with a few numbers" do
    [SortLast, 1, SortFirst, 2].sort.should == [SortFirst, 1, 2, SortLast]
  end

  it "should sort with a few times" do
    a = 5.seconds.ago
    b = Time.now
    [SortLast, a, SortFirst, b].sort.should == [SortFirst, a, b, SortLast]
  end

  it "should work with Array#min" do
    [1, 2, SortFirst].min.should == SortFirst
  end
end
