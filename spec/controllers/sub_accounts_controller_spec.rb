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

describe SubAccountsController do
  describe "POST 'create'" do
    it "should create sub-accounts with the right root account when inside the root account" do
      root_account = Account.default
      account_admin_user(:active_all => true)
      user_session(@user)
      
      post 'create', :account_id => root_account.id, :account => { :parent_account_id => root_account.id, :name => 'sub account' }
      sub_account = assigns[:sub_account]
      sub_account.should_not be_nil
      
      post 'create', :account_id => root_account.id, :account => { :parent_account_id => sub_account.id, :name => 'sub sub account 1' }
      sub_sub_account_1 = assigns[:sub_account]
      sub_sub_account_1.should_not be_nil
      sub_sub_account_1.name.should == 'sub sub account 1'
      sub_sub_account_1.parent_account.should == sub_account
      sub_sub_account_1.root_account.should == root_account
    end
    
    it "should create sub-accounts with the right root account when inside a sub account" do
      root_account = Account.default
      account_admin_user(:active_all => true)
      user_session(@user)
      
      sub_account = root_account.sub_accounts.create(:name => 'sub account')
      
      post 'create', :account_id => sub_account.id, :account => { :parent_account_id => sub_account.id, :name => 'sub sub account 2' }
      sub_sub_account_2 = assigns[:sub_account]
      sub_sub_account_2.should_not be_nil
      sub_sub_account_2.name.should == 'sub sub account 2'
      sub_sub_account_2.parent_account.should == sub_account
      sub_sub_account_2.root_account.should == root_account
    end
  end
end
