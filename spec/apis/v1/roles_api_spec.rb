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
      @role_name = 'NewRole'
      @permission = 'read_reports'
      @initial_count = @account.role_overrides.size
    end

    def api_call_with_settings(settings={})
      admin = settings.delete(:admin) || @admin
      account = settings.delete(:account) || @admin.account
      role = settings.delete(:role) || @role_name
      base_role_type = settings.delete(:base_role_type)

      permission = settings.delete(:permission) || @permission

      parameters = {:role => role, :permissions => { permission => settings }}
      parameters[:base_role_type] = base_role_type if base_role_type.present?

      json = api_call(:post, "/api/v1/accounts/#{account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => account.id.to_s },
        parameters)
      @role = Role.find_by_id(json["id"])
      json
    end

    describe "add_role" do 
      it "includes base_role_type_label" do 
        json = api_call_with_settings(:base_role_type => "StudentEnrollment")
        expect(json).to include("base_role_type_label" => "Student")
      end

      it "adds the role to the account" do
        json = api_call_with_settings(:explicit => '1', :enabled => '1')
        @account.reload
        expect(@account.available_account_roles).to include(@role)
      end
    end

    describe "index" do
      it "should index roles" do
        api_call_with_settings(:explicit => '1', :enabled => '1')
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param })

        expect(json.collect{|role| role['role']}.sort).to eq (["NewRole"] + Role.visible_built_in_roles.map(&:name)).sort
        expect(json.find{|role| role['role'] == "StudentEnrollment"}['workflow_state']).to eq 'active'
      end

      it "should paginate" do
        api_call_with_settings(:explicit => '1', :enabled => '1')
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles?per_page=5",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :per_page => '5' })
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="last"})
        expect(json.size).to eq 5
        json += api_call(:get, "/api/v1/accounts/#{@account.id}/roles?per_page=5&page=2",
          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :per_page => '5', :page => '2' })
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/roles\?.*page=2.*>; rel="last"})
        expect(json.size).to eq 7
        expect(json.collect{|role| role['role']}.sort).to eq (["NewRole"] + Role.visible_built_in_roles.map(&:name)).sort
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
          expect(json.size).to eq 1
          expect(json[0]['role']).to eq 'inactive_role'
        end

        it "should omit inactive roles if unspecified" do
          json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles",
                          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param})
          expect(json.size).to eq 6
          expect(json.map{|role| role['role']}).to be_exclude 'inactive_role'
        end

        it "should accept multiple states" do
          json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles?state[]=inactive&state[]=active",
                          { :controller => 'role_overrides', :action => 'api_index', :format => 'json', :account_id => @account.id.to_param, :state => %w(inactive active) })
          expect(json.size).to eq 7
          expect(json.map{|role| role['role']}).to be_include 'inactive_role'
        end
      end
    end

    describe "show" do
      it "should show a built-in role" do
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/#{admin_role.id}",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :id => admin_role.id.to_param })
        expect(json['role']).to eq 'AccountAdmin'
        expect(json['base_role_type']).to eq 'AccountMembership'
        expect(json['workflow_state']).to eq 'active'
      end

      it "should show a custom role" do
        role = @account.roles.create :name => 'Assistant Grader'
        role.base_role_type = 'TaEnrollment'
        role.workflow_state = 'inactive'
        role.save!
        json = api_call(:get, "/api/v1/accounts/#{@account.id}/roles/#{role.id}",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :id => role.id.to_param })
        expect(json['role']).to eq 'Assistant Grader'
        expect(json['base_role_type']).to eq 'TaEnrollment'
        expect(json['workflow_state']).to eq 'inactive'
      end

      it "should not show a deleted role" do
        role = @account.roles.create :name => 'Deleted'
        role.base_role_type = 'AccountMembership'
        role.workflow_state = 'deleted'
        role.save!
        api_call(:get, "/api/v1/accounts/#{@account.id}/roles/#{role.id}",
          { :controller => 'role_overrides', :action => 'show', :format => 'json', :account_id => @account.id.to_param, :id => role.id.to_param },
          {}, {}, { :expected_status => 404 })
      end
    end

    it "should add a course-level role to the account" do
      base_role_type = 'TeacherEnrollment'

      expect(@account.roles).to be_empty
      json = api_call_with_settings(:base_role_type => base_role_type, :explicit => '1', :enabled => '1')
      @account.reload

      expect(@account.available_account_roles.map(&:name)).to_not include(@role_name)
      expect(@account.roles.count).to eq 1
      new_role = @account.roles.first
      expect(new_role.name).to eq @role_name
      expect(new_role.base_role_type).to eq base_role_type

      expect(json['base_role_type']).to eq base_role_type
    end

    it "should accept the usual forms of booleans in addition to 0 / 1" do
      json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
              { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @account.id.to_s },
              { 'role' => 'WeirdStudent', 'base_role_type' => 'StudentEnrollment',
                'permissions' => { 'read_forum' => { 'enabled' => 'true', 'explicit' => 'true' },
                                   'moderate_forum' => { 'explicit' => true, 'enabled' => false },
                                   'post_to_forum' => { 'explicit' => 'false' },
                                   'send_messages' => { 'explicit' => 'on', 'locked' => 'yes', 'enabled' => 'off' }} })
      @account.reload

      role = Role.find_by_id(json['id'])
      overrides = @account.role_overrides.where(:role_id => role.id).index_by(&:permission)
      expect(overrides['read_forum'].enabled).to be_truthy
      expect(overrides['read_forum'].locked).to be_falsey
      expect(overrides['moderate_forum'].enabled).to be_falsey
      expect(overrides['moderate_forum'].locked).to be_falsey
      expect(overrides['send_messages'].enabled).to be_falsey
      expect(overrides['send_messages'].locked).to be_truthy
      expect(overrides['post_to_forum']).to be_nil
    end

    context "when there are enrollments using a course-level role" do
      before :once do
        @role = custom_teacher_role(@role_name, :account => @account)
        course1 = Course.create!(:name => "blah", :account => @account)
        user1 = user()

        enrollment1 = course1.enroll_user(user1, 'TeacherEnrollment', :role => @role)
        enrollment1.invite
        enrollment1.accept
        enrollment1.save!
        @user = @admin
      end

      it "should deactivate a course-level role" do
        json = api_call(:delete, "/api/v1/accounts/#{@account.id}/roles/#{@role.id}",
          { :controller => 'role_overrides', :action => 'remove_role', :format => 'json', :account_id => @account.id.to_param, :id => @role.id}, {})

        @role.reload
        expect(@role.workflow_state).to eq 'inactive'
        expect(json['workflow_state']).to eq 'inactive'
      end

      it "should reactivate an inactive role" do
        @role.update_attribute(:workflow_state, 'inactive')

        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles/#{@role.id}/activate",
          { :controller => 'role_overrides', :action => 'activate_role', :format => 'json', :account_id => @account.id.to_param, :id => @role.id}, {})

        @account.reload
        @role.reload
        expect(@role.workflow_state).to eq 'active'
        expect(json['workflow_state']).to eq 'active'
      end

      it "should not recycle a deleted role" do
        @role.destroy
        expect(@account.roles.active.map(&:name)).to_not be_include @role_name

        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                        { :controller => 'role_overrides', :action => 'add_role',
                          :format => 'json', :account_id => @account.id.to_param},
                        { :role => @role_name, :base_role_type => 'TeacherEnrollment'})

        new_role = Role.where(:id => json["id"]).first
        expect(@role.id).to_not eq new_role.id
      end
    end

    it "should require a role" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :permissions => { @permission => { :explicit => '1', :enabled => '1' } } })
      assert_status(400)
      expect(JSON.parse(response.body)).to eq({"message" => "missing required parameter 'role'"})
    end

    it "should fail for course role without a valid base role type" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role_name, :base_role_type => "notagoodbaserole" })
      assert_status(400)
      expect(JSON.parse(response.body)).to eq({"message" => "Base role type is invalid"})
    end

    it "should fail for a course role with a reserved name" do
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
                   { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
                   { :role => 'student', :base_role_type => "StudentEnrollment" })
      assert_status(400)
      expect(JSON.parse(response.body)).to eq({"message" => "Name is reserved"})
    end

    it "should not create an override for course role for account-only permissions" do
      api_call_with_settings(:permission => 'manage_courses', :base_role_type => 'TeacherEnrollment', :explicit => '1', :enabled => '1')
      expect(@account.role_overrides(true).size).to eq @initial_count
    end

    it "should not create an override if enabled is nil and locked is not 1" do
      api_call_with_settings(:explicit => '1', :locked => '0')
      expect(@account.role_overrides(true).size).to eq @initial_count
    end

    it "should not create an override if explicit is not 1 and locked is not 1" do
      api_call_with_settings(:explicit => '0', :enabled => '1', :locked => '0')
      expect(@account.role_overrides(true).size).to eq @initial_count
    end

    it "should create the override if explicit is 1 and enabled has a value" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      expect(@account.role_overrides(true).size).to eq @initial_count + 1
      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
      expect(override.enabled).to be_falsey
    end

    it "should create an override for course-level roles" do
      api_call_with_settings(:base_role_type => 'TeacherEnrollment', :explicit => '1', :enabled => '0')
      expect(@account.role_overrides(true).size).to eq @initial_count + 1
      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
      expect(override.enabled).to be_falsey
    end

    it "should create the override if enabled is nil but locked is 1" do
      api_call_with_settings(:locked => '1')
      expect(@account.role_overrides(true).size).to eq @initial_count + 1
      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
      expect(override.locked).to be_truthy
    end

    it "should only set the parts that are specified" do
      api_call_with_settings(:explicit => '1', :enabled => '0')
      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
      expect(override.enabled).to be_falsey
      expect(override.locked).to be_nil

      override.destroy
      r = @account.roles.first
      r.workflow_state = 'deleted'
      r.save!

      api_call_with_settings(:locked => '1')
      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
      expect(override.enabled).to be_nil
      expect(override.locked).to be_truthy
    end

    it "should discard restricted permissions" do
      # @admin.account is not Account.site_admin, so the site_admin permission
      # (and a few others) is not available to roles on that account.
      restricted_permission = 'site_admin'

      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/roles",
        { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @admin.account.id.to_s },
        { :role => @role_name,
          :permissions => {
            @permission => { :explicit => '1', :enabled => '1' },
            restricted_permission => { :explicit => '1', :enabled => '1' } } })

      @role = Role.find_by_id(json["id"])

      expect(@account.role_overrides(true).size).to eq @initial_count + 1 # not 2
      override = @account.role_overrides.where(:permission => restricted_permission, :role_id => @role.id).first
      expect(override).to be_nil

      override = @account.role_overrides.where(:permission => @permission, :role_id => @role.id).first
      expect(override).to_not be_nil
    end

    describe "json response" do
      it "should return the expected json format" do
        json = api_call_with_settings
        expect(json.keys.sort).to eq ["account", "base_role_type", "id", "label", "permissions", "role", "workflow_state"]
        expect(json["account"]["id"]).to eq @account.id
        expect(json["id"]).to eq @role.id
        expect(json["role"]).to eq @role_name
        expect(json["base_role_type"]).to eq AccountUser::DEFAULT_BASE_ROLE_TYPE

        # make sure all the expected keys are there, but don't assert on a
        # *only* the expected keys, since plugins may have added more.
        expect([
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
        ] - json["permissions"].keys).to be_empty

        expect(json["permissions"][@permission]).to eq({
          "explicit" => false,
          "readonly" => false,
          "enabled" => false,
          "locked" => false
        })
      end

      it "should only return manageable permissions" do
        # set up a subaccount and admin in subaccount
        subaccount = @account.sub_accounts.create!

        # add a role in that subaccount
        json = api_call_with_settings(:account => subaccount)
        expect(json["account"]["id"]).to eq subaccount.id

        # become_user is a permission restricted to root account roles. it
        # shouldn't be in the response for this subaccount role.
        expect(json["permissions"].keys).not_to include("become_user")
      end

      it "should set explicit and prior default if enabled was provided" do
        json = api_call_with_settings(:explicit => '1', :enabled => '1')
        expect(json["permissions"][@permission]).to eq({
          "explicit" => true,
          "readonly" => false,
          "enabled" => true,
          "locked" => false,
          "prior_default" => false
        })
      end
    end
  end

  describe "create permission overrides" do
    before :once do
      @account = Account.default
      @path = "/api/v1/accounts/#{@account.id}/roles/#{teacher_role.id}"
      @path_options = { :controller => 'role_overrides', :action => 'update',
        :account_id => @account.id.to_param, :format => 'json',
        :id => teacher_role.id }
      @permissions = { :permissions => {
        :read_question_banks => { :explicit => 1, :enabled => 0,
        :locked => 1 }}}
    end

    context "an authorized user" do
      it "should be able to change permissions" do
        json = api_call(:put, @path, @path_options, @permissions)
        expect(json['permissions']['read_question_banks']).to eq({
          'enabled'       => false,
          'locked'        => true,
          'readonly'      => false,
          'prior_default' => true,
          'explicit'      => true })
        expect(json['id']).to eql teacher_role.id
        expect(json['role']).to eql 'TeacherEnrollment'
        expect(json['account']['id']).to eq Account.default.id
      end

      it "should not be able to edit read-only permissions" do
        sub = @account.sub_accounts.create!
        @path = "/api/v1/accounts/#{sub.id}/roles/#{teacher_role.id}"
        @path_options[:account_id] = sub.id.to_param
        o = @account.role_overrides.create(:permission => 'read_forum', :role => teacher_role, :enabled => true)
        o.locked = true
        o.save!

        json = api_call(:put, @path, @path_options, { :permission => {
          :read_forum => { :explicit => 1, :enabled => 0 }}})

        # permissions should remain unchanged
        expect(json['permissions']['read_forum']).to eq({
          'explicit' => false,
          'enabled'  => true,
          'readonly' => true,
          'locked'   => true })
      end

      it "should not be able to create permissions for nonexistent roles" do
        api_call(:put, "/api/v1/accounts/#{@account.id}/roles/nonexistent",
          @path_options.merge(:id => "nonexistent"),
          { :permissions =>
            { :read_forum => { :explicit => 1, :enabled => 0 }}},
            {}, { :expected_status => 404 })
      end

      it "should be able to change permissions for account admins" do
        json = api_call(:put, "/api/v1/accounts/#{@account.id}/roles/#{admin_role.id}",
          @path_options.merge(:id => admin_role.id), { :permissions => {
          :manage_courses => { :explicit => 1, :enabled => 0 }}})
        expect(json['permissions']['manage_courses']['enabled']).to eql false
      end

      it "should not be able to add an unavailable permission for a base role" do
        @path = "/api/v1/accounts/#{@account.id}/roles/#{student_role.id}"
        @path_options[:id] = student_role.id
        @permissions[:permissions][:read_question_banks][:enabled] = 1
        json = api_call(:put, @path, @path_options, @permissions)
        expect(json['permissions']['read_question_banks']).to eq({
          'enabled'       => false,
          'locked'        => true,
          'readonly'      => true,
          'explicit'      => false })
      end

      it "should not be able to add an unavailable permission for a course role" do
        role_name = 'new role'
        json = api_call(:post, "/api/v1/accounts/#{@account.id}/roles",
                 { :controller => 'role_overrides', :action => 'add_role', :format => 'json', :account_id => @account.id.to_s },
                 {:role => role_name, :base_role_type => 'StudentEnrollment'})

        role = Role.find_by_id(json["id"])
        @path = "/api/v1/accounts/#{@account.id}/roles/#{role.id}"
        @path_options[:id] = role.id
        @permissions[:permissions][:read_question_banks][:enabled] = 1

        json = api_call(:put, @path, @path_options, @permissions)
        expect(json['permissions']['read_question_banks']['enabled']).to eq false

        @account.reload

        override = @account.role_overrides.where(:permission => 'read_question_banks', :role_id => role.id).first
        expect(override).to be_nil
      end
    end

    context "an unauthorized user" do
      it "should return 401 unauthorized" do
        user_with_pseudonym
        raw_api_call(:put, @path, @path_options, @permissions)
        expect(response.code).to eql '401'
      end
    end
  end
end
