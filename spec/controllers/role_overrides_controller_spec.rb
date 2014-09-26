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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RoleOverridesController do
  before :each do
    @account = account_model(:parent_account => Account.default)
    account_admin_user(:account => @account)
    user_session(@admin)
  end

  describe "add_role" do
    it "adds the role type to the account" do
      @account.available_account_roles.should_not include('NewRole')
      post 'add_role', :account_id => @account.id, :role_type => 'NewRole'
      @account.reload
      @account.available_account_roles.should include('NewRole')
    end

    it "requires a role type" do
      post 'add_role', :account_id => @account.id
      flash[:error].should == 'Role creation failed'
    end

    it "fails when given an existing role type" do
      role = @account.roles.build(:name => 'NewRole')
      role.base_role_type = AccountUser::BASE_ROLE_NAME
      role.workflow_state = 'active'
      role.save!
      post 'add_role', :account_id => @account.id, :role_type => 'NewRole'
      flash[:error].should == 'Role creation failed'
    end
  end

  it "should deactivate a role" do
    role = @account.roles.build(:name => 'NewRole')
    role.base_role_type = AccountUser::BASE_ROLE_NAME
    role.workflow_state = 'active'
    role.save!
    delete 'remove_role', :account_id => @account.id, :role => 'NewRole'
    @account.roles.where(name: 'NewRole').first.should be_inactive
  end

  describe "create" do
    before :each do
      @role = 'NewRole'
      @permission = 'read_reports'
      role = @account.roles.build(:name => @role)
      role.base_role_type = AccountUser::BASE_ROLE_NAME
      role.workflow_state = 'active'
      role.save!
    end

    def post_with_settings(settings={})
      post 'create', :account_id => @account.id, :account_roles => 1, :permissions => { @permission => { @role => settings } }
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
        post_with_settings(:override => 'unchecked')
        @account.role_overrides(true).size.should == @initial_count
        @existing_override.reload
        @existing_override.enabled.should be_false
      end

      it "should update an existing override if override is nil but locked is truthy" do
        post_with_settings(:locked => 'true')
        @account.role_overrides(true).size.should == @initial_count
        @existing_override.reload
        @existing_override.locked.should be_true
      end

      it "only updates unchecked" do
        post_with_settings(:override => 'unchecked')
        @existing_override.reload
        @existing_override.locked.should be_false
      end
      
      it "only updates enabled" do 
        @existing_override.enabled = true
        @existing_override.save

        post_with_settings(:locked => 'true')
        @existing_override.reload
        @existing_override.enabled.should be_true
      end

      it "should delete an existing override if override is nil and locked is not truthy" do
        post_with_settings(:locked => '0')
        @account.role_overrides(true).size.should == @initial_count - 1
        RoleOverride.where(id: @existing_override).first.should be_nil
      end
    end

    describe "no override yet" do
      before :each do
        @initial_count = @account.role_overrides.size
      end

      it "should not create an override if override is nil and locked is not truthy" do
        post_with_settings(:locked => '0')
        @account.role_overrides(true).size.should == @initial_count
      end

      it "should create the override if override has a value" do
        post_with_settings(:override => 'unchecked')
        @account.role_overrides(true).size.should == @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
        override.should_not be_nil
        override.enabled.should be_false
      end

      it "should create the override if override is nil but locked is truthy" do
        post_with_settings(:locked => 'true')
        @account.role_overrides(true).size.should == @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
        override.should_not be_nil
        override.locked.should be_true
      end

      it "sets override as false when override is unchecked" do 
        post_with_settings(:override => 'unchecked')
        override = @account.role_overrides(true).where(permission: @permission, enrollment_type: @role).first
        override.should_not be_nil
        override.enabled.should be_false
        override.locked.should be_nil
        override.destroy
      end

      it "sets the override to locked when specifiying locked" do
        post_with_settings(:locked => 'true')
        override = @account.role_overrides(true).where(permission: @permission, enrollment_type: @role).first
        override.should_not be_nil
        override.enabled.should be_nil
        override.locked.should be_true
      end
    end
  end
end
