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
require 'db/migrate/20121129175438_move_account_membership_types'

describe 'MoveAccountMembershipTypes' do
  before(:each) do
    @account1 = Account.new
    @account1.membership_types = "AccountAdmin,role1,role2"
    @account1.save

    @account2 = Account.new
    @account2.membership_types = "AccountAdmin,role2,role3"
    @account2.save
  end

  it "should add active roles for each membership type" do
    MoveAccountMembershipTypes.up

    @account1.roles.count.should == 2
    role_names = ['role1', 'role2']
    @account1.roles.collect(&:name).sort.should == role_names
    role_names.each do |r|
      @account1.roles.find_by_name(r).workflow_state.should == 'active'
    end

    @account2.roles.count.should == 2
    role_names = ['role2', 'role3']
    @account2.roles.collect(&:name).sort.should == role_names
    role_names.each do |r|
      @account2.roles.find_by_name(r).workflow_state.should == 'active'
    end
  end

  it "should not add active roles if roles with same name already exist" do
    role1 = @account1.roles.build(:name => 'role1')
    role1.base_role_type = 'TeacherEnrollment'
    role1.save!

    role2 = @account2.roles.build(:name => 'role2')
    role2.base_role_type = 'StudentEnrollment'
    role2.save!

    role2 = @account2.roles.build(:name => 'role3')
    role2.base_role_type = 'ObserverEnrollment'
    role2.save!

    MoveAccountMembershipTypes.up

    @account1.roles.count.should == 2
    @account1.roles.find_by_name('role1').base_role_type.should == 'TeacherEnrollment'
    @account1.roles.find_by_name('role2').base_role_type.should == 'AccountMembership'

    @account2.roles.count.should == 2
    @account2.roles.find_by_name('role2').base_role_type.should == 'StudentEnrollment'
    @account2.roles.find_by_name('role3').base_role_type.should == 'ObserverEnrollment'
  end

  context "when adding inactive roles for role overrides" do
    before :each do
      RoleOverride.create!(:context => @account1, :permission => 'moderate_forum', :enrollment_type => "TeacherEnrollment")
      RoleOverride.create!(:context => @account1, :permission => 'moderate_forum', :enrollment_type => "customrole1")
      RoleOverride.create!(:context => @account1, :permission => 'moderate_forum', :enrollment_type => "customrole2")

      RoleOverride.create!(:context => @account2, :permission => 'moderate_forum', :enrollment_type => "customrole2")
      RoleOverride.create!(:context => @account2, :permission => 'moderate_forum', :enrollment_type => "role2")
      RoleOverride.create!(:context => @account2, :permission => 'moderate_forum', :enrollment_type => "role3")

      role2 = @account2.roles.build(:name => 'role3')
      role2.base_role_type = 'ObserverEnrollment'
      role2.save!

      MoveAccountMembershipTypes.up
    end

    it "should add inactive roles if there is a role-override referencing a missing type" do
      @account1.roles.count.should == 4
      @account1.roles.collect(&:name).sort.should == ['customrole1', 'customrole2', 'role1', 'role2']
      @account1.roles.find_by_name('customrole1').base_role_type.should == 'AccountMembership'
      @account1.roles.find_by_name('customrole1').workflow_state.should == 'inactive'
      @account1.roles.find_by_name('customrole2').base_role_type.should == 'AccountMembership'
      @account1.roles.find_by_name('customrole2').workflow_state.should == 'inactive'

      @account2.roles.count.should == 3
      @account2.roles.collect(&:name).sort.should == ['customrole2', 'role2', 'role3']
      @account2.roles.find_by_name('customrole2').base_role_type.should == 'AccountMembership'
      @account2.roles.find_by_name('customrole2').workflow_state.should == 'inactive'
    end

    it "should not overwrite the active roles added" do
      @account2.roles.find_by_name('role2').workflow_state.should == 'active'
    end

    it "should not overwrite an already existing role" do
      @account2.roles.find_by_name('role3').base_role_type.should == 'ObserverEnrollment'
    end
  end

  it "should add inactive roles for non-existent account user membership types" do
    @account1.account_users.create!(user: user, membership_type: 'role1')
    @account1.account_users.create!(user: user, membership_type: 'NonexistentType')
    @account2.account_users.create!(user: user, membership_type: 'AnotherNonexistentType')
    @account2.account_users.create!(user: user, membership_type: 'YetAnotherNonexistentType')

    MoveAccountMembershipTypes.up

    @account1.roles.count.should == 3
    @account1.roles.collect(&:name).sort.should == ['NonexistentType', 'role1', 'role2']
    @account1.roles.find_by_name('NonexistentType').base_role_type.should == 'AccountMembership'
    @account1.roles.find_by_name('NonexistentType').workflow_state.should == 'inactive'

    @account2.roles.count.should == 4
    @account2.roles.collect(&:name).sort.should == ['AnotherNonexistentType', 'YetAnotherNonexistentType', 'role2', 'role3', ]
    ['AnotherNonexistentType', 'YetAnotherNonexistentType'].each do |t|
      @account2.roles.find_by_name(t).base_role_type.should == 'AccountMembership'
      @account2.roles.find_by_name(t).workflow_state.should == 'inactive'
    end
  end

  it "should not add inactive roles for non-existent account user membership types if the role already exists" do
    @account1.account_users.create!(user: user, membership_type: 'NonexistentType')

    role1 = @account1.roles.build(:name => 'NonexistentType')
    role1.base_role_type = 'TeacherEnrollment'
    role1.save!

    MoveAccountMembershipTypes.up

    @account1.roles.count.should == 3
    @account1.roles.collect(&:name).sort.should == ['NonexistentType', 'role1', 'role2']
    @account1.roles.find_by_name('NonexistentType').base_role_type.should == 'TeacherEnrollment'
    @account1.roles.find_by_name('NonexistentType').workflow_state.should == 'active'
  end

  it "should not fail when encountering a user with a reserved membership type" do
    @account1.account_users.create!(user: user)

    MoveAccountMembershipTypes.up
  end
end
