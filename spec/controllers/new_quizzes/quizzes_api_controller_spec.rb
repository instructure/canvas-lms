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

describe NewQuizzes::QuizzesApiController do
  before :once do
    Account.site_admin.enable_feature! :new_quiz_public_api
    course_with_teacher
  end

  describe "show" do
    it "returns 200 with empty body" do
      user_session(@user)
      get :show, params: { course_id: @course.id, id: "0" }
      expect(response).to be_successful
    end

    it "returns 404 if the new_quiz_public_api flag is disabled" do
      Account.site_admin.disable_feature! :new_quiz_public_api
      user_session(@user)
      get :show, params: { course_id: @course.id, id: "0" }
      expect(response).to be_not_found
    end
  end
end
