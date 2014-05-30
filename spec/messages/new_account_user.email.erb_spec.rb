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
require File.expand_path(File.dirname(__FILE__) + '/messages_helper')

describe 'new_account_user.email' do
  before do
    @account = Account.create!(:name => "some account", :settings => {:outgoing_email_default_name => "Custom From"})
    user_model
    account_user = @account.account_users.create!(user: @user)
    account_user.account.should eql(@account)
    account_user.user.should eql(@user)
    @object = account_user
  end

  it "should render" do
    generate_message(:new_account_user, :email, @object)
  end

  it "should use the custom From: setting" do
    msg = generate_message(:new_account_user, :email, @object)
    msg.save
    msg.from_name.should == "Custom From"
  end
end
