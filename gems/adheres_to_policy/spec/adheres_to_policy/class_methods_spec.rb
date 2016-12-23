#
# Copyright (C) 2014 Instructure, Inc.
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

describe AdheresToPolicy::ClassMethods do
  before(:each) do
    @some_class = Class.new do
      extend AdheresToPolicy::ClassMethods
    end
  end

  it "should filter policy_block through a block filter with set_policy" do
    expect(@some_class).to respond_to(:set_policy)
    expect { @some_class.set_policy(1) }.to raise_error(ArgumentError)
    b = lambda { 1 }
    expect { @some_class.set_policy(&b) }.not_to raise_error
  end

  it "should use set_permissions as set_policy" do
    expect(@some_class).to respond_to(:set_permissions)
    expect { @some_class.set_permissions(1) }.to raise_error(ArgumentError)
    b = lambda { 1 }
    expect { @some_class.set_permissions(&b) }.not_to raise_error
  end

  it "should provide a Policy instance through policy" do
    @some_class.set_policy { 1 }
    expect(@some_class.policy).to be_is_a(AdheresToPolicy::Policy)
  end

  it "should continue to use the same Policy instance (an important check, since this is also a constructor)" do
    @some_class.set_policy { 1 }
    expect(@some_class.policy).to eql(@some_class.policy)
  end

  it "should apply all given policy blocks to the Policy instance" do
    @some_class.set_policy do
      given { |_| true }
      can :read
    end

    @some_class.set_policy do
      given { |_| true }
      can :write
    end

    some_class = @some_class.new
    expect(some_class.grants_right?(nil, :read)).to eq true
    expect(some_class.grants_right?(nil, :write)).to eq true
  end
end
