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
      admin = settings.delete(:admin) || @admin
      account = settings.delete(:account) || @admin.account
      role = settings.delete(:role) || @role
      base_role_type = settings.delete(:base_role_type)

      permission = settings.delete(:permission) || @permission

      parameters = {:role => role, :permissions => { permission => settings }}
      parameters[:base_role_type] = base_role_type if base_role_type.present?

      api_call(:post, "/api/v1/accounts/#{account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => account.id.to_s },
        parameters)
    end

    it "should add the role to the account" do
      @account.available_account_roles.should_not include(@role)
      json = api_call_with_settings(:explicit => '1', :enabled => '1')
      @account.reload
      @account.available_account_roles.should include(@role)
    end

    it "should index roles" do
      api_call_with_settings(:explicit => '1', :enabled => '1')
      json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles",
        { :controller => 'role_overrides', :action => 'index', :format => 'json', :account_id => @account.id.to_param })

      json.collect{|role| role['role']}.sort.should == (["AccountAdmin", "NewRole"] + RoleOverride.base_role_types).sort
      json.find{|role| role['role'] == "StudentEnrollment"}['workflow_state'].should == 'active'
    end

    it "should remove a role" do
      api_call_with_settings(:explicit => '1', :enabled => '1')
      @account.reload
      @account.available_account_roles.should include(@role)

      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role}",
         { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :role => @role}, {})

      @account.roles.find_by_name(@role).should be_deleted
      @account.reload
      @account.available_account_roles.should_not include(@role)
    end

    it "should 404 when attempting to remove a deleted role" do
      api_call_with_settings(:explicit => '1', :enabled => '1')
      @account.roles.find_by_name!(@role).destroy

      api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role}",
        { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :role => @role},
        {}, {}, :expected_status => 404)
    end

    it "should add a course-level role to the account" do
      base_role_type = 'TeacherEnrollment'

      @account.available_account_roles.should_not include(@role)
      @account.roles.should be_empty
      json = api_call_with_settings(:base_role_type => base_role_type, :explicit => '1', :enabled => '1')
      @account.reload

      @account.available_account_roles.should_not include(@role)
      @account.roles.count.should == 1
      new_role = @account.roles.first
      new_role.name.should == @role
      new_role.base_role_type.should == base_role_type

      json['base_role_type'].should == base_role_type
    end

    it "should delete a course-level role when there are no enrollments" do
      base_role_type = 'TeacherEnrollment'

      @account.available_account_roles.should_not include(@role)
      @account.roles.should be_empty
      api_call_with_settings(:base_role_type => base_role_type, :explicit => '1', :enabled => '1')
      @account.reload

      @account.roles.active.map(&:name).should include(@role)

      json = api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role}",
               { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :role => @role}, {})

      @account.reload
      @account.roles.active.map(&:name).should_not include(@role)
      @account.roles.find_by_name(@role).workflow_state.should == 'deleted'
      json['workflow_state'].should == 'deleted'
    end

    it "should accept the usual forms of booleans in addition to 0 / 1" do
      api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
              { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @account.id.to_s },
              { 'role' => 'WeirdStudent', 'base_role_type' => 'StudentEnrollment',
                'permissions' => { 'read_forum' => { 'enabled' => 'true', 'explicit' => 'true' },
                                   'moderate_forum' => { 'explicit' => true, 'enabled' => false },
                                   'post_to_forum' => { 'explicit' => 'false' },
                                   'send_messages' => { 'explicit' => 'on', 'locked' => 'yes', 'enabled' => 'off' }} })
      @account.reload
      overrides = @account.role_overrides.find_all_by_enrollment_type('WeirdStudent').index_by(&:permission)
      overrides['read_forum'].enabled.should be_true
      overrides['read_forum'].locked.should be_false
      overrides['moderate_forum'].enabled.should be_false
      overrides['moderate_forum'].locked.should be_false
      overrides['send_messages'].enabled.should be_false
      overrides['send_messages'].locked.should be_true
      overrides['post_to_forum'].should be_nil
    end

    context "when there are enrollments using a course-level role" do
      before :each do
        base_role_type = 'TeacherEnrollment'

        @account.available_account_roles.should_not include(@role)
        @account.roles.should be_empty
        api_call_with_settings(:base_role_type => base_role_type, :explicit => '1', :enabled => '1')
        @account.reload

        @account.roles.active.map(&:name).should include(@role)

        course1 = Course.new(:name => "blah", :account => @account)
        user1 = user()

        account_admin_user(:account => @account)
        enrollment1 = course1.enroll_user(user1, 'TeacherEnrollment')
        enrollment1.role_name = @role
        enrollment1.invite
        enrollment1.accept
        enrollment1.save!
      end

      it "should fail to delete a role that is in use" do
        json = api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role}",
          { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :role => @role},
          {}, {}, { :expected_status => 400 })
        json['message'].should == "Role is in use"
      end

      it "should deactivate a course-level role" do
        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles/#{@role}/deactivate",
          { :controller => 'role_overrides', :action => 'deactivate_role', :format => 'json', :account_id => @account.id.to_param, :role => @role}, {})

        @account.reload
        @account.get_course_role(@role).should_not be_nil
        @account.get_course_role(@role).workflow_state.should == 'inactive'
        json['workflow_state'].should == 'inactive'
      end

      it "should reactivate an inactive role" do
        @account.get_course_role(@role).update_attribute(:workflow_state, 'inactive')

        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles/#{@role}/activate",
          { :controller => 'role_overrides', :action => 'activate_role', :format => 'json', :account_id => @account.id.to_param, :role => @role}, {})

        @account.reload
        @account.roles.active.map(&:name).should include(@role)
        @account.roles.find_by_name(@role).workflow_state.should == 'active'
        json['workflow_state'].should == 'active'
      end

      it "should recycle a deleted role" do
        course_role = @account.roles.find_by_name!(@role)
        course_role.destroy
        @account.roles.active.map(&:name).should_not be_include @role

        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                        { :controller => 'role_overrides', :action => 'add_role',
                          :format => 'json', :account_id => @account.id.to_param},
                        { :role => @role, :base_role_type => 'TeacherEnrollment'})

        course_role.reload
        @account.roles.active.find_by_name!(@role).should == course_role
        course_role.should be_active
        course_role.deleted_at.should be_nil
        course_role.base_role_type.should == 'TeacherEnrollment'
        json['workflow_state'].should == 'active'
      end

      it "should discard old role overrides when recycling a deleted role" do
        course_role = @account.roles.find_by_name!(@role)
        course_role.destroy
        @account.roles.active.map(&:name).should_not be_include @role
        @account.reload.role_overrides.find_all_by_enrollment_type(@role).map(&:permission).should == %w(read_reports)

        api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                  { :controller => 'role_overrides', :action => 'add_role',
                    :format => 'json', :account_id => @account.id.to_param },
                  { :role => @role, :base_role_type => 'StudentEnrollment',
                    :permissions => { 'manage_calendar' => { :enabled => '1', :explicit => '1' }} })
        @account.reload.role_overrides.find_all_by_enrollment_type(@role).map(&:permission).should == %w(manage_calendar)
      end
    end

    it "should require a role" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :permissions => { @permission => { :explicit => '1', :enabled => '1' } } })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "missing required parameter 'role'"}
    end

    it "should fail when given an existing role" do
      course_role = @account.roles.build(:name => @role)
      course_role.base_role_type = AccountUser::BASE_ROLE_NAME
      course_role.workflow_state = 'active'
      course_role.save!

      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "role already exists"}
    end

    it "should fail when given an existing course role" do
      course_role = @account.roles.build(:name => @role)
      course_role.base_role_type = 'StudentEnrollment'
      course_role.save!
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "role already exists"}
    end

    it "should fail when given an existing inactive course role" do
      course_role = @account.roles.build(:name => @role)
      course_role.base_role_type = 'StudentEnrollment'
      course_role.workflow_state = 'inactive'
      course_role.save!
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
                   { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
                   { :role => @role }, {}, { :expected_status => 400 })
      json["message"].should == "role already exists"
    end

    it "should fail for course role without a valid base role type" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role, :base_role_type => "notagoodbaserole" })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "Base role type is invalid"}
    end

    it "should fail for a course role with a reserved name" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
                   { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
                   { :role => 'student', :base_role_type => "StudentEnrollment" })
      response.status.should == '400 Bad Request'
      JSON.parse(response.body).should == {"message" => "Name is reserved"}
    end

    it "should not create an override for course role for account-only permissions" do
      api_call_with_settings(:permission => 'manage_courses', :base_role_type => 'TeacherEnrollment', :explicit => '1', :enabled => '1')
      @account.role_overrides(true).size.should == @initial_count
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

    it "should create an override for course-level roles" do
      api_call_with_settings(:base_role_type => 'TeacherEnrollment', :explicit => '1', :enabled => '0')
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
      r = @account.roles.first
      r.workflow_state = 'deleted'
      r.save!

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
        json.keys.sort.should == ["account", "base_role_type", "permissions", "role", "workflow_state"]
        json["account"].should == {
          "name" => @account.name,
          "root_account_id" => @account.root_account_id,
          "parent_account_id" => @account.parent_account_id,
          "id" => @account.id
        }
        json["role"].should == @role
        json["base_role_type"].should == AccountUser::BASE_ROLE_NAME

        # make sure all the expected keys are there, but don't assert on a
        # *only* the expected keys, since plugins may have added more.
        ([
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
          "read_course_content", "read_course_list", "read_forum",
          "read_question_banks", "read_reports", "read_roster",
          "read_sis", "send_messages", "view_all_grades", "view_group_pages",
          "view_statistics"
        ] - json["permissions"].keys).should be_empty

        json["permissions"][@permission].should == {
          "explicit" => false,
          "readonly" => false,
          "enabled" => false,
          "locked" => false
        }
      end

      it "should only return manageable permissions" do
        # set up a subaccount and admin in subaccount
        subaccount = @account.sub_accounts.create!

        # add a role in that subaccount
        json = api_call_with_settings(:account => subaccount)
        json["account"]["id"].should == subaccount.id

        # become_user is a permission restricted to root account roles. it
        # shouldn't be in the response for this subaccount role.
        json["permissions"].keys.should_not include("become_user")
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

  describe "create permission overrides" do
    before do
      @account = Account.default
      @path = "/api/v1/accounts/#{@account.id}/roles/TeacherEnrollment"
      @path_options = { :controller => 'role_overrides', :action => 'update',
        :account_id => @account.id.to_param, :format => 'json',
        :role => 'TeacherEnrollment' }
      @permissions = { :permissions => {
        :read_question_banks => { :explicit => 1, :enabled => 0,
        :locked => 1 }}}
    end

    context "an authorized user" do
      it "should be able to change permissions" do
        json = api_call(:put, @path, @path_options, @permissions)
        json['permissions']['read_question_banks'].should == {
          'enabled'       => false,
          'locked'        => true,
          'readonly'      => false,
          'prior_default' => true,
          'explicit'      => true }
        json['role'].should eql 'TeacherEnrollment'
        json['account'].should == {
          'root_account_id' => nil,
          'name' => Account.default.name,
          'id' => Account.default.id,
          'parent_account_id' => nil }
      end

      it "should not be able to edit read-only permissions" do
        json = api_call(:put, @path, @path_options, { :permission => {
          :read_forum => { :explicit => 1, :enabled => 0 }}})

        # permissions should remain unchanged
        json['permissions']['read_forum'].should == {
          'explicit' => false,
          'enabled'  => true,
          'readonly' => true,
          'locked'   => true }
      end

      it "should be able to change permissions for account admins" do
        json = api_call(:put, @path.sub(/TeacherEnrollment/, 'AccountAdmin'),
          @path_options.merge(:role => 'AccountAdmin'), { :permissions => {
          :manage_courses => { :explicit => 1, :enabled => 0 }}})
        json['permissions']['manage_courses']['enabled'].should eql false
      end

      it "should not be able to add an unavailable permission for a base role" do
        @path = @path.sub(/TeacherEnrollment/, 'StudentEnrollment')
        @path_options[:role] = "StudentEnrollment"
        @permissions[:permissions][:read_question_banks][:enabled] = 1
        json = api_call(:put, @path, @path_options, @permissions)
        json['permissions']['read_question_banks'].should == {
          'enabled'       => false,
          'locked'        => true,
          'readonly'      => true,
          'explicit'      => false }
      end

      it "should not be able to add an unavailable permission for a course role" do
        role_name = 'new role'
        api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                 { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @account.id.to_s },
                 {:role => role_name, :base_role_type => 'StudentEnrollment'})

        @path = @path.sub(/TeacherEnrollment/, role_name)
        @path_options[:role] = role_name
        @permissions[:permissions][:read_question_banks][:enabled] = 1

        json = api_call(:put, @path, @path_options, @permissions)
        json['permissions']['read_question_banks']['enabled'].should == false

        @account.reload

        override = @account.role_overrides.find_by_permission_and_enrollment_type('read_question_banks', role_name)
        override.should be_nil
      end
    end

    context "an unauthorized user" do
      it "should return 401 unauthorized" do
        user_with_pseudonym
        raw_api_call(:put, @path, @path_options, @permissions)
        response.code.should eql '401'
      end
    end
  end
end
