# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require_relative "../../../spec_helper"

RSpec.describe Lti::Pns::LtiAssetProcessorContributionNoticeBuilder do
  let!(:course) do
    course_with_teacher_and_student_enrolled
  end
  let(:developer_key) do
    dk = DeveloperKey.new(
      scopes: ["https://purl.imsglobal.org/spec/lti/scope/noticehandlers", TokenScopes::LTI_AGS_LINE_ITEM_SCOPE],
      account: Account.default
    )
    dk.save!
    dk
  end
  let(:tool) do
    ContextExternalTool.new(
      name: "Test Tool",
      context: course,
      url: "https://www.test.tool.com",
      consumer_key: "key",
      shared_secret: "secret",
      settings: { "platform" => "canvas" },
      account: Account.default,
      developer_key:,
      root_account: Account.default
    )
  end
  let(:iso_timestamp) { Time.now.utc.iso8601 }
  let(:assignment) { discussion.assignment }
  let(:submission_lti_claim_id) { "submission_id:1" }
  let(:for_user_id) { @student.id }
  let(:notice_event_timestamp) { iso_timestamp }
  let(:custom) { { myparam: "$Canvas.account.id", groupId: "$CourseGroup.id" } }
  let(:discussion) { graded_discussion_topic(context: course) }
  let(:asset_report_url) { "https://example.com/asset_processor_service" }
  let(:reply) { discussion.reply_from(user: @student, html: "This is my comment") }
  let(:discussion_entry_version) { reply.discussion_entry_versions.first }
  let(:param_hash) do
    {
      submission_lti_claim_id:,
      assignment:,
      for_user_id:,
      notice_event_timestamp:,
      user: @teacher, # teacher resubmits a notice, so the user is the teacher, the for_user_id is the student
      assets: [
        {
          title: "title",
          size: 123,
          asset_id: "333",
          url: "url",
          sha256_checksum: "555",
          timestamp: "2024-01-01T00:00:00Z",
          content_type: "text/plain"
        }
      ],
      custom:,
      asset_report_service_url: asset_report_url,
      discussion_entry_version:,
      contribution_status: "Submitted"
    }
  end

  describe "#initialize" do
    context "when submission is missing" do
      let(:submission_lti_claim_id) { nil }

      it "it is fine" do
        described_class.new(param_hash)
      end
    end

    context "when assignment is missing" do
      let(:assignment) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end

    context "when asset_report_service_url is missing" do
      let(:asset_report_url) { nil }

      it "raises an error when assets are present" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError, /asset_report_service_url/)
      end
    end

    context "when asset_report_service_url is missing but no assets provided" do
      let(:asset_report_url) { nil }

      before { param_hash[:assets] = [] }

      it "is fine" do
        described_class.new(param_hash)
      end
    end

    context "when for_user_id is missing" do
      let(:for_user_id) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end

    context "when notice_event_timestamp is missing" do
      let(:notice_event_timestamp) { nil }

      it "raises an error" do
        expect { described_class.new(param_hash) }.to raise_error(ArgumentError)
      end
    end

    context "when contribution_status is valid" do
      %w[Draft Submitted Deleted Hidden].each do |status|
        it "accepts #{status} status" do
          param_hash[:contribution_status] = status
          expect { described_class.new(param_hash) }.not_to raise_error
        end
      end
    end

    context "when contribution_status is invalid" do
      it "raises an error for invalid status" do
        param_hash[:contribution_status] = "InvalidStatus"
        expect { described_class.new(param_hash) }.to raise_error(
          ArgumentError,
          "Invalid contribution_status: InvalidStatus. Must be one of: Draft, Submitted, Deleted, Hidden"
        )
      end

      it "raises an error when status is empty string" do
        param_hash[:contribution_status] = ""
        expect { described_class.new(param_hash) }.to raise_error(
          ArgumentError,
          "Invalid contribution_status: . Must be one of: Draft, Submitted, Deleted, Hidden"
        )
      end
    end

    context "ensures lti_ids are set" do
      it "sets lti_id on discussion_entry and its parent if missing without changing updated_at or creating new discussion_entry_version" do
        reply.update_columns(lti_id: nil)
        child = reply.reply_from(user: @student, html: "This is my comment reply")
        child.update_columns(lti_id: nil)
        updated = child.updated_at
        versions = child.discussion_entry_versions.count
        expect(child.parent_entry.lti_id).to be_nil
        expect(child.lti_id).to be_nil
        param_hash[:discussion_entry_version] = child.discussion_entry_versions.first

        described_class.new(param_hash)

        expect(child.reload.lti_id).not_to be_nil
        expect(child.parent_entry.reload.lti_id).not_to be_nil
        expect(child.reload.updated_at).to eq(updated)
        expect(child.discussion_entry_versions.count).to eq(versions)
      end

      it "does not change lti_id if already set" do
        original_lti_id = reply.lti_id
        expect(original_lti_id).not_to be_nil

        described_class.new(param_hash)

        expect(reply.reload.lti_id).to eq(original_lti_id)
      end
    end
  end

  describe "#build" do
    let(:notice_builder) { described_class.new(param_hash) }

    before do
      allow(SecureRandom).to receive(:uuid).and_return("random_uuid")
      allow(LtiAdvantage::Messages::JwtMessage).to receive(:create_jws).and_return("signed_jwt")
      allow(Rails.application.routes.url_helpers).to receive_messages(
        lti_notice_handlers_url: "https://example.com/notice_handler",
        update_tool_eula_url: "https://example.com/eula"
      )
    end

    it "builds a valid contribution notice for teacher" do
      param_hash[:submission_lti_claim_id] = nil
      param_hash[:assets] = []
      param_hash[:asset_report_service_url] = nil

      notice_message = notice_builder.build(tool)

      expect(notice_message).to eq({ jwt: "signed_jwt" })

      expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
        hash_including(
          "https://purl.imsglobal.org/spec/lti/claim/activity" => { id: assignment.lti_context_id },
          "https://purl.imsglobal.org/spec/lti/claim/assetservice" =>
          {
            assets: [],
            scope: ["https://purl.imsglobal.org/spec/lti/scope/asset.readonly"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/contribution" => {
            created: discussion_entry_version.created_at.iso8601,
            id: "random_uuid",
            status: "Submitted",
            updated: discussion_entry_version.updated_at.iso8601
          },
          "https://purl.imsglobal.org/spec/lti/claim/notice" => {
            "id" => "random_uuid",
            "timestamp" => iso_timestamp,
            "type" => "LtiAssetProcessorContributionNotice"
          },
          "sub" => @teacher.lti_id
        ),
        anything
      )
    end

    it "builds a valid contribution notice for student" do
      notice_message = notice_builder.build(tool)

      expect(notice_message).to eq({ jwt: "signed_jwt" })
      expect(LtiAdvantage::Messages::JwtMessage).to have_received(:create_jws).with(
        hash_including(
          "aud" => developer_key.global_id.to_s,
          "azp" => developer_key.global_id.to_s,
          "https://purl.imsglobal.org/spec/lti/claim/activity" => { id: assignment.lti_context_id },
          "https://purl.imsglobal.org/spec/lti/claim/assetservice" =>
          {
            assets: [{
              asset_id: "333",
              content_type: "text/plain",
              sha256_checksum: "555",
              size: 123,
              timestamp: "2024-01-01T00:00:00Z",
              title: "title",
              url: "url"
            }],
            scope: ["https://purl.imsglobal.org/spec/lti/scope/asset.readonly"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/custom" => { "myparam" => Account.default.id, "groupId" => "" },
          "https://purl.imsglobal.org/spec/lti/claim/context" => {
            "id" => assignment.context.lti_context_id,
            "title" => assignment.context.name,
            "label" => kind_of(String),
            "type" => ["http://purl.imsglobal.org/vocab/lis/v2/course#CourseOffering"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/contribution" => {
            created: reply.created_at.iso8601,
            id: "random_uuid",
            status: "Submitted",
            updated: reply.updated_at.iso8601
          },
          "https://purl.imsglobal.org/spec/lti/claim/deployment_id" => tool.deployment_id.to_s,
          "https://purl.imsglobal.org/spec/lti/claim/for_user" => { user_id: for_user_id },
          "https://purl.imsglobal.org/spec/lti/claim/submission" => { id: "submission_id:1" },
          "https://purl.imsglobal.org/spec/lti/claim/notice" => {
            "id" => "random_uuid",
            "timestamp" => iso_timestamp,
            "type" => "LtiAssetProcessorContributionNotice"
          },
          "https://purl.imsglobal.org/spec/lti/claim/version" => "1.3.0",
          "iss" => "https://canvas.instructure.com",
          "nonce" => "random_uuid",
          "https://purl.imsglobal.org/spec/lti/claim/roles" => array_including(
            "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"
          ),
          "https://purl.imsglobal.org/spec/lti/claim/assetreport" => {
            scope: ["https://purl.imsglobal.org/spec/lti/scope/report"],
            report_url: "https://example.com/asset_processor_service",
          },
          "https://purl.imsglobal.org/spec/lti-ags/claim/endpoint" => {
            "lineitems" => "http://localhost/api/lti/courses/#{assignment.course.id}/line_items",
            "scope" => ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"]
          },
          "https://purl.imsglobal.org/spec/lti/claim/eulaservice" => {
            "scope" => ["https://purl.imsglobal.org/spec/lti/scope/eula/user", "https://purl.imsglobal.org/spec/lti/scope/eula/deployment"],
            "url" => "https://example.com/eula"
          },
          "sub" => @teacher.lti_id
        ),
        anything
      )
    end
  end

  describe "#info_log" do
    let(:notice_builder) { described_class.new(param_hash) }

    it "returns relevant log information" do
      log_info = notice_builder.info_log(tool)
      expect(log_info).to include(
        notice_type: "LtiAssetProcessorContributionNotice",
        tool_id: tool.id,
        user_id: @teacher.id,
        assignment_id: assignment.id,
        discussion_entry_id: reply.id,
        contribution_status: "Submitted",
        asset_count: 1,
        asset_uuids: ["333"]
      )
      expect(log_info).to have_key(:notice_id)
    end
  end
end
