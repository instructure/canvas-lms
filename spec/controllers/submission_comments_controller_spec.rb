#
# Copyright (C) 2011 Instructure, Inc.
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
      delete 'destroy', :id => @submission_comment.id, :format => "json"
      expect(response).to be_success
    end

  end

  describe "PATCH 'update'" do
    before(:once) do
      course_with_teacher_logged_in(active_all: true)
      submission_comment_model(author: @teacher, draft_comment: true)

      @test_params = {
        id: @submission_comment.id,
        format: :json,
        submission_comment: {
          draft: false
        }
      }
    end

    it 'allows updating the status field' do
      expect { patch 'update', @test_params }.to change { SubmissionComment.draft.count }.by(-1)
    end
  end
end
