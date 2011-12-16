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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe RoleOverride do
  it "should retain the prior permission when it encounters the first explicit override" do
    @account = account_model(:parent_account => Account.default)
    RoleOverride.create!(:context => @account, :permission => 'moderate_forum',
                         :enrollment_type => "TeacherEnrollment", :enabled => false)
    permissions = RoleOverride.permission_for(Account.default, :moderate_forum, "TeacherEnrollment")
    permissions[:enabled].should == true
    permissions.key?(:prior_default).should == false
    permissions[:explicit].should == false

    permissions = RoleOverride.permission_for(@account, :moderate_forum, "TeacherEnrollment")
    permissions[:enabled].should == false
    permissions[:prior_default].should == true
    permissions[:explicit].should == true
  end

  it "should use the immediately parent context as the prior permission when there are multiple explicit levels" do
    a1 = account_model
    a2 = account_model(:parent_account => a1)
    a3 = account_model(:parent_account => a2)

    RoleOverride.create!(:context => a1, :permission => 'moderate_forum',
                         :enrollment_type => "TeacherEnrollment", :enabled => false)
    RoleOverride.create!(:context => a2, :permission => 'moderate_forum',
                         :enrollment_type => "TeacherEnrollment", :enabled => true)

    permissions = RoleOverride.permission_for(a1, :moderate_forum, "TeacherEnrollment")
    permissions[:enabled].should == false
    permissions[:prior_default].should == true
    permissions[:explicit].should == true

    permissions = RoleOverride.permission_for(a2, :moderate_forum, "TeacherEnrollment")
    permissions[:enabled].should == true
    permissions[:prior_default].should == false
    permissions[:explicit].should == true

    permissions = RoleOverride.permission_for(a3, :moderate_forum, "TeacherEnrollment")
    permissions[:enabled].should == true
    permissions[:prior_default].should == true
    permissions[:explicit].should == true
  end

  it "should not fail when a context's associated accounts are missing" do
    group_model
    @group.account.should be_nil
    lambda {
      RoleOverride.permission_for(@group, :read_course_content, "TeacherEnrollment")
    }.should_not raise_error
  end

  describe "manage_role_override" do
    before :each do
      @account = account_model(:parent_account => Account.default)
      @role = 'NewRole'
      @permission = 'read_reports'
    end

    describe "override already exists" do
      before :each do
        @existing_override = @account.role_overrides.build(
          :permission => @permission,
          :enrollment_type => @role)
        @existing_override.enabled = true
        @existing_override.locked = false
        @existing_override.save!
        @initial_count = @account.role_overrides.size
      end

      it "should update an existing override if override has a value" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        @account.role_overrides.size.should == @initial_count
        new_override.should == @existing_override.reload
        @existing_override.enabled.should be_false
      end

      it "should update an existing override if override is nil but locked is truthy" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        @account.role_overrides.size.should == @initial_count
        new_override.should == @existing_override.reload
        @existing_override.locked.should be_true
      end

      it "should only update the parts that are specified" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        @existing_override.reload
        @existing_override.locked.should be_false

        @existing_override.enabled = true
        @existing_override.save

        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        @existing_override.reload
        @existing_override.enabled.should be_true
      end

      it "should delete an existing override if override is nil and locked is not truthy" do
        new_override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => false)
        @account.role_overrides.size.should == @initial_count - 1
        new_override.should be_nil
        RoleOverride.find_by_id(@existing_override.id).should be_nil
      end
    end

    describe "no override yet" do
      before :each do
        @initial_count = @account.role_overrides.size
      end

      it "should not create an override if override is nil and locked is not truthy" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => false)
        override.should be_nil
        @account.role_overrides.size.should == @initial_count
      end

      it "should create the override if override has a value" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        @account.role_overrides.size.should == @initial_count + 1
        override.enabled.should be_false
      end

      it "should create the override if override is nil but locked is truthy" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        @account.role_overrides.size.should == @initial_count + 1
        override.locked.should be_true
      end

      it "should only set the parts that are specified" do
        override = RoleOverride.manage_role_override(@account, @role, @permission, :override => false)
        override.enabled.should be_false
        override.locked.should be_nil
        override.destroy

        override = RoleOverride.manage_role_override(@account, @role, @permission, :locked => true)
        override.enabled.should be_nil
        override.locked.should be_true
      end
    end
  end
end
