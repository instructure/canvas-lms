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
  def create_role_override(permission_name, role, account, opts)
    RoleOverride.create!(:permission => permission_name, :enabled => opts[:enabled],
      :locked => opts[:locked], :context => account, :applies_to_self => true, :applies_to_descendants => true,
      :role_id => role.id, :context_type => 'Account')
  end

  def student_role
    Role.get_built_in_role('StudentEnrollment')
  end

  def ta_role
    Role.get_built_in_role('TaEnrollment')
  end

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

    it "updates the permission to the correct selection" do
      PermissionsIndex.open_edit_role_tray(@custom_student_role)
      PermissionsIndex.disable_tray_permission("read_announcements", @custom_student_role.id)
      expect{PermissionsIndex.role_tray_permission_state("read_announcements", @custom_student_role.id)}.to become('Disabled')
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

    it "focuses on newly created role when you close out all the things" do
      role_name = "no this is the best role name ever"
      PermissionsIndex.add_role(role_name)
      PermissionsIndex.close_role_tray
      role = Role.last
      expect(role.name).to eq(role_name)
      check_element_has_focus(PermissionsIndex.role_header_by_id(role))
    end
  end

  describe "permissions table" do
    before :once do
      @account = Account.default
      @admin = User.create!(:name => "Some User", :short_name => "User")
      @admin.accept_terms
      @admin.register!
      @admin_role = Role.get_built_in_role('AccountAdmin')
      @account.account_users.create!(:user => @admin, :role => @admin_role)
    end

    before :each do
      user_session(@admin)
    end

    it "permissions enables on grid" do
      PermissionsIndex.visit(@account)
      permission_name = "manage_outcomes"
      PermissionsIndex.change_permission(permission_name, ta_role.id, "enable")
      r = RoleOverride.last
      expect(r.role_id).to eq(ta_role.id)
      expect(r.permission).to eq(permission_name)
      expect(r.enabled).to eq(true)
      expect(r.locked).to eq(false)
    end

    it "permissions disables on grid" do
      PermissionsIndex.visit(@account)
      permission_name = "read_announcements"
      PermissionsIndex.change_permission(permission_name, student_role.id, "disable")
      r = RoleOverride.last
      expect(r.role_id).to eq(student_role.id)
      expect(r.permission).to eq(permission_name)
      expect(r.enabled).to eq(false)
      expect(r.locked).to eq(false)
    end

    it "permissions enables and locks on grid" do
      PermissionsIndex.visit(@account)
      permission_name = "manage_outcomes"
      PermissionsIndex.change_permission(permission_name, ta_role.id, "enable_and_lock")
      r = RoleOverride.last
      expect(r.role_id).to eq(ta_role.id)
      expect(r.permission).to eq(permission_name)
      expect(r.enabled).to eq(true)
      expect(r.locked).to eq(true)
    end

    it "permissions disables and locks on grid" do
      skip("because venk said so, COMMS-1227")
      permission_name = "read_announcements"
      PermissionsIndex.change_permission(permission_name, student_role.id, "disable_and_lock")
      r = RoleOverride.last
      expect(r.role_id).to eq(student_role.id)
      expect(r.permission).to eq(permission_name)
      expect(r.enabled).to eq(false)
      expect(r.locked).to eq(true)
    end

    it "permissions default on grid works" do
      permission_name = "read_announcements"
      create_role_override(permission_name, student_role, @account,
        :enabled => false, :locked => false)
      PermissionsIndex.visit(@account)
      PermissionsIndex.change_permission(permission_name, student_role.id, "use_default")
      r = RoleOverride.where(:id => @account.id, :permission => permission_name,
        :role_id => student_role.id)
      expect(r).to be_empty
    end

    it "locked permission cannot be edited by subaccount" do
      subaccount = Account.create!(:name => "subaccount", :parent_account_id => @account.id)
      permission_name = "read_announcements"
      create_role_override(permission_name, student_role, @account, :enabled => false, :locked => true)
      PermissionsIndex.visit(subaccount)
      expect(PermissionsIndex.permission_cell(permission_name, student_role.id).find('button')).
        to have_class('disabled')
    end
  end

  context "in the permissions tray" do
    before :each do
      @account = Account.default
      admin_logged_in
      @role = custom_teacher_role('test role', account: @account)

      @permission_name = 'manage_students'
      PermissionsIndex.visit(@account)
    end

    it "updates a permission when changed in the tray" do
      skip("fragile spec")
      PermissionsIndex.open_permission_tray(@permission_name)
      PermissionsIndex.disable_tray_permission(@permission_name, @role.id)
      expect{PermissionsIndex.role_tray_permission_state(@permission_name, @role.id)}.to become('Disabled')
      expect{PermissionsIndex.grid_permission_state(@permission_name, @role.id)}.to become('Disabled')
    end
  end

  context "main controls" do
    before(:each) do
      @account = Account.default
      account_admin_user
      user_session(@admin)
      PermissionsIndex.visit(Account.default)
    end
    it "filter based on role" do
      role_name = "Student"
      PermissionsIndex.select_filter(role_name)
      expect(PermissionsIndex.role_link(role_name)).to be_displayed
      expect(f('#content')).not_to contain_css(PermissionsIndex.role_link_css("Teacher"))
    end

    it "search by permission name works correctly" do
      PermissionsIndex.enter_search("Course State")
      expect(PermissionsIndex.permission_link("change_course_state")).to be_displayed
      expect(f('#content')).not_to contain_css("#permission_manage_interaction_alerts")
    end
  end
end
