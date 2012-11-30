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
      role.should_not be_valid
    end
  end

  context "with account" do
    before do
      account_model
    end

    it "should accept a valid Role" do
      role = @account.roles.create :name => "1337 Student"
      role.base_role_type = 'StudentEnrollment'
      role.should be_valid
    end

    it "should require a name" do
      role = @account.roles.build
      role.base_role_type = 'StudentEnrollment'
      role.should_not be_valid
    end

    it "should require a base role type" do
      role = @account.roles.build :name => 'CustomRole'
      role.should_not be_valid
    end

    it "should enforce known base role types" do
      role = @account.roles.create :name => 'CustomRole'

      role.base_role_type = 'TeacherEnrollment'
      role.should be_valid

      role.base_role_type = 'TaEnrollment'
      role.should be_valid

      role.base_role_type = 'DesignerEnrollment'
      role.should be_valid

      role.base_role_type = 'ObserverEnrollment'
      role.should be_valid

      role.base_role_type = 'RidiculousEnrollment'
      role.should_not be_valid
    end

    it "should disallow names that match base role types" do
      role = @account.roles.create
      role.base_role_type = 'StudentEnrollment'

      role.name = 'StudentEnrollment'
      role.should_not be_valid

      role.name = 'TeacherEnrollment'
      role.should_not be_valid

      role.name = 'TaEnrollment'
      role.should_not be_valid

      role.name = 'DesignerEnrollment'
      role.should_not be_valid

      role.name = 'ObserverEnrollment'
      role.should_not be_valid

      role.name = 'RidiculousEnrollment'
      role.should be_valid
    end

    it "should infer the root account id" do
      role = @account.roles.create :name => "1337 Student"
      role.base_role_type = 'StudentEnrollment'
      role.save!
      role.root_account_id.should == @account.id
    end
  end

  context "with multiple accounts" do
    before do
      @root_account_1 = account_model
      @sub_account_1a = @root_account_1.sub_accounts.create!
      @sub_account_1b = @root_account_1.sub_accounts.create!
      @root_account_2 = account_model
      @sub_account_2 = @root_account_2.sub_accounts.create!

      @role = @sub_account_1a.roles.create :name => 'TestRole'
      @role.base_role_type = 'StudentEnrollment'
      @role.save!
    end

    it "should infer the root account name" do
      @role.root_account_id.should == @root_account_1.id
    end

    it "should allow a role name to be reused with the same base role type within a root account" do
      new_role = @sub_account_1b.roles.create :name => 'TestRole'
      new_role.base_role_type = 'StudentEnrollment'
      new_role.should be_valid
    end

    it "should not allow a role name to be reused with a different base role type within a root account" do
      new_role = @sub_account_1b.roles.create :name => 'TestRole'
      new_role.base_role_type = 'TaEnrollment'
      new_role.should_not be_valid
    end

    it "should allow a role name to be reused with a different base role type in a separate root account" do
      new_role = @sub_account_2.roles.create :name => 'TestRole'
      new_role.base_role_type = 'TaEnrollment'
      new_role.should be_valid
    end
  end

  context "with active role" do
    before do
      account_model
      @role = @account.roles.create :name => "1337 Student"
      @role.base_role_type = 'StudentEnrollment'
      @role.save!
      @role.reload
    end

    it "should not allow a duplicate role to be created in the same account" do
      dup_role = @account.roles.create :name => "1337 Student"
      dup_role.base_role_type = 'StudentEnrollment'
      dup_role.should be_invalid
    end

    describe "workflow" do
      it "should default to active state" do
        @role.should be_active
      end

      it "should be set to deleted by destroy" do
        @role.destroy
        @role.reload.should be_deleted
      end
    end

    describe "deleted_at" do
      it "should default to nil" do
        @role.deleted_at.should be_nil
      end

      it "should be set upon destroy" do
        @role.destroy
        @role.reload.deleted_at.should > 1.minute.ago
      end
    end

    describe "active scope" do
      before do
        @deleted_role = @account.roles.create :name => 'Stupid Role'
        @deleted_role.base_role_type = 'TaEnrollment'
        @deleted_role.save!
        @deleted_role.destroy
      end

      it "should include only active Roles" do
        @account.roles.sort_by(&:id).should == [@role, @deleted_role]
        @account.roles.active.should == [@role]
      end
    end
  end
end
