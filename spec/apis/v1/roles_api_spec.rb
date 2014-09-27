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

describe "Roles API", type: :request do
  before :once do
    @account = Account.default
    account_admin_user(:account => @account)
    user_with_pseudonym(:user => @admin)
  end

  describe "Roles CRUD" do
    before :once do
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

    describe "add_role" do 
      it "includes base_role_type_label" do 
        json = api_call_with_settings(:base_role_type => "StudentEnrollment")
        json.should include("base_role_type_label" => "Student")
      end

      it "adds the role to the account" do
        @account.available_account_roles.should_not include(@role)
        json = api_call_with_settings(:explicit => '1', :enabled => '1')
        @account.reload
        @account.available_account_roles.should include(@role)
      end
    end

    describe "index" do
      it "should index roles" do
        api_call_with_settings(:explicit => '1', :enabled => '1')
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param })

        json.collect{|role| role['role']}.sort.should == (["NewRole"] + Role.built_in_role_names).sort
        json.find{|role| role['role'] == "StudentEnrollment"}['workflow_state'].should == 'active'
      end

      it "should paginate" do
        api_call_with_settings(:explicit => '1', :enabled => '1')
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles?per_page=5",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :per_page => '5' })
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="last"})
        json.size.should == 5
        json += api_call(:get, "/api/v1/accounts/#{@account.id}/roles?per_page=5&page=2",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :per_page => '5', :page => '2' })
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="last"})
        json.size.should == 7
        json.collect{|role| role['role']}.sort.should == (["NewRole"] + Role.built_in_role_names).sort
      end

      context "with state parameter" do
        before :once do
          role = @account.roles.create :name => 'inactive_role'
          role.base_role_type = 'StudentEnrollment'
          role.workflow_state = 'inactive'
          role.save!
        end

        it "should list inactive roles" do
          json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles?state[]=inactive",
                          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :state => %w(inactive) })
          json.size.should == 1
          json[0]['role'].should == 'inactive_role'
        end

        it "should omit inactive roles if unspecified" do
          json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles",
                          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param})
          json.size.should == 6
          json.map{|role| role['role']}.should be_exclude 'inactive_role'
        end

        it "should accept multiple states" do
          json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles?state[]=inactive&state[]=active",
                          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :state => %w(inactive active) })
          json.size.should == 7
          json.map{|role| role['role']}.should be_include 'inactive_role'
        end
      end
    end

    describe "show" do
      it "should show a built-in role" do
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/AccountAdmin",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :role => 'AccountAdmin' })
        json['role'].should == 'AccountAdmin'
        json['base_role_type'].should == 'AccountMembership'
        json['workflow_state'].should == 'active'
      end

      it "should show a custom role" do
        role = @account.roles.create :name => 'Assistant Grader'
        role.base_role_type = 'TaEnrollment'
        role.workflow_state = 'inactive'
        role.save!
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/Assistant%20Grader",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :role => 'Assistant Grader' })
        json['role'].should == 'Assistant Grader'
        json['base_role_type'].should == 'TaEnrollment'
        json['workflow_state'].should == 'inactive'
      end

      it "should find roles even when the name contains a period" do
        role = @account.roles.create :name => 'Assistant.Grader'
        role.base_role_type = 'TaEnrollment'
        role.save!
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/Assistant.Grader",
                        { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :role => 'Assistant.Grader' })
        json['role'].should == 'Assistant.Grader'
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/Assistant%2EGrader",
                        { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :role => 'Assistant.Grader' })
        json['role'].should == 'Assistant.Grader'
      end

      it "should not show a deleted role" do
        role = @account.roles.create :name => 'Deleted'
        role.base_role_type = 'AccountMembership'
        role.workflow_state = 'deleted'
        role.save!
        api_call(:get, "/api/v1/accounts/#{@account.id}/roles/Deleted",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :role => 'Deleted' },
          {}, {}, { :expected_status => 404 })
      end
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

    it "should accept the usual forms of booleans in addition to 0 / 1" do
      api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
              { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @account.id.to_s },
              { 'role' => 'WeirdStudent', 'base_role_type' => 'StudentEnrollment',
                'permissions' => { 'read_forum' => { 'enabled' => 'true', 'explicit' => 'true' },
                                   'moderate_forum' => { 'explicit' => true, 'enabled' => false },
                                   'post_to_forum' => { 'explicit' => 'false' },
                                   'send_messages' => { 'explicit' => 'on', 'locked' => 'yes', 'enabled' => 'off' }} })
      @account.reload
      overrides = @account.role_overrides.where(enrollment_type: 'WeirdStudent').index_by(&:permission)
      overrides['read_forum'].enabled.should be_true
      overrides['read_forum'].locked.should be_false
      overrides['moderate_forum'].enabled.should be_false
      overrides['moderate_forum'].locked.should be_false
      overrides['send_messages'].enabled.should be_false
      overrides['send_messages'].locked.should be_true
      overrides['post_to_forum'].should be_nil
    end

    context "when there are enrollments using a course-level role" do
      before :once do
        course1 = Course.create!(:name => "blah", :account => @account)
        user1 = user()

        enrollment1 = course1.enroll_user(user1, 'TeacherEnrollment')
        enrollment1.role_name = @role
        enrollment1.invite
        enrollment1.accept
        enrollment1.save!
        @user = @admin
      end

      before :each do
        base_role_type = 'TeacherEnrollment'

        @account.available_account_roles.should_not include(@role)
        @account.roles.should be_empty
        api_call_with_settings(:base_role_type => base_role_type, :explicit => '1', :enabled => '1')
        @account.reload

        @account.roles.active.map(&:name).should include(@role)
      end

      it "should deactivate a course-level role" do
        json = api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role}",
          { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :role => @role}, {})

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
        @account.roles.where(name: @role).first.workflow_state.should == 'active'
        json['workflow_state'].should == 'active'
      end

      it "should recycle a deleted role" do
        course_role = @account.roles.where(name: @role).first!
        course_role.destroy
        @account.roles.active.map(&:name).should_not be_include @role

        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                        { :controller => 'role_overrides', :action => 'add_role',
                          :format => 'json', :account_id => @account.id.to_param},
                        { :role => @role, :base_role_type => 'TeacherEnrollment'})

        course_role.reload
        @account.roles.active.where(name: @role).first!.should == course_role
        course_role.should be_active
        course_role.deleted_at.should be_nil
        course_role.base_role_type.should == 'TeacherEnrollment'
        json['workflow_state'].should == 'active'
      end

      it "should discard old role overrides when recycling a deleted role" do
        course_role = @account.roles.where(name: @role).first!
        course_role.destroy
        @account.roles.active.map(&:name).should_not be_include @role
        @account.reload.role_overrides.where(enrollment_type: @role).pluck(:permission).should == %w(read_reports)

        api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                  { :controller => 'role_overrides', :action => 'add_role',
                    :format => 'json', :account_id => @account.id.to_param },
                  { :role => @role, :base_role_type => 'StudentEnrollment',
                    :permissions => { 'manage_calendar' => { :enabled => '1', :explicit => '1' }} })
        @account.reload.role_overrides.where(enrollment_type: @role).pluck(:permission).should == %w(manage_calendar)
      end
    end

    it "should require a role" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :permissions => { @permission => { :explicit => '1', :enabled => '1' } } })
      assert_status(400)
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
      assert_status(400)
      JSON.parse(response.body).should == {"message" => "role already exists"}
    end

    it "should fail when given an existing course role" do
      course_role = @account.roles.build(:name => @role)
      course_role.base_role_type = 'StudentEnrollment'
      course_role.save!
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role })
      assert_status(400)
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
      assert_status(400)
      JSON.parse(response.body).should == {"message" => "Base role type is invalid"}
    end

    it "should fail for a course role with a reserved name" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
                   { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
                   { :role => 'student', :base_role_type => "StudentEnrollment" })
      assert_status(400)
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
      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
      override.should_not be_nil
      override.enabled.should be_false
    end

    it "should create an override for course-level roles" do
      api_call_with_settings(:base_role_type => 'TeacherEnrollment', :explicit => '1', :enabled => '0')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
      override.should_not be_nil
      override.enabled.should be_false
    end

    it "should create the override if enabled is nil but locked is 1" do
      api_call_with_settings(:locked => '1')
      @account.role_overrides(true).size.should == @initial_count + 1
      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
      override.should_not be_nil
      override.locked.should be_true
    end

    it "should only set the parts that are specified" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
      override.should_not be_nil
      override.enabled.should be_false
      override.locked.should be_nil

      override.destroy
      r = @account.roles.first
      r.workflow_state = 'deleted'
      r.save!

      api_call_with_settings(:locked => '1')
      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
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
      override = @account.role_overrides.where(permission: restricted_permission, enrollment_type: @role).first
      override.should be_nil

      override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
      override.should_not be_nil
    end

    describe "json response" do
      it "should return the expected json format" do
        json = api_call_with_settings
        json.keys.sort.should == ["account", "base_role_type", "label", "permissions", "role", "workflow_state"]
        json["account"]["id"].should == @account.id
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
    before :once do
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
        json['account']['id'].should == Account.default.id
      end

      it "should not be able to edit read-only permissions" do
        sub = @account.sub_accounts.create!
        @path = "/api/v1/accounts/#{sub.id}/roles/TeacherEnrollment"
        @path_options[:account_id] = sub.id.to_param
        o = @account.role_overrides.create(:permission => 'read_forum', :enrollment_type => 'TeacherEnrollment', :enabled => true)
        o.locked = true
        o.save!

        json = api_call(:put, @path, @path_options, { :permission => {
          :read_forum => { :explicit => 1, :enabled => 0 }}})

        # permissions should remain unchanged
        json['permissions']['read_forum'].should == {
          'explicit' => false,
          'enabled'  => true,
          'readonly' => true,
          'locked'   => true }
      end

      it "should not be able to create permissions for nonexistent roles" do
        api_call(:put, "/api/v1/accounts/#{@account.id}/roles/nonexistent",
          @path_options.merge(:role => "nonexistent"),
          { :permissions =>
            { :read_forum => { :explicit => 1, :enabled => 0 }}},
            {}, { :expected_status => 404 })
        RoleOverride.where(enrollment_type: 'nonexistent').should_not be_exists
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

        @path = @path.sub(/TeacherEnrollment/, URI.escape(role_name))
        @path_options[:role] = role_name
        @permissions[:permissions][:read_question_banks][:enabled] = 1

        json = api_call(:put, @path, @path_options, @permissions)
        json['permissions']['read_question_banks']['enabled'].should == false

        @account.reload

        override = @account.role_overrides.where(permission: 'read_question_banks', enrollment_type: role_name).first
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
