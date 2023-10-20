# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative "../spec_helper"

RSpec.describe SubmissionCommentsController do
  describe "GET 'index'" do
    before :once do
      @course = Account.default.courses.create!
      @teacher = course_with_teacher(course: @course, active_all: true).user
      @student = course_with_student(course: @course, active_all: true).user
      @assignment = @course.assignments.create!
      @submission = @assignment.submissions.find_by!(user: @student)
      @submission.submission_comments.create!(author: @teacher, comment: "a comment")
    end

    context "given a teacher session" do
      before { user_session(@teacher) }

      context "given a standard request" do
        before do
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :ok }
        specify { expect(response).to render_template(:index) }
        specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Aapplication/pdf}) }
      end

      context "when course is in a concluded term" do
        before :once do
          @course.enrollment_term.update!(end_at: 1.day.ago)
        end

        before do
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :ok }
        specify { expect(response).to render_template(:index) }
        specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Aapplication/pdf}) }
      end

      context "given a request where no submission is present" do
        before do
          @submission.all_submission_comments.destroy_all
          @submission.destroy
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :not_found }
        specify { expect(response).to render_template("shared/errors/404_message") }
        specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html}) }
      end

      context "given a request where no submission comments are present" do
        before do
          @submission.all_submission_comments.destroy_all
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :ok }
        specify { expect(response).to render_template(:index) }
        specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Aapplication/pdf}) }
      end

      context "given an anonymized assignment" do
        before do
          @assignment.update!(anonymous_grading: true)
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :unauthorized }
        specify { expect(response).to render_template("shared/unauthorized") }
        specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html}) }
      end
    end

    context "given a student session" do
      before do
        user_session(@student)
        get :index, params: { submission_id: @submission.id }, format: :pdf
      end

      specify { expect(response).to have_http_status :unauthorized }
      specify { expect(response).to render_template("shared/unauthorized") }
      specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html}) }
    end
  end

  describe "DELETE 'destroy'" do
    it "deletes the comment" do
      course_with_teacher(active_all: true)
      submission_comment_model(author: @user)
      user_session(@teacher)
      delete "destroy", params: { id: @submission_comment.id }, format: "json"
      expect(response).to be_successful
    end

    describe "audit event logging" do
      let(:course) { Course.create! }
      let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
      let(:teacher) { course.enroll_teacher(User.create!, enrollment_state: "active").user }
      let(:assignment) { course.assignments.create!(title: "hi", anonymous_grading: true) }
      let(:submission) { assignment.submission_for_student(student) }

      let!(:comment) do
        submission.submission_comments.create!(
          author: student,
          comment: "initial comment"
        )
      end

      let!(:draft_comment) do
        submission.submission_comments.create!(
          author: student,
          draft: true,
          comment: "this is a draft"
        )
      end

      let(:audit_events) do
        AnonymousOrModerationEvent.where(
          assignment:,
          submission:
        ).order(:id)
      end
      let(:last_event) { audit_events.last }

      context "when an assignment is auditable" do
        before do
          user_session(teacher)
        end

        it "creates an event when a published comment is destroyed" do
          expect { delete(:destroy, params: { id: comment.id }) }
            .to change(audit_events, :count).by(1)
        end

        it "records the user_id of the destroyer" do
          delete(:destroy, params: { id: comment.id, format: :json })
          expect(last_event.user_id).to eq teacher.id
        end

        it 'sets the event_type of the event to "submission_comment_deleted"' do
          delete(:destroy, params: { id: comment.id, format: :json })
          expect(last_event.event_type).to eq "submission_comment_deleted"
        end

        it "includes the ID of the destroyed comment in the payload" do
          delete(:destroy, params: { id: comment.id })
          expect(last_event.payload["id"]).to eq comment.id
        end
      end

      it "does not create an event if the assignment is not auditable" do
        assignment.update!(anonymous_grading: false)

        expect { delete(:destroy, params: { id: comment.id }) }
          .not_to change(audit_events, :count)
      end

      it "does not create an event if the comment is a draft" do
        expect { delete(:destroy, params: { id: draft_comment.id }) }
          .not_to change(audit_events, :count)
      end
    end
  end

  describe "PATCH 'update'" do
    before(:once) do
      course_with_teacher(active_all: true)
      @the_teacher = @teacher
      submission_comment_model(author: @teacher, draft_comment: true)

      @test_params = {
        id: @submission_comment.id,
        format: :json,
        submission_comment: {
          draft: false
        }
      }
    end

    before do
      user_session(@the_teacher)
    end

    it "allows updating the comment" do
      updated_comment = "an updated comment!"
      patch(
        :update,
        params: @test_params.merge(submission_comment: { comment: updated_comment })
      )
      comment = response.parsed_body.dig("submission_comment", "comment")
      expect(comment).to eq updated_comment
    end

    it "sets the edited_at if the comment is updated" do
      updated_comment = "an updated comment!"
      patch(
        :update,
        params: @test_params.merge(submission_comment: { comment: updated_comment })
      )
      edited_at = response.parsed_body.dig("submission_comment", "edited_at")
      expect(edited_at).to be_present
    end

    it "returns strings for numeric values when passed the json+canvas-string-ids header" do
      request.headers["HTTP_ACCEPT"] = "application/json+canvas-string-ids"
      patch :update, params: @test_params
      id = response.parsed_body.dig("submission_comment", "id")
      expect(id).to be_a String
    end

    it "does not set the edited_at if the comment is not updated" do
      patch :update, params: @test_params
      edited_at = response.parsed_body.dig("submission_comment", "edited_at")
      expect(edited_at).to be_nil
    end

    it "allows updating the status field" do
      expect { patch "update", params: @test_params }.to change { SubmissionComment.draft.count }.by(-1)
    end

    describe "audit event logging" do
      let(:course) { Course.create! }
      let(:student) { course.enroll_student(User.create!, enrollment_state: "active").user }
      let(:assignment) { course.assignments.create!(title: "hi", anonymous_grading: true) }
      let(:submission) { assignment.submission_for_student(student) }

      let!(:comment) do
        submission.submission_comments.create!(
          author: student,
          comment: "initial comment"
        )
      end

      let!(:draft_comment) do
        submission.submission_comments.create!(
          author: student,
          draft: true,
          comment: "this is a draft"
        )
      end

      let(:audit_events) do
        AnonymousOrModerationEvent.where(
          assignment:,
          submission:
        ).order(:id)
      end
      let(:last_event) { audit_events.last }

      before do
        user_session(student)
      end

      context "when an assignment is auditable" do
        it "does not create an event when a comment is saved as a draft" do
          expect do
            patch(:update, params: { id: draft_comment.id, submission_comment: { comment: "update!!!!!" } })
          end.not_to change(audit_events, :count)
        end

        context "when publishing an existing draft" do
          it 'sets the event_type to "submission_comment_created"' do
            patch(:update, params: { id: draft_comment.id, submission_comment: { draft: false } })
            expect(last_event.event_type).to eq "submission_comment_created"
          end

          it "records changed values as if saving a new comment" do
            comment_params = { draft: false, comment: "this is NO LONGER a draft" }
            patch(:update, params: { id: draft_comment.id, submission_comment: comment_params, format: :json })

            expect(last_event.payload["comment"]).to eq "this is NO LONGER a draft"
          end
        end
      end
    end
  end
end
