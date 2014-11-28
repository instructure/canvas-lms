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
    expect(CanvasSort::First).to eq CanvasSort::First
  end

  it "should be less than any string" do
    expect(CanvasSort::First).to be < ""
    expect(CanvasSort::First).to be < "a"
  end

  it "should be less than any string, commutatively" do
    expect("").to be > CanvasSort::First
    expect("a").to be > CanvasSort::First
  end

  it "should be less than any number" do
    expect(CanvasSort::First).to be < 0
    expect(CanvasSort::First).to be < -1
    expect(CanvasSort::First).to be < 1
  end

  it "should be less than any number, commutatively" do
    expect(0).to be > CanvasSort::First
    expect(-1).to be > CanvasSort::First
    expect(1).to be > CanvasSort::First
  end

  it "should be less than any time or time with zone" do
    expect(CanvasSort::First).to be < Time.now
    expect(CanvasSort::First).to be < Time.at(0)
    expect(CanvasSort::First).to be < Time.at(-1)
    expect(CanvasSort::First).to be < Time.zone.now
  end

  it "should be less than any time or time with zone, commutatively" do
    expect(Time.now).to be > CanvasSort::First
    expect(Time.at(0)).to be > CanvasSort::First
    expect(Time.at(-1)).to be > CanvasSort::First
    expect(Time.zone.now).to be > CanvasSort::First
  end

  it "should sort with a few strings" do
    expect([CanvasSort::Last, 'a', CanvasSort::First, 'b'].sort).to eq [CanvasSort::First, 'a', 'b', CanvasSort::Last]
  end

  it "should sort with a few numbers" do
    expect([CanvasSort::Last, 1, CanvasSort::First, 2].sort).to eq [CanvasSort::First, 1, 2, CanvasSort::Last]
  end

  it "should sort with a few times" do
    a = 5.seconds.ago
    b = Time.now
    expect([CanvasSort::Last, a, CanvasSort::First, b].sort).to eq [CanvasSort::First, a, b, CanvasSort::Last]
  end

  it "should work with Array#min" do
    expect([1, 2, CanvasSort::First].min).to eq CanvasSort::First
  end
end
