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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SubmissionCommentsController do

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
