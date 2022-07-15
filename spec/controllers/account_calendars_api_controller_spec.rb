# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe AccountCalendarsApiController do
  before :once do
    Account.site_admin.enable_feature! :account_calendar_events
    @root_account = Account.default
    @subaccount1 = @root_account.sub_accounts.create!
    @subaccount2 = @root_account.sub_accounts.create!
    @subaccount1a = @subaccount1.sub_accounts.create!(name: "Subaccount 1a")
    [@root_account, @subaccount1, @subaccount2, @subaccount1a].each do |a|
      a.account_calendar_visible = true
      a.save!
    end
    @user = user_factory(active_all: true)
  end

  describe "GET 'index'" do
    it "returns only calendars where the user has an association" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@root_account.id, @subaccount1.id, @subaccount1a.id)
    end

    it "returns only visible calendars" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      course_with_student_logged_in(user: @user, account: @subaccount2)
      @subaccount1a.account_calendar_visible = false
      @subaccount1a.save!
      @subaccount1.account_calendar_visible = false
      @subaccount1.save!
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@root_account.id, @subaccount2.id)
    end

    it "returns an empty array for a user without any enrollments" do
      user_session(@user)
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json).to eq []
    end

    it "requires the user to be logged in" do
      get :index

      expect(response).to be_redirect
    end

    it "returns not found if the flag is disabled" do
      Account.site_admin.disable_feature! :account_calendar_events
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      get :index

      expect(response).to be_not_found
    end
  end

  describe "GET 'show'" do
    it "returns the calendar with id, name, parent_account_id, root_account_id, and visible attributes" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      user_session(@user)
      get :show, params: { account_id: @subaccount1a.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["id"]).to be @subaccount1a.id
      expect(json["name"]).to eq "Subaccount 1a"
      expect(json["parent_account_id"]).to be @subaccount1.id
      expect(json["root_account_id"]).to be @root_account.id
      expect(json["visible"]).to be_truthy
    end

    it "returns a hidden calendar for an admin with :manage_account_calendar_visibility" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      @subaccount2.account_calendar_visible = false
      @subaccount2.save!
      user_session(@user)
      get :show, params: { account_id: @subaccount2.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["id"]).to be @subaccount2.id
      expect(json["visible"]).to be_falsey
    end

    it "returns unauthorized for a student if the requested calendar is hidden" do
      course_with_student_logged_in(user: @user, account: @root_account)
      @root_account.account_calendar_visible = false
      @root_account.save!
      user_session(@user)
      get :show, params: { account_id: @root_account.id }

      expect(response).to be_unauthorized
    end

    it "returns not found for a fake account id" do
      user_session(@user)
      get :show, params: { account_id: (Account.maximum(:id) || 0) + 1 }

      expect(response).to be_not_found
    end

    it "requires the user to be logged in" do
      get :show, params: { account_id: @root_account.id }

      expect(response).to be_redirect
    end
  end

  describe "PUT 'update'" do
    it "updates calendar visibility and returns calendar json" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      expect(@root_account.account_calendar_visible).to be_truthy

      put :update, params: { account_id: @root_account, visible: false }
      expect(response).to be_successful
      json = json_parse(response.body)
      @root_account.reload
      expect(@root_account.account_calendar_visible).to be_falsey
      expect(json["id"]).to be @root_account.id
      expect(json["visible"]).to be_falsey

      put :update, params: { account_id: @root_account, visible: "1" }
      expect(response).to be_successful
      json = json_parse(response.body)
      @root_account.reload
      expect(@root_account.account_calendar_visible).to be_truthy
      expect(json["id"]).to be @root_account.id
      expect(json["visible"]).to be_truthy
    end

    it "returns bad request if visible param is not provided" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      put :update, params: { account_id: @root_account }

      expect(response).to be_bad_request
      json = json_parse(response.body)
      expect(json["errors"]).to eq "Missing param: `visible`"
    end

    it "returns not found for a fake account id" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      put :update, params: { account_id: (Account.maximum(:id) || 0) + 1, visible: false }

      expect(response).to be_not_found
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility" do
      account_admin_user_with_role_changes(active_all: true, account: @root_account, user: @user,
                                           role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      put :update, params: { account_id: @root_account.id, visible: false }

      expect(response).to be_unauthorized
    end
  end

  describe "GET 'all_calendars'" do
    it "returns provided account calendar and all children account calendars" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @root_account.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@root_account.id, @subaccount1.id, @subaccount2.id, @subaccount1a.id)
    end

    it "returns hidden calendars" do
      account_admin_user(active_all: true, account: @subaccount1, user: @user)
      @subaccount1.account_calendar_visible = false
      @subaccount1.save!
      user_session(@user)
      get :all_calendars, params: { account_id: @subaccount1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@subaccount1.id, @subaccount1a.id)
    end

    it "returns only one account if provided account doesn't have subaccounts" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @subaccount2.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@subaccount2.id)
    end

    it "returns not found for a fake account id" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: (Account.maximum(:id) || 0) + 1 }

      expect(response).to be_not_found
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility" do
      account_admin_user_with_role_changes(active_all: true, account: @root_account, user: @user,
                                           role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      get :all_calendars, params: { account_id: @root_account.id }

      expect(response).to be_unauthorized
    end

    it "returns unauthorized for a subaccount admin requesting a parent account's calendars" do
      account_admin_user(active_all: true, account: @subaccount1a, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @subaccount1.id }

      expect(response).to be_unauthorized
    end

    it "limits admin's permissions to accounts with :manage_account_calendar_visibility" do
      limited_admin_role = custom_account_role("no calendar permissions", account: @root_account)
      account_admin_user_with_role_changes(active_all: true,
                                           account: @root_account,
                                           user: @user,
                                           role: limited_admin_role,
                                           role_changes: { manage_account_calendar_visibility: false })
      account_admin_user(active_all: true, account: @subaccount2, user: @user)
      user_session(@user)

      get :all_calendars, params: { account_id: @root_account.id }
      expect(response).to be_unauthorized

      get :all_calendars, params: { account_id: @subaccount2.id }
      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.map { |calendar| calendar["id"] }).to contain_exactly(@subaccount2.id)
    end
  end
end
