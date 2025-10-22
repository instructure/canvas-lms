# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
require_relative "../../spec_helper"

describe Lti::EulaUiService do
  describe "eula_launch_urls" do
    subject do
      asset_processor
      Lti::EulaUiService.eula_launch_urls(user: student, assignment:)
    end

    let(:course) do
      course_with_student
      @course
    end
    let(:student) { course.student_enrollments.first.user }
    let(:assignment) { assignment_model({ course: }) }
    let(:developer_key) do
      lti_developer_key_model(
        scopes: [
          TokenScopes::LTI_EULA_USER_SCOPE,
          TokenScopes::LTI_EULA_DEPLOYMENT_SCOPE
        ]
      )
    end
    let(:tool) do
      t = external_tool_1_3_model(
        context: course,
        opts: { name: "test tool" },
        placements: ["ActivityAssetProcessor"],
        developer_key:
      )
      t.settings["message_settings"] = [
        {
          type: "LtiEulaRequest",
          enabled: true,
          target_link_uri: "http://example.com/eula",
          custom_fields: { "foo" => "bar" }
        }
      ]
      t.save!
      t
    end
    let!(:asset_processor) { lti_asset_processor_model(tool:, assignment:) }

    it "returns [] if lti_asset_processor FF is off" do
      course.root_account.disable_feature!(:lti_asset_processor)

      expect(subject).to be_empty
    end

    it "returns [] if assignment does not have active processors" do
      asset_processor.destroy

      expect(subject).to be_empty
    end

    it "returns [] if tool does not have eula service scope" do
      tool.developer_key.update!(scopes: [TokenScopes::LTI_EULA_DEPLOYMENT_SCOPE])
      expect(subject).to be_empty
    end

    it "returns [] if EULA is not enabled in message_settings" do
      tool.settings["message_settings"][0]["enabled"] = false
      tool.save!
      expect(subject).to be_empty
    end

    context "when tool has eula service scope" do
      it "returns [] if tool has opted out of EULA" do
        tool.update!(asset_processor_eula_required: false)

        expect(subject).to be_empty
      end

      it "returns [] if user has already accepted the EULA" do
        student.lti_asset_processor_eula_acceptances.new(
          context_external_tool_id: tool.id,
          timestamp: Time.now.iso8601,
          accepted: true
        ).save!

        expect(subject).to be_empty
      end

      it "returns launch url if user rejected the EULA" do
        student.lti_asset_processor_eula_acceptances.new(
          context_external_tool_id: tool.id,
          timestamp: Time.now.iso8601,
          accepted: false
        ).save!

        expect(subject).to eq [{ name: "test tool", url: "http://localhost/courses/#{course.id}/external_tools/#{tool.id}/eula_launch" }]
      end

      it "returns launch url if user has not yet decided" do
        expect(subject).to eq [{ name: "test tool", url: "http://localhost/courses/#{course.id}/external_tools/#{tool.id}/eula_launch" }]
      end

      it "returns multiple launch urls if there are multiple APs from multiple tools attached" do
        tool2 = external_tool_1_3_model(
          context: course.root_account,
          placements: ["ActivityAssetProcessor"],
          opts: { name: "test tool2" }
        )
        tool2.developer_key.update!(scopes: [TokenScopes::LTI_EULA_USER_SCOPE, TokenScopes::LTI_EULA_DEPLOYMENT_SCOPE])
        tool2.settings["message_settings"] = [
          {
            type: "LtiEulaRequest",
            enabled: true,
            target_link_uri: "http://example.com/eula2",
            custom_fields: { "tool2" => "test" }
          }
        ]
        tool2.save!

        lti_asset_processor_model(tool: tool2, assignment:)
        # multiple APs for the same tool should result only one launch url
        lti_asset_processor_model(tool: tool2, assignment:)

        expect(subject).to eq [
          { name: "test tool", url: "http://localhost/courses/#{course.id}/external_tools/#{tool.id}/eula_launch" },
          { name: "test tool2", url: "http://localhost/accounts/#{course.root_account.id}/external_tools/#{tool2.id}/eula_launch" }
        ]
      end
    end
  end
end
