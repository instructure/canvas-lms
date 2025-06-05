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

describe ItemBanksController do
  describe "#show" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "returns a 404 when ams_service feature flag is disabled" do
      @course.root_account.disable_feature!(:ams_service)

      get :show, params: { course_id: @course.id }

      expect(response).to have_http_status(:not_found)
      expect(response).to render_template("shared/errors/404_message")
    end

    it "renders successfully when ams_service feature flag is enabled" do
      @course.root_account.enable_feature!(:ams_service)

      get :show, params: { course_id: @course.id }

      expect(response).to be_successful
    end
  end
end
