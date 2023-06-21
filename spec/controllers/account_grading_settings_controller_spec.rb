# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe AccountGradingSettingsController, type: :request do
  require_relative "../spec_helper"

  context "account admin" do
    before(:once) do
      @account = Account.default
      @admin = account_admin_user(account: @account)
    end

    it "js_env POINTS_BASED_GRADING_SCHEMES_ENABLED is true when points_based_grading_schemes ff is on" do
      Account.site_admin.enable_feature!(:points_based_grading_schemes)
      user_session(@admin)
      get "/accounts/" + @account.id.to_s + "/grading_settings"
      expect(response).to be_successful
      expect((controller.js_env[:POINTS_BASED_GRADING_SCHEMES_ENABLED] || [])).to be(true)
    end
  end
end
