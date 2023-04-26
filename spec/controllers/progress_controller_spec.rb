# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

require "timecop"

describe ProgressController do
  before :once do
    @course = course_model
    @user = course_with_teacher(course: @course, active_all: true).user
    @progress = Progress.create!(context: @course, tag: "gradebook_to_csv", user: @user)
  end

  describe "show" do
    it "show the progress" do
      user_session(@user)

      get "show", params: { id: @progress.id }
      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["workflow_state"]).to eql("queued")
    end

    it "returns 401 unauthorized when user not authorized" do
      @user2 = User.new
      user_session(@user2)

      get "show", params: { id: @progress.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "cancel" do
    it "cancels the progress. sets workflow_state to failed" do
      user_session(@user)

      post "cancel", params: { id: @progress.id }
      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["workflow_state"]).to eql("failed")
    end

    it "returns 401 unauthorized when user not authorized to cancel" do
      @user2 = User.new
      user_session(@user2)

      post "cancel", params: { id: @progress.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
