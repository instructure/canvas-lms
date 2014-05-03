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

  describe "GET 'index'" do
    it "should preload all necessary information" do
      root_account = Account.create(name: 'new account')
      account_admin_user(active_all: true, account: root_account)
      user_session(@user)

      # no sub accounts or courses
      sub_account_1 = root_account.sub_accounts.create!

      # 2 courses, 1 deleted
      sub_account_2 = root_account.sub_accounts.create!
      Course.create!(:account => sub_account_2)
      Course.create!(:account => sub_account_2) { |c| c.workflow_state ='deleted' }

      # 1 course, 2 sections
      sub_account_3 = root_account.sub_accounts.create!
      course = Course.create!(:account => sub_account_3)
      course.course_sections.create!
      course.course_sections.create!

      # deeply nested sub account; sub_sub_account won't be visible
      sub_account_4 = root_account.sub_accounts.create!
      sub_sub_account = sub_account_4.sub_accounts.create!
      sub_sub_sub_account = sub_sub_account.sub_accounts.create!
      # add one more, then delete it; the count should remain the same
      sub_sub_account.sub_accounts.create! { |sa| sa.workflow_state = 'deleted' }

      # 150 sub_accounts; these sub_accounts won't be visible
      sub_account_5 = root_account.sub_accounts.create!
      (1..150).each { sub_account_5.sub_accounts.create! }
      # give one of them a course (which previously triggered a bug)
      Course.create!(:account => sub_account_5.sub_accounts.last)
      # add one more, then delete it; count should remain unchanged
      sub_account_5.sub_accounts.create! { |sa| sa.workflow_state = 'deleted' }

      get 'index', :account_id => root_account.id

      @accounts = assigns[:accounts]
      @accounts[root_account.id][:sub_account_count].should == 5
      @accounts[root_account.id][:course_count].should == 0
      @accounts[root_account.id][:sub_account_ids].sort.should == [sub_account_1.id, sub_account_2.id, sub_account_3.id, sub_account_4.id, sub_account_5.id].sort

      @accounts[sub_account_1.id][:sub_account_count].should == 0
      @accounts[sub_account_1.id][:course_count].should == 0
      @accounts[sub_account_1.id][:sub_account_ids].should == []

      @accounts[sub_account_2.id][:sub_account_count].should == 0
      @accounts[sub_account_2.id][:course_count].should == 1

      @accounts[sub_account_3.id][:sub_account_count].should == 0
      @accounts[sub_account_3.id][:course_count].should == 1

      @accounts[sub_account_4.id][:sub_account_count].should == 1
      @accounts[sub_account_4.id][:sub_account_ids].should == [sub_sub_account.id]
      @accounts[sub_sub_account.id][:sub_account_count].should == 1
      @accounts[sub_sub_account.id][:sub_account_ids].should == []
      @accounts[sub_sub_sub_account.id].should be_nil

      @accounts[sub_account_5.id][:sub_account_count].should == 150
      @accounts[sub_account_2.id][:sub_account_ids].should == []
    end
  end
end
