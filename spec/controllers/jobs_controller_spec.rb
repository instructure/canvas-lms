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
#

describe JobsController do
  describe "GET 'index'" do
    it "returns a 302 redirect to root path for non-site-admin users" do
      account_admin_user(active_all: true)
      user_session(@admin)
      get :index
      expect(response).to redirect_to(root_path)
    end

    it "returns a 200 response for site admin users" do
      site_admin_user(active_all: true)
      user_session(@admin)
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end
