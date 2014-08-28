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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "/users/admin_merge" do
  it "should only list accounts that the user can merge users in" do
    user
    @account = Account.create!(:name => "My Root Account")
    @account2 = @account.sub_accounts.create!(:name => "Sub-Account")
    @account.account_users.create!(user: @user)
    @course1 = Course.create!(:account => Account.default)
    @course2 = Course.create!(:account => @account2)
    @course1.enroll_teacher(@user)
    @course2.enroll_teacher(@user)

    @user.associated_accounts.map(&:id).sort.should == [@account.id, @account2.id, Account.default.id].sort

    assigns[:current_user] = @user
    user
    assigns[:user] = @user

    render "users/admin_merge"
    response.should_not be_nil
    response.body.should match /My Root Account/
    response.body.should match /Sub-Account/
    response.body.should_not match /Default Account/
  end
end
