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

describe Lti::AssetProcessorNotifier do
  include LtiSpecHelper

  describe "notify_asset_processors" do
    let(:course) do
      course_with_student
      @course
    end
    let(:student) { course.student_enrollments.first.user }
    let(:assignment) { assignment_model({ course: }) }
    let(:assignment2) { assignment_model({ course: }) }
    let(:attachment) { attachment_with_context student, { display_name: "a1.txt", uploaded_data: StringIO.new("hello") } }
    let(:attachment2) { attachment_with_context student, { display_name: "a2.txt", uploaded_data: StringIO.new("world") } }
    let(:tool) { new_valid_external_tool(course) }

    it "does not create Lti::Attachment if feature flag is off" do
      course.root_account.disable_feature!(:lti_asset_processor)

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment: submission.attachments.first)).to be_empty
    end

    it "does not create Lti::Attachment if there's no tool" do
      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment: submission.attachments.first)).to be_empty
    end

    it "does not create Lti::Attachment if there's no asset processor registered" do
      # Register asset processor for different assignment
      lti_asset_processor_model(tool:, assignment: assignment2)

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment: submission.attachments.first)).to be_empty
    end

    it "sends the notice again for already existing assets" do
      ap = lti_asset_processor_model(tool:, assignment:)
      received_notifications = []
      allow(Lti::PlatformNotificationService).to receive(:notify_tools) do |payload|
        received_notifications << payload
      end

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])
      assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).twice
      notice_params = received_notifications[0]
      expect(notice_params[:cet_id_or_ids]).to eq(tool.id)

      builder_params = notice_params[:builders].first.instance_variable_get(:@params)
      builder_params => {asset_report_service_url:, submission_lti_id:, assets:}
      expect(asset_report_service_url).to eq("http://localhost/api/lti/asset_processors/#{ap.id}/reports")
      expect(submission_lti_id).to eq(submission.lti_attempt_id)

      assets = assets.sort_by { it[:display_name] }
      expect(assets.pluck(:title)).to eq([assignment.title, assignment.title])
      expect(assets.pluck(:filename)).to eq([attachment, attachment2].map(&:display_name))
      expect(assets.pluck(:sha256_checksum)).to eq([
                                                     "LPJNul+wow4m6DsqxbninhsWHlwfp0JecwQzYpOLmCQ=",
                                                     "SG6kYiTRu0+2gPNPfJrZao8k7Ii+c+qOWmxlJg6cuKc="
                                                   ])
    end

    it "creates Lti::Asset for each attachment" do
      lti_asset_processor_model(tool:, assignment:)
      lti_asset_processor_model(tool:, assignment:)
      allow(Lti::PlatformNotificationService).to receive(:notify_tools)
      allow(Rails.application.routes.url_helpers).to receive(:lti_asset_processor_asset_show_url).and_return("http://example.com")

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment:, submission:).active).to be_present
      expect(Lti::Asset.where(attachment: attachment2, submission:).active).to be_present
      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).twice
    end

    it "can resubmit for a specific asset processor" do
      ap = lti_asset_processor_model(tool:, assignment:)
      lti_asset_processor_model(tool:, assignment:)
      allow(Lti::PlatformNotificationService).to receive(:notify_tools)
      allow(Rails.application.routes.url_helpers).to receive(:lti_asset_processor_asset_show_url).and_return("http://example.com")

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment:, submission:).active).to be_present
      expect(Lti::Asset.where(attachment: attachment2, submission:).active).to be_present
      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).twice

      # Notify only for the first asset processor
      Lti::AssetProcessorNotifier.notify_asset_processors(submission, ap)

      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).exactly(3).times
    end

    it "can resubmit for an old version of a submission" do
      ap = lti_asset_processor_model(tool:, assignment:)
      received_notifications = []
      allow(Lti::PlatformNotificationService).to receive(:notify_tools) do |payload|
        received_notifications << payload
      end

      submission = assignment.submit_homework(student, attachments: [attachment])
      assignment.submit_homework(student, attachments: [attachment2])

      Lti::AssetProcessorNotifier.notify_asset_processors(submission, ap)

      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).exactly(3).times
      notice_params = received_notifications.last
      builder_params = notice_params[:builders].first.instance_variable_get(:@params)
      asset_filenames = builder_params[:assets].map { it[:filename] }
      expect(asset_filenames).to eq([attachment.display_name])
    end

    context "when the submission is a text entry" do
      before do
        lti_asset_processor_model(tool:, assignment:)
        allow(Lti::PlatformNotificationService).to receive(:notify_tools)
        allow(Rails.application.routes.url_helpers).to receive(:lti_asset_processor_asset_show_url).and_return("http://example.com")
      end

      it "creates Lti::Asset for text entry submission" do
        submission = assignment.submit_homework(student, body: "Hello world")
        expect(Lti::Asset.where(submission:).active.count).to eq(1)
        expect(Lti::Asset.first.text_entry?).to be true
      end

      it "calculates the SHA256 checksum for text entry" do
        assignment.submit_homework(student, body: "Hello world")
        asset = Lti::Asset.first
        asset.calculate_sha256_checksum!
        expect(asset.sha256_checksum).to eq("ZOyIygCyaOW6GjVnihtTFtIS9PNmskdyMlNKiuyjfzw=")
      end

      it "sends correct notice content for text entry asset" do
        received_notifications = []
        allow(Lti::PlatformNotificationService).to receive(:notify_tools) do |payload|
          received_notifications << payload
        end
        assignment.submit_homework(student, body: "Hello world")
        expect(Lti::PlatformNotificationService).to have_received(:notify_tools)
        notice_params = received_notifications.first
        builder_params = notice_params[:builders].first.instance_variable_get(:@params)
        asset = builder_params[:assets].first
        expect(asset[:filename]).to be_nil
        expect(asset[:title]).to eq(assignment.title)
        expect(asset[:sha256_checksum]).to eq("ZOyIygCyaOW6GjVnihtTFtIS9PNmskdyMlNKiuyjfzw=")
        expect(asset[:content_type]).to eq("text/html")
        expect(asset[:size]).to eq("Hello world".bytesize)
      end
    end
  end
end
