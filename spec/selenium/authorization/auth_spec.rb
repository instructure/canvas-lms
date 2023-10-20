# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require_relative "../common"
require_relative "pages/logout_page"

describe "auth" do
  include_context "in-process server selenium tests"
  include LogoutPage

  describe "logout" do
    it "presents confirmation on GET /logout" do
      user_with_pseudonym active_user: true
      login_as

      visit_logout_page
      confirm_logout

      keep_trying_until do
        expect(driver.current_url).to match %r{/login/canvas}
      end
    end
  end
end
