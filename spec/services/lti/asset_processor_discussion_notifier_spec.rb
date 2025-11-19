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

require_relative "../../lti_spec_helper"

RSpec.describe Lti::AssetProcessorDiscussionNotifier do
  include LtiSpecHelper

  let(:course) do
    course_with_teacher_and_student_enrolled
    @course
  end
  let(:discussion_topic) { graded_discussion_topic(context: course) }
  let(:assignment) { discussion_topic.assignment }
  let(:tool) { new_valid_external_tool(course) }
  let(:contribution_status) { Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED }

  # Returns [version, submission]
  def reply_version(user:, html: "This is my comment")
    entry = discussion_topic.reply_from(user:, html:)
    version = entry.discussion_entry_versions.first
    submission = assignment.submissions.active.find_by(user:) || assignment.submissions.create!(user:)
    [version, submission]
  end

  def stub_asset_processor_routes
    allow(Rails.application.routes.url_helpers).to receive_messages(
      lti_asset_processor_asset_show_url: "http://example.com/asset",
      lti_asset_processor_create_report_url: "http://example.com/report"
    )
  end

  # Invokes the notifier and returns builder_params (also yields received payloads if block given)
  def capture_notice(version:, assignment:, submission:, contribution_status:, current_user:)
    received = []
    allow(Lti::PlatformNotificationService).to receive(:notify_tools) { |payload| received << payload }
    described_class.notify_asset_processors_of_discussion(
      discussion_entry_version: version,
      assignment:,
      contribution_status:,
      submission:,
      current_user:
    )
    yield(received) if block_given?
    received.first[:builders].first.instance_variable_get(:@params)
  end

  before do
    lti_asset_processor_model(tool:, assignment:)
  end

  describe ".notify_asset_processors_of_discussion" do
    context "when student comments" do
      it "creates asset (text) and sends a contribution notice" do
        stub_asset_processor_routes
        version, submission = reply_version(user: @student)
        builder_params = capture_notice(
          version:,
          assignment:,
          submission:,
          contribution_status:,
          current_user: @student
        ) do |received|
          expect(received.size).to eq(1)
          expect(received.first[:cet_id_or_ids]).to eq(tool.id)
        end
        expect(builder_params[:assignment]).to eq(assignment)
        expect(builder_params[:contribution_status]).to eq("Submitted") # human readable form
        expect(builder_params[:discussion_entry_version]).to eq(version)
        expect(builder_params[:for_user_id]).to eq(version.user.lti_id)
        expect(builder_params[:notice_event_timestamp]).to match(/\A\d{4}-\d{2}-\d{2}T/)
        expect(builder_params[:custom]).to be_a(Hash)
        expect(builder_params[:asset_report_service_url]).to eq("http://example.com/report")
        expect(builder_params[:submission_lti_claim_id]).to eq("#{submission.lti_id}:#{version.id}:")
        expect(builder_params[:user]).to eq(@student)

        expect(builder_params[:assets].size).to eq(1)
        asset_hash = builder_params[:assets].first
        %i[asset_id url sha256_checksum timestamp size content_type].each do |required_key|
          expect(asset_hash[required_key]).to be_present, "expected asset to have #{required_key}"
        end
        expect(asset_hash[:content_type]).to eq("text/html")
        expect(asset_hash).not_to have_key(:title)
        expect(asset_hash[:filename]).to be_nil
        # compute size from html string to avoid brittle literal
        expect(asset_hash[:size]).to eq("This is my comment".bytesize)
      end

      it "skips when submission not compatible" do
        version, submission = reply_version(user: @student, html: "Another comment")
        allow(submission).to receive(:asset_processor_for_discussions_compatible?).and_return(false)
        expect(Lti::PlatformNotificationService).not_to receive(:notify_tools)
        described_class.notify_asset_processors_of_discussion(
          discussion_entry_version: version,
          assignment:,
          contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
          submission:,
          current_user: @student
        )
      end

      it "skips when lti_asset_processor_discussions feature flag is disabled" do
        course.root_account.disable_feature!(:lti_asset_processor_discussions)
        version, submission = reply_version(user: @student, html: "Another comment")
        expect(Lti::PlatformNotificationService).not_to receive(:notify_tools)
        described_class.notify_asset_processors_of_discussion(
          discussion_entry_version: version,
          assignment:,
          contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
          submission:,
          current_user: @student
        )
      end
    end

    context "when teacher comments (no submission)" do
      it "does not create assets and sends notice with no assets and no asset_report_service_url" do
        entry = discussion_topic.reply_from(user: @teacher, html: "Teacher feedback")
        version = entry.discussion_entry_versions.first
        allow(Rails.application.routes.url_helpers).to receive(:lti_asset_processor_create_report_url).and_return("http://example.com/report")
        builder_params = capture_notice(
          version:,
          assignment:,
          submission: nil,
          contribution_status:,
          current_user: @teacher
        ) { |received| expect(received.size).to eq(1) }
        expect(builder_params[:asset_report_service_url]).to be_nil
        expect(builder_params[:assignment]).to eq(assignment)
        expect(builder_params[:contribution_status]).to eq("Submitted")
        expect(builder_params[:discussion_entry_version]).to eq(version)
        expect(builder_params[:for_user_id]).to eq(version.user.lti_id)
        expect(builder_params[:notice_event_timestamp]).to match(/\A\d{4}-\d{2}-\d{2}T/)
        expect(builder_params[:custom]).to be_a(Hash)
        expect(builder_params[:submission_lti_claim_id]).to be_nil
        expect(builder_params[:user]).to eq(@teacher)
        expect(builder_params[:assets]).to be_empty
      end
    end

    context "attachment on entry" do
      it "creates two assets when an attachment is present" do
        attachment = attachment_with_context(@student, display_name: "note.txt", uploaded_data: StringIO.new("hello"))
        version, submission = reply_version(user: @student, html: "This is my comment")
        version.discussion_entry.update!(attachment:)
        stub_asset_processor_routes
        builder_params = capture_notice(
          version:,
          assignment:,
          submission:,
          contribution_status:,
          current_user: @teacher
        )
        # One text asset and one attachment asset
        expect(builder_params[:assets].size).to eq(2)
        expect(builder_params[:user]).to eq(@teacher)
        filenames = builder_params[:assets].filter_map { |a| a[:filename] }
        expect(filenames).to include("note.txt")
        attachment_asset = builder_params[:assets].find { |a| a[:filename] == "note.txt" }
        expect(attachment_asset[:title]).to eq("note.txt")
        text_asset = builder_params[:assets].find { |a| a[:filename].nil? }
        expect(text_asset).not_to have_key(:title)
      end
    end

    context "tool_id filtering" do
      it "filters asset processors by tool_id when provided" do
        # Create a second tool and asset processor (first one created in before block)
        tool2 = new_valid_external_tool(course)
        lti_asset_processor_model(tool: tool2, assignment:)

        stub_asset_processor_routes

        # Create discussion entry and version before setting up notification spy
        # to avoid counting notifications from reply_version
        version, submission = reply_version(user: @student, html: "Test comment")

        received_notifications = []
        allow(Lti::PlatformNotificationService).to receive(:notify_tools) do |payload|
          received_notifications << payload
        end

        # Initial notify sends to both tools (2 asset processors total)
        described_class.notify_asset_processors_of_discussion(
          discussion_entry_version: version,
          assignment:,
          contribution_status:,
          submission:,
          current_user: @student
        )

        expect(received_notifications.size).to eq(2)

        # Resubmit filtered to tool2 only
        described_class.notify_asset_processors_of_discussion(
          discussion_entry_version: version,
          assignment:,
          contribution_status:,
          submission:,
          current_user: @student,
          tool_id: tool2.id
        )

        expect(received_notifications.size).to eq(3)
        expect(received_notifications.last[:cet_id_or_ids]).to eq(tool2.id)
      end
    end
  end
end
