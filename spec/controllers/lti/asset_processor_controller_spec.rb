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

describe Lti::AssetProcessorController do
  describe "#resubmit_notice" do
    let(:course) { course_model }
    let(:assignment) { assignment_model(course:, submission_types: "online_upload") }
    let(:student) { course_with_student(course:, active_all: true).user }
    let(:teacher) { course_with_teacher(course:, active_all: true).user }
    let(:asset_processor) { lti_asset_processor_model(assignment:) }
    let(:attachment) { attachment_model(user: student) }
    let(:submission) do
      assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment])
    end

    let(:params) { { asset_processor_id: asset_processor.id, student_id: student.id, attempt: } }
    let(:attempt) { "latest" }

    before do
      Account.site_admin.enable_feature!(:lti_asset_processor)
    end

    context "when the user has proper permissions" do
      before do
        user_session(teacher)
      end

      def expect_submission(attempt: nil, attachment_ids: nil)
        attempt ||= submission.attempt
        attachment_ids ||= attachment.id.to_s

        received_submission = nil
        expect(Lti::AssetProcessorNotifier).to receive(:notify_asset_processors).with(
          submission,
          asset_processor
        ) do |sub, _ap|
          received_submission = sub
          true
        end

        post(:resubmit_notice, params:)
        expect(response).to have_http_status(:no_content)

        expect(received_submission.attempt).to eq(attempt)
        expect(received_submission.attachment_ids).to eq(attachment_ids)
      end

      it "notifies asset processors and returns success" do
        expect_submission
      end

      context "when there are multiple attempts" do
        let(:attachment2) { attachment_model(user: student) }

        before do
          opts = { submission_type: "online_upload", attachments: [attachment] }
          # Create a second submission with attempt number 1
          assignment.submit_homework(student, **opts, submitted_at: submission.submitted_at)

          opts = { submission_type: "online_upload", attachments: [attachment2] }
          # Create a third submission with a attempt number 2
          submission2 = assignment.submit_homework(student, **opts)

          # Create a fourth submission with attempt number 2
          assignment.submit_homework(student, **opts, submitted_at: submission2.submitted_at)
        end

        context "when attempt is given" do
          let(:attempt) { "1" }

          it "uses the given attempt" do
            expect_submission(attempt: 1, attachment_ids: attachment.id.to_s)
          end
        end

        context "when attempt is not found" do
          let(:attempt) { "100" }

          it("uses the latest attempt") { expect_submission(attempt: 2, attachment_ids: attachment2.id.to_s) }
        end

        context "when attempt is 'latest'" do
          it("uses the latest attempt") { expect_submission(attempt: 2, attachment_ids: attachment2.id.to_s) }
        end
      end
    end

    context "when testing before_actions" do
      context "require_feature_enabled" do
        before do
          Account.site_admin.disable_feature!(:lti_asset_processor)
          user_session(teacher)
        end

        it "returns not found when feature is disabled" do
          post(:resubmit_notice, params:)
          expect(response).to have_http_status(:not_found)
        end
      end

      context "require_user" do
        it "redirects to login when user is not authenticated" do
          post(:resubmit_notice, params:)
          expect(response).to redirect_to(login_url)
        end
      end

      context "require_asset_processor" do
        before do
          user_session(teacher)
        end

        it "returns not found when asset processor doesn't exist" do
          post :resubmit_notice, params: { asset_processor_id: "nonexistent", student_id: student.id, attempt: "latest" }
          expect(response).to have_http_status(:not_found)
        end
      end

      context "require_access_to_context" do
        before do
          user_session(student) # Student doesn't have manage_grades permission
        end

        it "returns forbidden when user doesn't have access" do
          post(:resubmit_notice, params:)
          expect(response).to have_http_status(:forbidden)
          expect(response.body).to eq("invalid_request")
        end
      end

      context "require_submission" do
        before do
          user_session(teacher)
        end

        it "returns not found when student doesn't exist" do
          post :resubmit_notice, params: { asset_processor_id: asset_processor.id, student_id: "nonexistent", attempt: "latest" }
          expect(response).to have_http_status(:not_found)
        end

        it "returns not found when submission doesn't exist" do
          other_student = user_model
          post :resubmit_notice, params: { asset_processor_id: asset_processor.id, student_id: other_student.id, attempt: "latest" }
          expect(response).to have_http_status(:not_found)
        end
      end
    end
  end

  describe "helper methods" do
    let(:course) { course_model }
    let(:assignment) { assignment_model(course:) }
    let(:student) { course_with_student(course:, active_all: true).user }
    let(:teacher) { course_with_teacher(course:, active_all: true).user }
    let(:asset_processor) { lti_asset_processor_model(assignment:) }
    let(:submission) { submission_model(assignment:, user: student) }
    let(:params) { { asset_processor_id: asset_processor.id, student_id: student.id } }

    before do
      Account.site_admin.enable_feature!(:lti_asset_processor)
      user_session(teacher)
      allow(assignment).to receive(:submission_for_student).with(student).and_return(submission)
    end

    describe "#assignment" do
      it "returns the assignment associated with the asset processor" do
        controller.params = params
        expect(controller.send(:assignment)).to eq(asset_processor.assignment)
      end
    end

    describe "#asset_processor" do
      it "finds and returns the asset processor" do
        controller.params = params
        expect(controller.send(:asset_processor).id).to eq(asset_processor.id)
      end
    end

    describe "#student" do
      it "finds and returns the student" do
        controller.params = params
        expect(controller.send(:student).id).to eq(student.id)
      end
    end

    describe "#submission" do
      it "returns the submission for the student" do
        controller.params = params
        expect(controller.send(:submission)).to eq(submission)
      end
    end
  end
end
