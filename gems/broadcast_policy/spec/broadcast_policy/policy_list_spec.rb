# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe BroadcastPolicy::PolicyList do
  describe ".new" do
    it "creates a new notification list" do
      expect(subject.notifications).to eq([])
    end
  end

  describe "#populate" do
    it "stores notification policies" do
      subject.populate do
        dispatch :foo
        to       { "test@example.com" }
        whenever { true }
      end

      expect(subject.notifications.length).to eq(1)
    end
  end

  describe "#find_policy_for" do
    it "returns the named policy" do
      subject.populate do
        dispatch :foo
        to       { "test@example.com" }
        whenever { true }
      end

      expect(subject.find_policy_for("Foo")).not_to be_nil
    end
  end

  describe "#broadcast" do
    it "calls broadcast on each notification" do
      subject.populate do
        dispatch :foo
        to       { "test@example.com" }
        whenever { true }
      end

      record = "record"
      expect(subject.notifications[0]).to receive(:broadcast).with(record)
      subject.broadcast(record)
    end
  end

  describe "#dispatch" do
    it "saves new notifications" do
      subject.dispatch(:foo)
      expect(subject.notifications).not_to be_nil
    end

    it "ignores existing notifications" do
      subject.dispatch(:foo)
      subject.dispatch(:foo)
      expect(subject.notifications.length).to eq(1)
    end
  end
end
