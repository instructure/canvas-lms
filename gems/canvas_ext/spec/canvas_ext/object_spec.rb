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

require 'spec_helper'

describe "Object#try_rescue" do
  it "should return nil when nil is the receiver" do
    expect(nil.try_rescue(:asdf)).to be_nil
    expect(nil.try_rescue(:asdf){}).to be_nil
  end

  it "should call the method" do
    expect("1".try_rescue(:to_i)).to eq 1
  end

  it "should pass along the block" do
    expect([1, 2, 3].try_rescue(:map){|i|i+1}).to eq [2, 3, 4]
  end

  it "should rescue nil" do
    expect("1".try_rescue(:asdf)).to be_nil
    expect([1, 2, 3].try_rescue(:asdf){|i|i+1}).to be_nil
  end
end
