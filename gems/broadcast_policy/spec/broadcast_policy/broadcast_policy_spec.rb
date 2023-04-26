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

describe BroadcastPolicy do
  let(:policy_harness) do
    Class.new do
      def self.before_save(_)
        true
      end

      def self.after_save(_)
        true
      end

      extend BroadcastPolicy::ClassMethods
    end
  end

  describe ".has_a_broadcast_policy" do
    it "includes instance methods once declared to have one" do
      obj = policy_harness.new
      expect(obj).not_to respond_to(:messages_sent)
      policy_harness.has_a_broadcast_policy
      expect(obj).to respond_to(:messages_sent)
    end
  end

  describe ".set_broadcast_policy" do
    it "handles multiple declarations" do
      policy_harness.class_eval do
        has_a_broadcast_policy
        set_broadcast_policy do
          dispatch :foo
          to
          whenever
        end
        set_broadcast_policy do
          dispatch :bar
          to
          whenever
        end
      end

      policy_list = policy_harness.broadcast_policy_list
      expect(policy_list.find_policy_for("Foo")).not_to be_nil
      expect(policy_list.find_policy_for("Bar")).not_to be_nil
    end
  end

  describe ".set_broadcast_policy!" do
    let(:parent) do
      Class.new(policy_harness) do
        has_a_broadcast_policy
        set_broadcast_policy do
          dispatch :foo
          to
          whenever
        end
      end
    end

    let(:child) do
      Class.new(parent) do
        has_a_broadcast_policy
        set_broadcast_policy! do
          dispatch :bar
          to
          whenever
        end
      end
    end

    it "overwrites any inherited blocks" do
      policy_list = child.broadcast_policy_list
      expect(policy_list.find_policy_for("Foo")).to be_nil
      expect(policy_list.find_policy_for("Bar")).not_to be_nil
    end
  end
end
