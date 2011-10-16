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
end
