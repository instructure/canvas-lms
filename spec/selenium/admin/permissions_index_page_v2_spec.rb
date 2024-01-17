# frozen_string_literal: true

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

require_relative "../common"
require_relative "pages/permissions_page"

describe "permissions index" do
  include_context "in-process server selenium tests"

  before :once do
    @account = Account.default
    @subaccount = Account.create!(name: "subaccount", parent_account_id: @account.id)
    account_admin_user
  end

  def create_role_override(permission_name, role, account, opts)
    new_role = RoleOverride.create!(permission: permission_name,
                                    enabled: opts[:enabled],
                                    locked: opts[:locked],
                                    context: account,
                                    applies_to_self: true,
                                    applies_to_descendants: true,
                                    role_id: role.id,
                                    context_type: "Account")
    new_role.id
  end

  describe "editing role info" do
    before do
      user_session(@admin)
      @custom_student_role = custom_student_role("A Kitty")
      PermissionsIndex.visit(@account)
    end

    it "updates the role to the new name after editing" do
      PermissionsIndex.edit_role(@custom_student_role, "A Better Kitty") # TODO: flakiness lies within
      expect { PermissionsIndex.role_name(@custom_student_role).text }.to become("A Better Kitty")
      expect { PermissionsIndex.edit_tray_header.text }.to become("Edit A Better Kitty")
    end

    it "updates the permission to the correct selection" do
      PermissionsIndex.open_edit_role_tray(@custom_student_role)
      PermissionsIndex.disable_tray_permission("read_announcements", @custom_student_role.id)
      expect { PermissionsIndex.role_tray_permission_state("read_announcements", @custom_student_role.id) }.to become("Disabled")
    end
  end

  describe "Add Role" do
    before do
      user_session(@admin)
      PermissionsIndex.visit(@account)
    end

    it "opens the edit tray when you click an edit icon" do
      PermissionsIndex.add_role("best role name ever")
      expect(PermissionsIndex.role_header).to include_text("Student\nbest role name ever\n")
    end

    it "focuses on newly created role when you close out all the thing" do
      role_name = "no this is the best role name ever"
      PermissionsIndex.add_role(role_name)
      PermissionsIndex.close_role_tray
      role = Role.find_by(name: role_name)
      check_element_has_focus(PermissionsIndex.role_header_by_id(role))
    end
  end

  describe "permissions table" do
    context "root account" do
      before do
        user_session(@admin)
      end

      it "permissions enables on grid" do
        PermissionsIndex.visit(@account)
        permission_name = "manage_outcomes"
        PermissionsIndex.change_permission(permission_name, ta_role.id, "enable")
        r = RoleOverride.last
        expect(r.role_id).to eq(ta_role.id)
        expect(r.permission).to eq(permission_name)
        expect(r.enabled).to be(true)
        expect(r.locked).to be(false)
      end

      it "permissions disables on grid" do
        PermissionsIndex.visit(@account)
        permission_name = "read_announcements"
        PermissionsIndex.change_permission(permission_name, student_role.id, "disable")
        r = RoleOverride.last
        expect(r.role_id).to eq(student_role.id)
        expect(r.permission).to eq(permission_name)
        expect(r.enabled).to be(false)
        expect(r.locked).to be(false)
      end

      it "permissions locks on grid" do
        PermissionsIndex.visit(@account)
        permission_name = "manage_outcomes"
        PermissionsIndex.change_permission(permission_name, ta_role.id, "lock")
        r = RoleOverride.last
        expect(r.role_id).to eq(ta_role.id)
        expect(r.permission).to eq(permission_name)
        expect(r.locked).to be(true)
      end

      it "permissions unlocks on grid" do
        permission_name = "read_announcements"
        id = create_role_override(permission_name, student_role, @account, enabled: false, locked: true)
        PermissionsIndex.visit(@account)
        PermissionsIndex.change_permission(permission_name, student_role.id, "lock")
        r = RoleOverride.find(id)
        expect(r.role_id).to eq(student_role.id)
        expect(r.permission).to eq(permission_name)
        expect(r.enabled).to be(false)
        expect(r.locked).to be(false)
      end

      it "permissions default on grid works" do
        permission_name = "read_announcements"
        create_role_override(permission_name, student_role, @account, enabled: false, locked: false)
        PermissionsIndex.visit(@account)
        PermissionsIndex.change_permission(permission_name, student_role.id, "use_default")
        r = RoleOverride.where(id: @account.id, permission: permission_name, role_id: student_role.id)
        expect(r).to be_empty
      end

      it "autoscrolls so expanded granular permissions are visible" do
        PermissionsIndex.visit(@account)
        PermissionsIndex.expand_manage_wiki
        expect(PermissionsIndex.permission_link("manage_wiki_create")).to be_displayed
        expect(PermissionsIndex.permission_link("manage_wiki_delete")).to be_displayed
        expect(PermissionsIndex.permission_link("manage_wiki_update")).to be_displayed
      end
    end

    context "subaccount" do
      before do
        user_session(@admin)
      end

      it "locked permission cannot be edited" do
        permission_name = "read_announcements"
        create_role_override(permission_name, student_role, @account, enabled: false, locked: true)
        PermissionsIndex.visit(@subaccount)
        expect(PermissionsIndex.permission_cell(permission_name, student_role.id).find("button")).to be_disabled
      end
    end
  end

  context "in the permissions tray" do
    before do
      admin_logged_in
      @role = custom_teacher_role("test role", account: @account)
      @permission_name = "manage_students"
      PermissionsIndex.visit(@account)
    end

    it "updates a permission when changed in the tray" do
      PermissionsIndex.open_permission_tray(@permission_name)
      PermissionsIndex.disable_tray_permission(@permission_name, @role.id)
      expect { PermissionsIndex.role_tray_permission_state(@permission_name, @role.id) }.to become("Disabled")
      expect { PermissionsIndex.grid_permission_state(@permission_name, @role.id) }.to become("Disabled")
    end
  end

  context "main controls" do
    before do
      user_session(@admin)
      PermissionsIndex.visit(Account.default)
    end

    it "filter based on role" do
      role_name = "TA"
      PermissionsIndex.select_filter(role_name)
      expect(PermissionsIndex.role_link(role_name)).to be_displayed
      expect(f("#content")).not_to contain_css(PermissionsIndex.role_link_css("Teacher"))
    end

    it "search by permission name works correctly" do
      PermissionsIndex.enter_search("Manage Pages")
      expect(PermissionsIndex.permission_link("manage_wiki")).to be_displayed
      expect(f("#content")).not_to contain_css("#permission_manage_interaction_alerts")
    end

    it "search by permission filters according to course / account context type" do
      PermissionsIndex.enter_search("SIS Data")
      expect { PermissionsIndex.permissions_tray_viewable_permissions.count }.to become 1
      PermissionsIndex.choose_tab("account")
      wait_for_ajaximations
      PermissionsIndex.enter_search("SIS Data")
      expect { PermissionsIndex.permissions_tray_viewable_permissions.count }.to become 3
      PermissionsIndex.enter_search("")
      expect { PermissionsIndex.permissions_tray_viewable_permissions.count }.to become > 3
    end
  end
end
