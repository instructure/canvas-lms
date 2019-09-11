#
# Copyright (C) 2019 - present Instructure, Inc.
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

require 'spec_helper'

describe ContentSharesController do
  before :once do
    course_with_teacher(active_all: true)
    @course_1 = @course
    @teacher_1 = @teacher
    course_with_teacher(active_all: true)
    @course_2 = @course
    @teacher_2 = @teacher
    assignment_model(course: @course_1, name: 'assignment share')
    @course.root_account.enable_feature!(:direct_share)
  end

  describe "POST #create" do
    before :each do
      user_session(@teacher_1)
    end

    it "returns http success" do
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:created)
      expect(SentContentShare.where(user_id: @teacher_1.id)).to exist
      expect(ReceivedContentShare.where(user_id: @teacher_2.id, sender_id: @teacher_1.id)).to exist
      expect(ContentExport.where(context: @assignment.context)).to exist
      json = JSON.parse(response.body)
      expect(json).to include({
        "name" => @assignment.title,
        "user_id" => @teacher_1.id,
        "read_state" => 'read',
        "sender" => nil,
      })
      expect(json['receivers'].first).to include({'id' => @teacher_2.id})
    end

    it "returns 400 if required parameters aren't included" do
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id}
      expect(response).to have_http_status(:bad_request)

      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)

      post :create, params: {user_id: @teacher_1.id, content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)

      announcement_model(context: @course_1)
      post :create, params: {user_id: @teacher_1.id, content_type: 'announcement', content_id: @a.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)
    end

    it 'returns 400 if the associated content cannot be found' do
      post :create, params: {user_id: @teacher_1.id, content_type: 'discussion_topic', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:bad_request)
    end

    it "returns 401 if the user doesn't have access to export the associated content" do
      user_session(@teacher_2)
      post :create, params: {user_id: @teacher_2.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_1.id]}
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 if the sharing user doesn't match current user" do
      user_session(@teacher_2)
      post :create, params: {user_id: @teacher_1.id, content_type: 'assignment', content_id: @assignment.id, receiver_ids: [@teacher_2.id]}
      expect(response).to have_http_status(:forbidden)
    end
  end
end
