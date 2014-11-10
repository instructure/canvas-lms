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
      expect(@account.available_account_roles).not_to include('NewRole')
      post 'add_role', :account_id => @account.id, :role_type => 'NewRole'
      @account.reload
      expect(@account.available_account_roles).to include('NewRole')
    end

    it "requires a role type" do
      post 'add_role', :account_id => @account.id
      expect(flash[:error]).to eq 'Role creation failed'
    end

    it "fails when given an existing role type" do
      role = @account.roles.build(:name => 'NewRole')
      role.base_role_type = AccountUser::BASE_ROLE_NAME
      role.workflow_state = 'active'
      role.save!
      post 'add_role', :account_id => @account.id, :role_type => 'NewRole'
      expect(flash[:error]).to eq 'Role creation failed'
    end
  end

  it "should deactivate a role" do
    role = @account.roles.build(:name => 'NewRole')
    role.base_role_type = AccountUser::BASE_ROLE_NAME
    role.workflow_state = 'active'
    role.save!
    delete 'remove_role', :account_id => @account.id, :role => 'NewRole'
    expect(@account.roles.where(name: 'NewRole').first).to be_inactive
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
        expect(@account.role_overrides(true).size).to eq @initial_count
        @existing_override.reload
        expect(@existing_override.enabled).to be_falsey
      end

      it "should update an existing override if override is nil but locked is truthy" do
        post_with_settings(:locked => 'true')
        expect(@account.role_overrides(true).size).to eq @initial_count
        @existing_override.reload
        expect(@existing_override.locked).to be_truthy
      end

      it "only updates unchecked" do
        post_with_settings(:override => 'unchecked')
        @existing_override.reload
        expect(@existing_override.locked).to be_falsey
      end
      
      it "only updates enabled" do 
        @existing_override.enabled = true
        @existing_override.save

        post_with_settings(:locked => 'true')
        @existing_override.reload
        expect(@existing_override.enabled).to be_truthy
      end

      it "should delete an existing override if override is nil and locked is not truthy" do
        post_with_settings(:locked => '0')
        expect(@account.role_overrides(true).size).to eq @initial_count - 1
        expect(RoleOverride.where(id: @existing_override).first).to be_nil
      end
    end

    describe "no override yet" do
      before :each do
        @initial_count = @account.role_overrides.size
      end

      it "should not create an override if override is nil and locked is not truthy" do
        post_with_settings(:locked => '0')
        expect(@account.role_overrides(true).size).to eq @initial_count
      end

      it "should create the override if override has a value" do
        post_with_settings(:override => 'unchecked')
        expect(@account.role_overrides(true).size).to eq @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
        expect(override).not_to be_nil
        expect(override.enabled).to be_falsey
      end

      it "should create the override if override is nil but locked is truthy" do
        post_with_settings(:locked => 'true')
        expect(@account.role_overrides(true).size).to eq @initial_count + 1
        override = @account.role_overrides.where(permission: @permission, enrollment_type: @role).first
        expect(override).not_to be_nil
        expect(override.locked).to be_truthy
      end

      it "sets override as false when override is unchecked" do 
        post_with_settings(:override => 'unchecked')
        override = @account.role_overrides(true).where(permission: @permission, enrollment_type: @role).first
        expect(override).not_to be_nil
        expect(override.enabled).to be_falsey
        expect(override.locked).to be_nil
        override.destroy
      end

      it "sets the override to locked when specifiying locked" do
        post_with_settings(:locked => 'true')
        override = @account.role_overrides(true).where(permission: @permission, enrollment_type: @role).first
        expect(override).not_to be_nil
        expect(override.enabled).to be_nil
        expect(override.locked).to be_truthy
      end
    end
  end
end
