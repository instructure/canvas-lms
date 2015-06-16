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

describe BroadcastPolicy::SingletonMethods do
  subject do
    Class.new { extend BroadcastPolicy::SingletonMethods }
  end

  describe ".set_broadcast_policy" do
    it "creates a policy list" do
      subject.set_broadcast_policy do
        dispatch :foo
        to       { ['test@example.com'] }
        whenever { true }
      end

      expect(subject.broadcast_policy_list).not_to be(nil)
    end

    it "appends to an existing policy list" do
      subject.set_broadcast_policy do
        dispatch :foo
        to       { ['test@example.com'] }
        whenever { true }
      end

      subject.set_broadcast_policy do
        dispatch :bar
        to       { ['test@example.com'] }
        whenever { true }
      end

      expect(subject.broadcast_policy_list.notifications.length).to eq(2)
    end
  end

  describe ".set_broadcast_policy!" do
    it "overwrites an inherited policy list" do
      subject.set_broadcast_policy do
        dispatch :foo
        to       { ['test@example.com'] }
        whenever { true }
      end

      subject.set_broadcast_policy! do
        dispatch :bar
        to       { ['test@example.com'] }
        whenever { true }
      end

      expect(subject.broadcast_policy_list.notifications.length).to eq(1)
      expect(subject.broadcast_policy_list.notifications[0].dispatch).to eq('Bar')
    end
  end
end
