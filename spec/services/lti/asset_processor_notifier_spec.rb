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
    let(:attachment) { attachment_with_context student }
    let(:attachment2) { attachment_with_context student }

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
      tool = new_valid_external_tool course
      # Register asset processor for different assignment
      lti_asset_processor_model(tool:, assignment: assignment2)

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment: submission.attachments.first)).to be_empty
    end

    it "sends the notice again for already existing assets" do
      tool = new_valid_external_tool course
      ap = lti_asset_processor_model(tool:, assignment:)
      received_notifications = []
      allow(Lti::PlatformNotificationService).to receive(:notify_tools) do |payload|
        received_notifications << payload
      end

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])
      assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).twice
      notice_params = received_notifications[0]
      builder_params = notice_params[:builders].first.instance_variable_get(:@params)
      expect(notice_params[:cet_id_or_ids]).to eq(tool.id)
      expect(builder_params[:asset_report_service_url]).to eq("http://localhost/api/lti/asset_processor/#{ap.id}/report")
      expect(builder_params[:submission_lti_id]).to eq(submission.lti_attempt_id)
    end

    it "creates Lti::Asset for each attachment" do
      tool = new_valid_external_tool course
      lti_asset_processor_model(tool:, assignment:)
      lti_asset_processor_model(tool:, assignment:)
      allow(Lti::PlatformNotificationService).to receive(:notify_tools)
      allow(Rails.application.routes.url_helpers).to receive(:lti_asset_processor_asset_show_url).and_return("http://example.com")

      submission = assignment.submit_homework(student, attachments: [attachment, attachment2])

      expect(Lti::Asset.where(attachment:, submission:).active).to be_present
      expect(Lti::Asset.where(attachment: attachment2, submission:).active).to be_present
      expect(Lti::PlatformNotificationService).to have_received(:notify_tools).twice
    end
  end
end
