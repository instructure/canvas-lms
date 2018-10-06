#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe RoleOverride do
  it "should retain the prior permission when it encounters the first explicit override" do
    @account = account_model(:parent_account => Account.default)

    role = teacher_role
    RoleOverride.create!(:context => @account, :permission => 'moderate_forum',
                         :role => role, :enabled => false)
    permissions = RoleOverride.permission_for(Account.default, :moderate_forum, role)
    expect(permissions[:enabled]).to be_truthy
    expect(permissions[:prior_default]).to be_truthy
    expect(permissions[:explicit]).to eq false

    permissions = RoleOverride.permission_for(@account, :moderate_forum, role)
    expect(permissions[:enabled]).to be_falsey
    expect(permissions[:prior_default]).to be_truthy
    expect(permissions[:explicit]).to eq true
  end

  it "should use the immediately parent context as the prior permission when there are multiple explicit levels" do
    a1 = account_model
    a2 = account_model(:parent_account => a1)
    a3 = account_model(:parent_account => a2)

    role = teacher_role
    RoleOverride.create!(:context => a1, :permission => 'moderate_forum',
                         :role => role, :enabled => false)
    RoleOverride.create!(:context => a2, :permission => 'moderate_forum',
                         :role => role, :enabled => true)

    permissions = RoleOverride.permission_for(a1, :moderate_forum, role)
    expect(permissions[:enabled]).to be_falsey
    expect(permissions[:prior_default]).to be_truthy
    expect(permissions[:explicit]).to eq true

    permissions = RoleOverride.permission_for(a2, :moderate_forum, role)
    expect(permissions[:enabled]).to be_truthy
    expect(permissions[:prior_default]).to be_falsey
    expect(permissions[:explicit]).to eq true

    permissions = RoleOverride.permission_for(a3, :moderate_forum, role)
    expect(permissions[:enabled]).to be_truthy
    expect(permissions[:prior_default]).to be_truthy
    expect(permissions[:explicit]).to eq false
  end

  it "should be able to be disabled for a custom course role even if enabled from above on the role account (if not locked)" do
    a1 = account_model
    c1 = course_factory(:account => a1, :active_course => true)
    a2 = account_model(:parent_account => a1)
    c2 = course_factory(:account => a2, :active_course => true)

    role = custom_student_role("some role", :account => a1)
    u1 = user_factory
    c1.enroll_student(u1, :role => role)
    u2 = user_factory
    c2.enroll_student(u2, :role => role)

    ro = RoleOverride.create!(:context => a1, :permission => 'moderate_forum',
      :role => role, :enabled => true)
    RoleOverride.create!(:context => a2, :permission => 'moderate_forum',
      :role => role, :enabled => false)

    expect(c1.grants_right?(u1, :moderate_forum)).to be_truthy
    expect(c2.grants_right?(u2, :moderate_forum)).to be_falsey

    ro.locked = true
    ro.save!

    AdheresToPolicy::Cache.clear
    RoleOverride.clear_cached_contexts
    c2 = Course.find(c2.id)

    expect(c2.grants_right?(u2, :moderate_forum)).to be_truthy
  end

  it "should not fail when a context's associated accounts are missing" do
    group_model
    allow(@group).to receive(:account).and_return(nil)
    expect{
      RoleOverride.permission_for(@group, :read_course_content, teacher_role)
    }.to_not raise_error
  end

  it "should update the roles updated_at timestamp on save" do
    account = account_model(:parent_account => Account.default)
    role = teacher_role
    role_override = RoleOverride.create!(:context => account, :permission => 'moderate_forum',
                                         :role => role, :enabled => false)
    role.update!(updated_at: 1.day.ago)
    old_updated_at = role.updated_at

    role_override.update!(enabled: true)
    new_updated_at = role.updated_at

    expect(old_updated_at).not_to eq(new_updated_at)
  end

  describe "student view permissions" do
    it "should mirror student permissions" do
      permission = 'comment_on_others_submissions'

      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @fake_student = @course.student_view_student

      expect(@student.enrollments.first.has_permission_to?(permission.to_sym)).to be_falsey
      expect(@fake_student.enrollments.first.has_permission_to?(permission.to_sym)).to be_falsey

      RoleOverride.manage_role_override(Account.default, student_role, permission, :override => true)
      RoleOverride.clear_cached_contexts

      expect(@student.enrollments.first.has_permission_to?(permission.to_sym)).to be_truthy
      expect(@fake_student.enrollments.first.has_permission_to?(permission.to_sym)).to be_truthy
    end
  end

  describe "manage_role_override" do
    before :once do
      @account = account_model(:parent_account => Account.default)
      @role = @account.roles.new(:name => 'NewRole')
      @role.base_role_type = 'AccountMembership'
      @role.save!
      @permission = 'read_reports'
    end

    describe "override already exists" do
      before :once do
        @existing_override = @account.role_overrides.build(
          :permission => @permission,
          :role => @role)
        @existing_override.enabled = true
        @existing_override.locked = false
        @existing_override.save!
        @initial_count = @account.role_overrides.size
      end

      it "should update an existing override if override has a value" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        expect(@account.role_overrides.size).to eq @initial_count
        expect(new_override).to eq @existing_override.reload
        expect(@existing_override.enabled).to be_falsey
      end

      it "should update an existing override if override is nil but locked is truthy" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        expect(@account.role_overrides.size).to eq @initial_count
        expect(new_override).to eq @existing_override.reload
        expect(@existing_override.locked).to be_truthy
      end

      it "should only update the parts that are specified" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        @existing_override.reload
        expect(@existing_override.locked).to be_falsey

        @existing_override.enabled = true
        @existing_override.save

        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        @existing_override.reload
        expect(@existing_override.enabled).to be_truthy
      end

      it "should delete an existing override if override is nil and locked is not truthy" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => false)
        expect(@account.role_overrides.size).to eq @initial_count - 1
        expect(new_override).to be_nil
        expect(RoleOverride.where(id: @existing_override).first).to be_nil
      end
    end

    describe "no override yet" do
      before :once do
        @initial_count = @account.role_overrides.size
      end

      it "should not create an override if override is nil and locked is not truthy" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => false)
        expect(override).to be_nil
        expect(@account.role_overrides.size).to eq @initial_count
      end

      it "should create the override if override has a value" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        expect(@account.role_overrides.size).to eq @initial_count + 1
        expect(override.enabled).to be_falsey
      end

      it "should create the override if override is nil but locked is truthy" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        expect(@account.role_overrides.size).to eq @initial_count + 1
        expect(override.locked).to be_truthy
      end

      it "should only set the parts that are specified" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        expect(override.enabled).to eq false
        expect(override.locked).to eq false
        override.destroy

        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        expect(override.enabled).to eq true
        expect(override.locked).to eq true
      end
    end
  end

  describe "#permissions_for" do
    before :once do
      @account = account_model(:parent_account => Account.default)
      @role = @account.roles.new(:name => 'NewRole')
      @role.base_role_type = 'AccountMembership'
      @role.save!
      @permission = :view_group_pages
    end

    def check_permission(role, enabled)
      hash = RoleOverride.permission_for(@account, @permission, role)
      expect((!!hash[:enabled])).to eq enabled
    end

    def create_role(base_role, role_name)
      @role = @account.roles.build(:name => role_name.to_s)
      @role.base_role_type = base_role.to_s
      @role.workflow_state = 'active'
      @role.save!
    end

    def create_override(role, enabled)
      RoleOverride.create!(:context => @account, :permission => @permission.to_s,
                         :role => role, :enabled => enabled)
    end

    it "should not mark a permission as explicit in a sub account when it's explicit in the root" do
      @sub_account = @account
      @account = Account.default
      create_role('AccountMembership', 'somerole')
      create_override(@role, true)
      permission_data = RoleOverride.permission_for(@sub_account, @permission, @role)
      expect(permission_data[:enabled]).to be_truthy
      expect(permission_data[:explicit]).to be_falsey
      expect(permission_data[:prior_default]).to be_truthy

      permission_data = RoleOverride.permission_for(@account, @permission, @role)
      expect(permission_data[:enabled]).to be_truthy
      expect(permission_data[:explicit]).to be_truthy
      expect(permission_data[:prior_default]).to be_falsey
    end

    context 'using :account_allows' do
      it "should be enabled for account if not specified" do
        permission_data = RoleOverride.permission_for(@account, :undelete_courses, admin_role)
        expect(permission_data[:account_allows]).to be_truthy
        expect(permission_data[:enabled]).to be_truthy
        expect(permission_data[:explicit]).to be_falsey
      end

      it "should be enabled for account if specified" do
        root_account = @account.root_account
        root_account.settings[:admins_can_view_notifications] = true
        root_account.save!
        permission_data = RoleOverride.permission_for(@account, :view_notifications, admin_role)
        expect(permission_data[:account_allows]).to be_truthy
        expect(permission_data[:enabled]).to be_falsey
        expect(permission_data[:explicit]).to be_falsey
      end

      it "should be disabled for account if lambda evaluates to false" do
        root_account = @account.root_account
        root_account.settings[:admins_can_view_notifications] = false
        root_account.save!
        permission_data = RoleOverride.permission_for(@account, :view_notifications, admin_role)
        expect(permission_data[:account_allows]).to be_falsey
        expect(permission_data[:enabled]).to be_falsey
        expect(permission_data[:explicit]).to be_falsey
      end
    end

    context "admin roles" do
      it "should special case AccountAdmin role to use AccountAdmin as base role" do
        # the default base role type has no permissions, so this tests it is getting
        # them from the AccountAdmin type.
        check_permission(admin_role, true)
      end

      it "should use role override for role" do
        create_override(@role, true)

        check_permission(@role, true)
      end

      it "should fall back to base role permissions" do
        check_permission(@role, false)
      end

      it "should default :view_notifications to false" do
        permission_data = RoleOverride.permission_for(@account, @permission, @role)
        expect(permission_data[:enabled]).to be_falsey
        expect(permission_data[:explicit]).to be_falsey
      end
    end

    context "course roles" do
      RoleOverride.enrollment_type_labels.each do |base_role|
        context "#{base_role[:name]} enrollments" do
          before do
            @base_role_name = base_role[:name]
            @base_role = Role.get_built_in_role(@base_role_name)
            @role_name = 'course role'
            @default_perm = RoleOverride.permissions[@permission][:true_for].include?(@base_role_name)
            @parent_account = @account
            @sub = account_model(:parent_account => @account)
            @account = @parent_account
            create_role(@base_role_name, @role_name)
          end

          it "should use default permissions" do
            check_permission(@role, @default_perm)
          end

          it "should use permission for role" do
            create_override(@role, !@default_perm)

            check_permission(@role, !@default_perm)
          end

          it "should not find override for base type of role" do
            create_override(@role, @default_perm)
            create_override(Role.get_built_in_role(@base_role_name), !@default_perm)

            check_permission(@role, @default_perm)
            check_permission(@base_role, !@default_perm)
          end

          it "should use permission for role in parent account" do
            @course = @sub.courses.create!

            #create permission in parent
            create_override(@role, !@default_perm)

            # check based on sub account
            hash = RoleOverride.permission_for(@course, @permission, @role)
            expect((!!hash[:enabled])).to eq !@default_perm
          end

          it "should use permission for role in parent account if the course is the role_context and has the same id as an account" do
            @course = @sub.courses.build
            @course.id = Account.site_admin.id
            @course.save!

            #create permission in parent
            create_override(@role, !@default_perm)

            # check based on sub account
            hash = RoleOverride.permission_for(@course, @permission, @role, @course)
            expect((!!hash[:enabled])).to eq !@default_perm
          end
        end
      end
    end

    context "account_only" do
      before :once do
        @site_admin = User.create!
        Account.site_admin.account_users.create!(user: @site_admin)
        @root_admin = User.create!
        Account.default.account_users.create!(user: @root_admin)
        @sub_admin = User.create!
        @sub_account = Account.default.sub_accounts.create!
        @sub_account.account_users.create!(user: @sub_admin)
      end

      it "should not grant site admin permissions to normal account admins" do
        expect(Account.default.grants_right?(@root_admin, :manage_site_settings)).to be_falsey
        # check against the normal root account, but granted rights from Site Admin
        expect(Account.default.grants_right?(@site_admin, :manage_site_settings)).to be_truthy
        # check against Site Admin
        expect(Account.site_admin.grants_right?(@site_admin, :manage_site_settings)).to be_truthy
      end

      it "should not grant root only permissions to sub account admins" do
        expect(Account.default.grants_right?(@root_admin, :become_user)).to be_truthy
        expect(@sub_account.grants_right?(@sub_admin, :become_user)).to be_falsey
        # check against the sub account, but granted rights from the root account
        expect(@sub_account.grants_right?(@root_admin, :become_user)).to be_truthy
      end

      it "should grant root only permissions in courses when the user is a root account admin" do
        @course = @account.courses.create!
        expect(@course.grants_right?(@root_admin, :become_user)).to be_truthy
      end

      it "should not allow a sub-account to revoke a permission granted to a parent account" do
        @sub_account.role_overrides.create!(role: admin_role, enabled: false, permission: :manage_admin_users)
        expect(@sub_account.grants_right?(@site_admin, :manage_admin_users)).to be_truthy
        expect(@sub_account.grants_right?(@root_admin, :manage_admin_users)).to be_truthy
        expect(@sub_account.grants_right?(@sub_admin, :manage_admin_users)).to be_falsey
      end
    end

    context "sharding" do
      specs_require_sharding

      it "should find role overrides on a non-current shard" do
        @shard1.activate do
          @account = Account.create!
          @account.role_overrides.create!(:permission => 'become_user', :enabled => false, :role => admin_role)
        end
        expect(RoleOverride.permission_for(@account, :become_user, admin_role)[:enabled]).to eq false
      end

      it "should find site-admin role overrides on a non-current shard" do
        role = custom_account_role("custom", :account => Account.site_admin)
        Account.site_admin.role_overrides.create!(:permission => 'become_user', :enabled => true, :role => role)
        @shard1.activate do
          @account = Account.create!
        end
        expect(RoleOverride.permission_for(@account, :become_user, role)[:enabled]).to eq [:self, :descendants]
      end
    end
  end

  describe "enabled_for?" do
    it "should honor applies_to_self" do
      role = Account.site_admin.roles.build(:name => 'role')
      role.base_role_type = 'AccountMembership'
      role.save!
      ro = RoleOverride.new(:context => Account.site_admin, :permission => 'manage_role_overrides',
                            :role => role, :enabled => true)
      ro.applies_to_self = false
      ro.save!
      # for the UI - should be enabled
      expect(RoleOverride.permission_for(Account.site_admin, :manage_role_overrides, role)[:enabled]).to eq [:descendants]
      # applying to Site Admin, should be disabled
      expect(RoleOverride.enabled_for?(Account.site_admin, :manage_role_overrides, role)).to eq [:descendants]
      # applying to Default Account, should be enabled
      expect(RoleOverride.enabled_for?(Account.default, :manage_role_overrides, role)).to eq [:self, :descendants]
    end

    it "should honor applies_to_descendants" do
      role = Account.site_admin.roles.build(:name => 'role')
      role.base_role_type = 'AccountMembership'
      role.save!
      ro = RoleOverride.new(:context => Account.site_admin, :permission => 'manage_role_overrides',
                            :role => role, :enabled => true)
      ro.applies_to_descendants = false
      ro.save!
      # for the UI - should be enabled
      expect(RoleOverride.permission_for(Account.site_admin, :manage_role_overrides, role)[:enabled]).to eq [:self]
      # applying to Site Admin, should be enabled
      expect(RoleOverride.enabled_for?(Account.site_admin, :manage_role_overrides, role)).to eq [:self]
      # applying to Default Account, should be disabled
      expect(RoleOverride.enabled_for?(Account.default, :manage_role_overrides, role)).to eq []
    end

    context "with account allows" do
      before :once do
        @role = Account.default.roles.build(:name => 'role')
        @role.base_role_type = 'AccountMembership'
        @role.save!
        RoleOverride.create!(:context => Account.default, :permission => 'manage_user_notes', :role => @role, :enabled => true)
      end

      it "should ignore permissions with account_allows off" do
        expect(RoleOverride.enabled_for?(Account.default, :manage_user_notes, admin_role)).to eq []
        expect(RoleOverride.enabled_for?(Account.default, :manage_user_notes, @role)).to eq []
      end

      it "should allow with account_allows on" do
        Account.default.tap{|a| a.enable_user_notes = true; a.save!}
        expect(RoleOverride.enabled_for?(Account.default, :manage_user_notes, admin_role)).to_not eq []
        expect(RoleOverride.enabled_for?(Account.default, :manage_user_notes, @role)).to_not eq []
      end
    end
  end

  context "enabled_for_plugin" do
    before(:once) do
      account_model
    end

    it "should not show a permission if the specified plugin does not exist" do
      expect(RoleOverride.manageable_permissions(@account).keys).not_to include(:manage_frozen_assignments)
    end

    it "should not show a permission if the specified plugin is not enabled" do
      p = Canvas::Plugin.register(:assignment_freezer, :assignment_freezer, {
        :settings => {:foo => true}})
      s = PluginSetting.new(:name => p.id, :settings => p.default_settings)
      s.disabled = true
      s.save!
      expect(RoleOverride.manageable_permissions(@account).keys).not_to include(:manage_frozen_assignments)
    end

    it "should include show a permission if the specified plugin is enabled" do
      p = Canvas::Plugin.register(:assignment_freezer, :assignment_freezer, {
        :settings => {:foo => true}})
      s = PluginSetting.new(:name => p.id, :settings => p.default_settings)
      s.disabled = false
      s.save!
      expect(RoleOverride.manageable_permissions(@account).keys).to include(:manage_frozen_assignments)
    end
  end

  describe 'specific permissions' do
    before(:once) do
      account_model
    end

    describe 'select_final_grade' do
      let(:permission) { RoleOverride.permissions[:select_final_grade] }

      it 'is enabled by default for account admins, teachers, and TAs' do
        expect(permission[:true_for]).to match_array %w(AccountAdmin TeacherEnrollment TaEnrollment)
      end

      it 'is available to account admins, account memberships, teachers, and TAs' do
        expect(permission[:available_to]).to match_array %w(AccountAdmin AccountMembership TeacherEnrollment TaEnrollment)
      end
    end

    describe 'view_audit_trail' do
      let(:permission) { RoleOverride.permissions[:view_audit_trail] }

      it 'is enabled by default for teachers, TAs and admins' do
        expect(permission[:true_for]).to match_array %w(AccountAdmin)
      end

      it 'is available to teachers, TAs, admins and account memberships' do
        expect(permission[:available_to]).to match_array %w(TeacherEnrollment AccountAdmin AccountMembership)
      end
    end
  end

end
