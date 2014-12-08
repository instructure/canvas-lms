#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Role do
  context "without account" do
    it "should require an account" do
      role = Role.create :name => "1337 Student"
      role.base_role_type = 'StudentEnrollment'
      expect(role).not_to be_valid
    end
  end

  context "with account" do
    before :once do
      account_model
    end

    it "should accept a valid Role" do
      role = @account.roles.create :name => "1337 Student"
      role.base_role_type = 'StudentEnrollment'
      expect(role).to be_valid
    end

    it "should require a name" do
      role = @account.roles.build
      role.base_role_type = 'StudentEnrollment'
      expect(role).not_to be_valid
    end

    it "should require a base role type" do
      role = @account.roles.build :name => 'CustomRole'
      expect(role).not_to be_valid
    end

    it "should enforce known base role types" do
      role = @account.roles.create :name => 'CustomRole'

      role.base_role_type = 'TeacherEnrollment'
      expect(role).to be_valid

      role.base_role_type = 'TaEnrollment'
      expect(role).to be_valid

      role.base_role_type = 'DesignerEnrollment'
      expect(role).to be_valid

      role.base_role_type = 'ObserverEnrollment'
      expect(role).to be_valid

      role.base_role_type = 'RidiculousEnrollment'
      expect(role).not_to be_valid
    end

    it "should disallow names that match base role types" do
      role = @account.roles.create
      role.base_role_type = 'StudentEnrollment'

      role.name = 'StudentEnrollment'
      expect(role).not_to be_valid

      role.name = 'TeacherEnrollment'
      expect(role).not_to be_valid

      role.name = 'TaEnrollment'
      expect(role).not_to be_valid

      role.name = 'DesignerEnrollment'
      expect(role).not_to be_valid

      role.name = 'ObserverEnrollment'
      expect(role).not_to be_valid

      role.name = 'RidiculousEnrollment'
      expect(role).to be_valid
    end

    it "should disallow names that match base sis enrollment role names" do
      role = @account.roles.create
      role.base_role_type = 'StudentEnrollment'

      role.name = 'student'
      expect(role).not_to be_valid

      role.name = 'teacher'
      expect(role).not_to be_valid

      role.name = 'ta'
      expect(role).not_to be_valid

      role.name = 'designer'
      expect(role).not_to be_valid

      role.name = 'observer'
      expect(role).not_to be_valid

      role.name = 'cheater'
      expect(role).to be_valid
    end

    it "should infer the root account id" do
      role = custom_student_role("1337 Student")
      expect(role.root_account_id).to eq @account.id
    end
  end

  context "with multiple accounts" do
    before :once do
      @root_account_1 = account_model
      @sub_account_1a = @root_account_1.sub_accounts.create!
      @sub_account_1b = @root_account_1.sub_accounts.create!
      @root_account_2 = account_model
      @sub_account_2 = @root_account_2.sub_accounts.create!

      @role = custom_student_role('TestRole', :account => @sub_account_1a)
    end

    it "should infer the root account name" do
      expect(@role.root_account_id).to eq @root_account_1.id
    end

    it "should allow a role name to be reused with the same base role type within a root account" do
      new_role = @sub_account_1b.roles.create :name => 'TestRole'
      new_role.base_role_type = 'StudentEnrollment'
      expect(new_role).to be_valid
    end
  end

  context "with active role" do
    before :once do
      account_model
      @role = custom_student_role("1337 Student")
      @role.reload
    end

    it "should not allow a duplicate active role to be created in the same account" do
      dup_role = @account.roles.new :name => "1337 Student"
      dup_role.base_role_type = 'StudentEnrollment'
      expect(dup_role).to be_invalid
      @role.destroy
      expect(dup_role).to be_valid
    end

    describe "workflow" do
      it "should default to active state" do
        expect(@role).to be_active
      end

      it "should be set to deleted by destroy" do
        @role.destroy
        expect(@role.reload).to be_deleted
      end
    end

    describe "deleted_at" do
      it "should default to nil" do
        expect(@role.deleted_at).to be_nil
      end

      it "should be set upon destroy" do
        @role.destroy
        expect(@role.reload.deleted_at).to be > 1.minute.ago
      end
    end

    describe "active scope" do
      before do
        @deleted_role = custom_ta_role("Stupid Role")
        @deleted_role.destroy
      end

      it "should include only active Roles" do
        expect(@account.roles.sort_by(&:id)).to eq [@role, @deleted_role]
        expect(@account.roles.active).to eq [@role]
      end
    end
  end

  context "custom role helpers" do
    before :once do
      account_model
      @sub_account = @account.sub_accounts.create!
      @base_types = RoleOverride::ENROLLMENT_TYPES.map{|et|et[:base_role_name]}
      @custom_roles = {}
      @base_types.each do |bt|
        if bt == 'DesignerEnrollment'
          @custom_roles[bt] = custom_role(bt, "custom #{bt}", :account => @sub_account)
        else
          @custom_roles[bt] = custom_role(bt, "custom #{bt}")
        end
      end
    end

    def get_base_type(hash, name)
      hash.find{|br|br[:base_role_name] == name}
    end

    it "should find all custom roles" do
      all = Role.all_enrollment_roles_for_account(@sub_account)
      @base_types.each do |bt|
        expect(get_base_type(all, bt)[:custom_roles][0][:name]).to eq "custom #{bt}"
      end

      expect { Role.all_enrollment_roles_for_account(@sub_account) }.to_not raise_error
    end

    it "should get counts for all roles" do
      course(:account => @sub_account)

      @base_types.each do |bt|
        @course.enroll_user(user, bt)
        @course.enroll_user(user, bt, :role => @custom_roles[bt])
      end

      all = Role.custom_roles_and_counts_for_course(@course, @course.teachers.first)

      @base_types.each do |bt|
        hash = get_base_type(all, bt)
        expect(hash[:count]).to eq 1
        expect(hash[:custom_roles][0][:count]).to eq 1
      end
    end

    describe "Role.role_data" do
      it "returns the roles with custom roles flattened as siblings to the main roles" do
        course(:account => @sub_account)

        @base_types.each do |bt|
          @course.enroll_user(user, bt)
          @course.enroll_user(user, bt, :role => @custom_roles[bt])
        end

        roles = Role.role_data(@course, @course.teachers.first)
        expect(roles.length).to eq 10
      end
    end

    it "should include inactive roles" do
      @account.roles.each{|r| r.deactivate! }
      all = Role.all_enrollment_roles_for_account(@sub_account, true)
      @base_types.each do |bt|
        expect(get_base_type(all, bt)[:custom_roles][0][:name]).to eq "custom #{bt}"
      end
    end
  end

  describe "cross-shard built-in role translation" do
    specs_require_sharding
    it "should return the id of the built in role on the current shard" do
      built_in_role = Role.get_built_in_role("AccountAdmin")
      @shard1.activate do
        expect(built_in_role.id).to eq Role.get_built_in_role("AccountAdmin", @shard1).id
        account = Account.create
        # should not get foreign key error
        account.role_overrides.create!(role: built_in_role, enabled: false, permission: :manage_admin_users)
      end
    end
  end
end
