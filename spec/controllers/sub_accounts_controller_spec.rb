#
# Copyright (C) 2011 - present Instructure, Inc.
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

      post 'create', params: {:account_id => root_account.id, :account => { :parent_account_id => root_account.id, :name => 'sub account' }}
      sub_account = assigns[:sub_account]
      expect(sub_account).not_to be_nil

      post 'create', params: {:account_id => root_account.id, :account => { :parent_account_id => sub_account.id, :name => 'sub sub account 1' }}
      sub_sub_account_1 = assigns[:sub_account]
      expect(sub_sub_account_1).not_to be_nil
      expect(sub_sub_account_1.name).to eq 'sub sub account 1'
      expect(sub_sub_account_1.parent_account).to eq sub_account
      expect(sub_sub_account_1.root_account).to eq root_account
    end

    it "should create sub-accounts with the right root account when inside a sub account" do
      root_account = Account.default
      account_admin_user(:active_all => true)
      user_session(@user)

      sub_account = root_account.sub_accounts.create(:name => 'sub account')

      post 'create', params: {:account_id => sub_account.id, :account => { :parent_account_id => sub_account.id, :name => 'sub sub account 2' }}
      sub_sub_account_2 = assigns[:sub_account]
      expect(sub_sub_account_2).not_to be_nil
      expect(sub_sub_account_2.name).to eq 'sub sub account 2'
      expect(sub_sub_account_2.parent_account).to eq sub_account
      expect(sub_sub_account_2.root_account).to eq root_account
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

      other_account = Account.create!
      other_course = other_account.courses.create!

      section = course.course_sections.create!
      section.crosslist_to_course(other_course)

      get 'index', params: {:account_id => root_account.id}

      @accounts = assigns[:accounts]
      expect(@accounts[root_account.id][:sub_account_count]).to eq 5
      expect(@accounts[root_account.id][:course_count]).to eq 0
      expect(@accounts[root_account.id][:sub_account_ids].sort).to eq [sub_account_1.id, sub_account_2.id, sub_account_3.id, sub_account_4.id, sub_account_5.id].sort

      expect(@accounts[sub_account_1.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_1.id][:course_count]).to eq 0
      expect(@accounts[sub_account_1.id][:sub_account_ids]).to eq []

      expect(@accounts[sub_account_2.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_2.id][:course_count]).to eq 1

      expect(@accounts[sub_account_3.id][:sub_account_count]).to eq 0
      expect(@accounts[sub_account_3.id][:course_count]).to eq 1

      expect(@accounts[sub_account_4.id][:sub_account_count]).to eq 1
      expect(@accounts[sub_account_4.id][:sub_account_ids]).to eq [sub_sub_account.id]
      expect(@accounts[sub_sub_account.id][:sub_account_count]).to eq 1
      expect(@accounts[sub_sub_account.id][:sub_account_ids]).to eq []
      expect(@accounts[sub_sub_sub_account.id]).to be_nil

      expect(@accounts[sub_account_5.id][:sub_account_count]).to eq 150
      expect(@accounts[sub_account_2.id][:sub_account_ids]).to eq []
    end

    it "should include a root account when searching if requested" do
      root_account = Account.create(name: 'account')
      sub_account = root_account.sub_accounts.create!(name: 'sub account')
      account_admin_user(active_all: true, account: root_account)
      user_session(@user)

      get 'index', params: {:account_id => root_account.id, :term => "Acc"}, format: :json
      res = json_parse
      expect(res.count).to eq 1
      expect(res.first["id"]).to eq sub_account.id

      get 'index', params: {:account_id => root_account.id, :term => "Acc", :include_self => "1"}, format: :json
      res = json_parse
      expect(res.count).to eq 2
      expect(res.map{|r| r["id"]}).to match_array [root_account.id, sub_account.id]
    end
  end

  describe "DELETE 'destroy'" do
    before(:once) do
      @root_account = Account.create(name: 'new account')
      account_admin_user(active_all: true, account: @root_account)
      @sub_account = @root_account.sub_accounts.create!
    end

    it "should delete a sub-account" do
      user_session(@user)
      delete 'destroy', params: {:account_id => @root_account, :id => @sub_account}
      expect(response.status).to eq(200)
      expect(@sub_account.reload).to be_deleted
    end

    it "should delete a sub-account that contains a deleted course" do
      @sub_account.courses.create!
      @sub_account.courses.first.destroy
      user_session(@user)
      delete 'destroy', params: {:account_id => @root_account, :id => @sub_account}
      expect(response.status).to eq(200)
      expect(@sub_account.reload).to be_deleted
    end

    it "should not delete a sub-account that contains a course" do
      @sub_account.courses.create!
      user_session(@user)
      delete 'destroy', params: {:account_id => @root_account, :id => @sub_account}
      expect(response.status).to eq(409)
      expect(@sub_account.reload).not_to be_deleted
    end

    it "should not delete a sub-account that contains a sub-account that contains a course" do
      @sub_sub_account = @sub_account.sub_accounts.create!
      @sub_sub_account.courses.create!
      user_session(@user)
      delete 'destroy', params: {:account_id => @root_account, :id => @sub_account}
      expect(response.status).to eq(409)
      expect(@sub_account.reload).not_to be_deleted
    end

    it "should not delete a sub-account that contains a sub-account" do
      @sub_sub_account = @sub_account.sub_accounts.create!
      user_session(@user)
      delete 'destroy', params: {account_id: @root_account, id: @sub_account}
      expect(response.status).to eq(409)
      expect(@sub_account.reload).not_to be_deleted
    end
  end
end
