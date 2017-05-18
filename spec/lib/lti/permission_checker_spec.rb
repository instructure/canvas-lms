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

require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper.rb')


describe Lti::PermissionChecker do
  include_context 'lti2_spec_helper'

  describe ".authorized_lti2_action?" do
    it "is true if the tool is authorized for the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: account)).to eq true
    end

    it "is false if the tool isn't installed in the context" do
      expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: Account.create!)).to eq false
    end

    context "assignment" do
      before :each do
        AssignmentConfigurationToolLookup.any_instance.stubs(:create_subscription).returns true
        @original_fallback = Canvas::DynamicSettings.fallback_data
        Canvas::DynamicSettings.fallback_data = {
          'canvas' => {},
          'live-events-subscription-service' => {},
        }
      end

      after :each do
        Canvas::DynamicSettings.fallback_data = @original_fallback
      end

      let(:assignment) do
        a = course.assignments.new(:title => "some assignment")
        a.workflow_state = "published"
        a.tool_settings_tool = message_handler
        a.save
        a
      end

      it "is false if the context is an assignment and the tool isn't associated" do
        assignment.tool_settings_tool = []
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to eq false
      end

      it "is true if the tool is authorized for an assignment context" do
        expect(Lti::PermissionChecker.authorized_lti2_action?(tool: tool_proxy, context: assignment)).to eq true
      end
    end
  end
end
