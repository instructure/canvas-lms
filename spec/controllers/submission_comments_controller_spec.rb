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

require_relative '../spec_helper'

RSpec.describe SubmissionCommentsController do
  describe "GET 'index'" do
    before :once do
      course = Account.default.courses.create!
      @teacher = course_with_teacher(course: course, active_all: true).user
      @student = course_with_student(course: course, active_all: true).user
      @assignment = course.assignments.create!
      @submission = @assignment.submissions.find_by!(user: @student)
      @submission.submission_comments.create!(author: @teacher, comment: 'a comment')
    end

    context 'given a teacher session' do
      before { user_session(@teacher) }

      context 'given a standard request' do
        before do
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :ok }
        specify { expect(response).to render_template(:index) }
        specify { expect(response.headers.fetch('Content-Type')).to match(/\Aapplication\/pdf/) }
      end

      context 'given a request where no submission is present' do
        before do
          @submission.all_submission_comments.destroy_all
          @submission.destroy
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :not_found }
        specify { expect(response).to render_template('shared/errors/404_message') }
        specify { expect(response.headers.fetch('Content-Type')).to match(/\Atext\/html/) }
      end

      context 'given a request where no submission comments are present' do
        before do
          @submission.all_submission_comments.destroy_all
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :ok }
        specify { expect(response).to render_template(:index) }
        specify { expect(response.headers.fetch('Content-Type')).to match(/\Aapplication\/pdf/) }
      end

      context 'given an anonymized assignment' do
        before do
          @assignment.update!(anonymous_grading: true)
          get :index, params: { submission_id: @submission.id }, format: :pdf
        end

        specify { expect(response).to have_http_status :unauthorized }
        specify { expect(response).to render_template('shared/unauthorized') }
        specify { expect(response.headers.fetch('Content-Type')).to match(/\Atext\/html/) }
      end
    end

    context 'given a student session' do
      before do
        user_session(@student)
        get :index, params: { submission_id: @submission.id }, format: :pdf
      end

      specify { expect(response).to have_http_status :unauthorized }
      specify { expect(response).to render_template('shared/unauthorized') }
      specify { expect(response.headers.fetch('Content-Type')).to match(/\Atext\/html/) }
    end
  end

  describe "DELETE 'destroy'" do
    it "should delete the comment" do
      course_with_teacher_logged_in(:active_all => true)
      submission_comment_model(:author => @user)
      delete 'destroy', params: {:id => @submission_comment.id}, format: "json"
      expect(response).to be_successful
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

    before(:each) do
      user_session(@the_teacher)
    end

    it "allows updating the comment" do
      updated_comment = "an updated comment!"
      patch(
        :update,
        params: @test_params.merge(submission_comment: { comment: updated_comment })
      )
      comment = JSON.parse(response.body).dig("submission_comment", "comment")
      expect(comment).to eq updated_comment
    end

    it "sets the edited_at if the comment is updated" do
      updated_comment = "an updated comment!"
      patch(
        :update,
        params: @test_params.merge(submission_comment: { comment: updated_comment })
      )
      edited_at = JSON.parse(response.body).dig("submission_comment", "edited_at")
      expect(edited_at).to be_present
    end

    it "returns strings for numeric values when passed the json+canvas-string-ids header" do
      request.headers["HTTP_ACCEPT"] = "application/json+canvas-string-ids"
      patch :update, params: @test_params
      id = JSON.parse(response.body).dig("submission_comment", "id")
      expect(id).to be_a String
    end

    it "does not set the edited_at if the comment is not updated" do
      patch :update, params: @test_params
      edited_at = JSON.parse(response.body).dig("submission_comment", "edited_at")
      expect(edited_at).to be_nil
    end

    it "allows updating the status field" do
      expect { patch "update", params: @test_params }.to change { SubmissionComment.draft.count }.by(-1)
    end
  end
end
