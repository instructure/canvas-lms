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
    let(:assignment) { assignment_model(course:) }
    let(:student) { course_with_student(course:, active_all: true).user }
    let(:teacher) { course_with_teacher(course:, active_all: true).user }
    let(:asset_processor) { lti_asset_processor_model(assignment:) }
    let(:submission) { submission_model(assignment:, user: student) }

    let(:params) { { asset_processor_id: asset_processor.id, student_id: student.id } }

    before do
      Account.site_admin.enable_feature!(:lti_asset_processor)
    end

    context "when the user has proper permissions" do
      before do
        user_session(teacher)
      end

      it "notifies asset processors and returns success" do
        expect(Lti::AssetProcessorNotifier).to receive(:notify_asset_processors).with(
          submission,
          asset_processor
        ).and_return(true)

        post(:resubmit_notice, params:)
        expect(response).to have_http_status(:created)
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
          post :resubmit_notice, params: { asset_processor_id: "nonexistent", student_id: student.id }
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
          post :resubmit_notice, params: { asset_processor_id: asset_processor.id, student_id: "nonexistent" }
          expect(response).to have_http_status(:not_found)
        end

        it "returns not found when submission doesn't exist" do
          other_student = user_model
          post :resubmit_notice, params: { asset_processor_id: asset_processor.id, student_id: other_student.id }
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
