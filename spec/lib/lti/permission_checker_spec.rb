# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../../lti2_spec_helper"

describe Lti::PermissionChecker do
  include_context "lti2_spec_helper"

  describe ".authorized_lti2_action?" do
    it "is true if the tool is authorized for the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: account)).to be true
    end

    it "is false if the tool isn't installed in the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: Account.create!)).to be false
    end

    context "assignment" do
      before do
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:create_subscription).and_return true
        allow_any_instance_of(AssignmentConfigurationToolLookup).to receive(:destroy_subscription).and_return true
        @original_fallback = DynamicSettings.fallback_data
        DynamicSettings.fallback_data = {
          "canvas" => {},
          "live-events-subscription-service" => {},
        }
      end

      after do
        DynamicSettings.fallback_data = @original_fallback
      end

      let(:assignment) do
        a = course.assignments.new(title: "some assignment")
        a.workflow_state = "published"
        a.tool_settings_tool = message_handler
        a.save
        a
      end

      let(:other_tp) do
        other_tp = tool_proxy.dup
        other_tp.update(guid: SecureRandom.uuid, context: course)
        allow(other_tp).to receive(:active_in_context?) { true }
        allow(other_tp).to receive(:resources) { [double(message_handlers: [message_handler])] }
        other_tp
      end

      it "is false if the context is an assignment and the tool isn't associated" do
        assignment.tool_settings_tool = []
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to be false
      end

      it "returns true if the requesting tool has the same access as the associated tool" do
        assignment.tool_settings_tool = message_handler
        assignment.save!
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: other_tp, context: assignment)).to be true
      end

      it "returns false if the requesting tool does not have the same access as the associated tool" do
        allow(other_tp).to receive(:resources).and_call_original
        other_tp.raw_data["tool_profile"]["product_instance"]["product_info"]["product_family"]["code"] = "different"
        other_tp.update(guid: SecureRandom.uuid, context: course)
        allow(other_tp).to receive(:active_in_context?) { true }
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: other_tp, context: assignment)).to be false
      end

      it "is true if the tool is authorized for an assignment context" do
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to be true
      end
    end
  end
end
