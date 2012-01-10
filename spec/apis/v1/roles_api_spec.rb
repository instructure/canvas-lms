#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Roles API", :type => :integration do
  before do
    @account = Account.default
    account_admin_user(:account => @account)
    user_with_pseudonym(:user => @admin)
  end

  describe "add_role" do
    before :each do
      @role = 'NewRole'
      @permission = 'read_reports'
      @initial_count = @account.role_overrides.size
    end

    def api_call_with_settings(settings={})
      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role,
          :permissions => { @permission => settings } })
    end

    it "should add the role to the account" do
      @account.account_membership_types.should_not include(@role)
      json = api_call_with_settings(:explicit => '1', :enabled => '1')
      @account.reload
      @account.account_membership_types.should include(@role)
    end

    it "should require a role" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :permissions => { @permission => { :explicit => '1', :enabled => '1' } } })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "missing required parameter 'role'"}
    end

    it "should fail when given an existing role" do
      @account.add_account_membership_type(@role)
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "role already exists"}
    end

    it "should not create an override if enabled is nil and locked is not 1" do
      api_call_with_settings(:explicit => '1', :locked => '0')
      @account.role_overrides(true).size.should == @initial_count
    end

    it "should not create an override if explicit is not 1 and locked is not 1" do
      api_call_with_settings(:explicit => '0', :enabled => '1', :locked => '0')
      @account.role_overrides(true).size.should == @initial_count
    end

    it "should create the override if explicit is 1 and enabled has a value" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_false
    end

    it "should create the override if enabled is nil but locked is 1" do
      api_call_with_settings(:locked => '1')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.locked.should be_true
    end

    it "should only set the parts that are specified" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      override = @account.role_overrides(true).find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_false
      override.locked.should be_nil

      override.destroy
      @account.remove_account_membership_type(@role)

      api_call_with_settings(:locked => '1')
      override = @account.role_overrides(true).find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
      override.enabled.should be_nil
      override.locked.should be_true
    end

    it "should discard restricted permissions" do
      # @admin.account is not Account.site_admin, so the site_admin permission
      # (and a few others) is not available to roles on that account.
      restricted_permission = 'site_admin'

      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role,
          :permissions => {
            @permission => { :explicit => '1', :enabled => '1' },
            restricted_permission => { :explicit => '1', :enabled => '1' } } })

      @account.role_overrides(true).size.should == @initial_count + 1 # not 2
      override = @account.role_overrides.find_by_permission_and_enrollment_type(restricted_permission, @role)
      override.should be_nil

      override = @account.role_overrides.find_by_permission_and_enrollment_type(@permission, @role)
      override.should_not be_nil
    end

    describe "json response" do
      it "should return the expected json format" do
        json = api_call_with_settings
        json.keys.sort.should == ["account", "permissions", "role"]
        json["account"].should == {
          "name" => @account.name,
          "root_account_id" => @account.root_account_id,
          "parent_account_id" => @account.parent_account_id,
          "id" => @account.id,
          "sis_account_id" => @account.sis_source_id
        }
        json["role"].should == @role
        json["permissions"].keys.sort.should == [
          "become_user", "change_course_state",
          "comment_on_others_submissions", "create_collaborations",
          "create_conferences", "manage_account_memberships",
          "manage_account_settings", "manage_admin_users", "manage_alerts",
          "manage_assignments", "manage_calendar", "manage_content",
          "manage_courses", "manage_files", "manage_grades", "manage_groups",
          "manage_interaction_alerts", "manage_outcomes",
          "manage_role_overrides", "manage_sections", "manage_sis",
          "manage_students", "manage_user_logins", "manage_user_notes",
          "manage_wiki", "moderate_forum", "post_to_forum",
          "read_course_content", "read_course_list", "read_question_banks",
          "read_reports", "read_roster", "send_messages", "view_all_grades",
          "view_group_pages", "view_statistics"
        ]

        json["permissions"][@permission].should == {
          "explicit" => false,
          "readonly" => false,
          "enabled" => false,
          "locked" => false
        }
      end

      it "should set explicit and prior default if enabled was provided" do
        json = api_call_with_settings(:explicit => '1', :enabled => '1')
        json["permissions"][@permission].should == {
          "explicit" => true,
          "readonly" => false,
          "enabled" => true,
          "locked" => false,
          "prior_default" => false
        }
      end
    end
  end
end
