#
# Copyright (C) 2018 - present Instructure, Inc.
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

require_relative './pages/permissions_page'

describe "permissions index" do
  include_context "in-process server selenium tests"

  describe "editing role names" do
    before :each do
      @account = Account.default
      account_admin_user
      user_session(@admin)
      @custom_student_role = custom_student_role("A Kitty")
      PermissionsIndex.visit(@account)
    end

    it "updates the permission to the new name after editing" do
      PermissionsIndex.edit_role(@custom_student_role, "A Better Kitty")
      expect{PermissionsIndex.role_name(@custom_student_role).text}.to become("A Better Kitty")
      expect{PermissionsIndex.edit_tray_header.text}.to become("Edit A Better Kitty")
    end
  end
end
