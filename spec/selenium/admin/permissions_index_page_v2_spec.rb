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

  describe "editing role info" do
    before :each do
      @account = Account.default
      account_admin_user
      user_session(@admin)
      @custom_student_role = custom_student_role("A Kitty")
      PermissionsIndex.visit(@account)
    end

    it "updates the role to the new name after editing" do
      PermissionsIndex.edit_role(@custom_student_role, "A Better Kitty")
      expect{PermissionsIndex.role_name(@custom_student_role).text}.to become("A Better Kitty")
      expect{PermissionsIndex.edit_tray_header.text}.to become("Edit A Better Kitty")
    end

    it "updates the permission to the correct section" do
      button_state = PermissionsIndex.edit_role_tray_permissoin_state("read_announcements", @custom_student_role.id)
      expect(button_state).to eq('Enabled')
      PermissionsIndex.open_edit_role_tray(@custom_student_role)
      PermissionsIndex.disable_edit_tray_permission("read_announcements", @custom_student_role.id)
      wait_for_children("#flashalert_message_holder")
      button_state = PermissionsIndex.edit_role_tray_permissoin_state("read_announcements", @custom_student_role.id)
      expect(button_state).to eq('Disabled')
    end
  end

  describe "Add Role" do
    before :each do
      @account = Account.default
      account_admin_user
      user_session(@admin)
      PermissionsIndex.visit(@account)
    end

    it "opens the edit tray when you click an edit icon" do
      PermissionsIndex.add_role("best role name ever")
      expect(PermissionsIndex.role_header).to include_text("Student\nbest role name ever\n")
    end
  end
end
