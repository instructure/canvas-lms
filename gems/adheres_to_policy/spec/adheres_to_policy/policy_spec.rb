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

describe AdheresToPolicy::Policy, "set_policy" do
  it "should take a block" do
    lambda {
      Class.new do
        extend AdheresToPolicy::ClassMethods
        set_policy { 1 + 1 }
      end
    }.should_not raise_error
  end

  it "should allow multiple calls" do
    lambda {
      Class.new do
        extend AdheresToPolicy::ClassMethods

        3.times do
          set_policy { 1 + 1 }
        end
      end
    }.should_not raise_error
  end

  context "available_rights" do
    it "should return all available rights" do
      example_class = Class.new do
        extend AdheresToPolicy::ClassMethods

        set_policy {
          given { |_| true }
          can :read, nil

          given { |_| true }
          can :write, :read
        }
      end

      expect(example_class.policy.available_rights).to eq [:read, :write]
    end
  end
end
