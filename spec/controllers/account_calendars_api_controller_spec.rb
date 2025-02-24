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
    @user = user_factory(active_all: true)

    @root_account = Account.default
    @root_account.name = "Root"
    @root_account.account_calendar_visible = true
    @root_account.save!

    @subaccount1 = @root_account.sub_accounts.create!(name: "SA-1", account_calendar_visible: true)
    @subaccount2 = @root_account.sub_accounts.create!(name: "SA-2", account_calendar_visible: true)
    @subaccount1a = @subaccount1.sub_accounts.create!(name: "SA-1a", account_calendar_visible: true)
  end

  describe "GET 'index'" do
    it "returns only calendars where the user has an association" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["account_calendars"].pluck("id")).to contain_exactly(@root_account.id, @subaccount1.id, @subaccount1a.id)
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
      expect(json["account_calendars"].pluck("id")).to contain_exactly(@root_account.id, @subaccount2.id)
    end

    context "sharding" do
      specs_require_sharding

      it "works fetching account associations across shards" do
        @student = user_factory(active_all: true)
        user_session @student

        @shard2.activate { course_with_student(user: @student, active_all: true, account: Account.create!(account_calendar_visible: true)) }
        course_with_student(user: @student, active_all: true, account: Account.default)

        Account.last.trust_links.create!(managing_account: Account.default)
        Account.default.trust_links.create!(managing_account: Account.last)

        get :index
        expect(response).to be_successful
        expect(json_parse(response.body)["account_calendars"].pluck("id")).to contain_exactly(Account.default.id, Account.last.id)
      end
    end

    context "with a search term" do
      it "includes matching results from all accounts if a search term is provided" do
        course_with_student_logged_in(user: @user, account: @subaccount1a)
        course_with_student_logged_in(user: @user, account: @subaccount2)
        user_session(@user)
        get :index, params: { search_term: "sa-1" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["account_calendars"].pluck("id")).to contain_exactly(@subaccount1.id, @subaccount1a.id)
      end

      it "does not include hidden calendars in the search results" do
        course_with_student_logged_in(user: @user, account: @subaccount1a)
        user_session(@user)
        @subaccount1.account_calendar_visible = false
        @subaccount1.save!
        get :index, params: { search_term: "sa-1" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["account_calendars"].pluck("id")).to contain_exactly(@subaccount1a.id)
      end

      it "does not include accounts without an association" do
        course_with_student_logged_in(user: @user, account: @subaccount1)
        user_session(@user)
        get :index, params: { search_term: "sa-1" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json["account_calendars"].pluck("id")).to contain_exactly(@subaccount1.id)
      end
    end

    it "does not include a value for sub_account_count" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      get :index

      expect(response).to be_successful
      expect(response.body).not_to match(/sub_account_count/)
    end

    it "sorts the results by account name" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      course_with_student_logged_in(user: @user, account: @subaccount2)
      @root_account.name = "zzzz"
      @root_account.save!
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["account_calendars"].pluck("id")).to eq([@subaccount1.id, @subaccount1a.id, @subaccount2.id, @root_account.id])
    end

    it "returns an empty array for a user without any enrollments" do
      user_session(@user)
      get :index

      expect(response).to be_successful
      json = json_parse(response.body)
      expected_json = { "account_calendars" => [], "total_results" => 0 }
      expect(json).to eq(expected_json)
    end

    it "requires the user to be logged in" do
      get :index

      expect(response).to be_redirect
    end

    context "metrics collection" do
      before do
        allow(InstStatsd::Statsd).to receive(:increment)
        course_with_student_logged_in(user: @user, account: @root_account)
        @metric_name = "account_calendars.available_calendars_requested"
      end

      it "emits account_calendars.available_calendars_requested to statsd" do
        get :index
        expect(InstStatsd::Statsd).to have_received(:increment).once.with(@metric_name)
      end

      it "does not emit account_calendars.available_calendars_requested to statsd if a search term is included or if we're not on the first page" do
        get :index, params: { search_term: "sa-1" }
        expect(InstStatsd::Statsd).not_to have_received(:increment).with(@metric_name)

        get :index, params: { per_page: "2", page: "2" }
        expect(InstStatsd::Statsd).not_to have_received(:increment).with(@metric_name)
      end
    end
  end

  describe "GET 'show'" do
    it "returns the calendar with id, name, parent_account_id, root_account_id, visible, and auto_subscribe attributes" do
      course_with_student_logged_in(user: @user, account: @subaccount1a)
      user_session(@user)
      get :show, params: { account_id: @subaccount1a.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["id"]).to be @subaccount1a.id
      expect(json["name"]).to eq "SA-1a"
      expect(json["parent_account_id"]).to be @subaccount1.id
      expect(json["root_account_id"]).to be @root_account.id
      expect(json["visible"]).to be_truthy
      expect(json["auto_subscribe"]).to be_falsey
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
      expect(@root_account.account_calendar_subscription_type).to eq "manual"
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

    it "updates calendar auto_subscribe and returns calendar json" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      expect(@root_account.account_calendar_subscription_type).to eq "manual"

      put :update, params: { account_id: @root_account, auto_subscribe: true }
      expect(response).to be_successful
      json = json_parse(response.body)
      @root_account.reload
      expect(@root_account.account_calendar_subscription_type).to eq "auto"
      expect(@root_account.account_calendar_visible).to be true
      expect(json["id"]).to be @root_account.id
      expect(json["auto_subscribe"]).to be_truthy
    end

    it "updates both visible and auto_subscribe attributes" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)

      put :update, params: { account_id: @root_account, visible: false, auto_subscribe: true }
      expect(response).to be_successful
      @root_account.reload
      expect(@root_account.account_calendar_subscription_type).to eq "auto"
      expect(@root_account.account_calendar_visible).to be false
    end

    it "returns not found for a fake account id" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      put :update, params: { account_id: (Account.maximum(:id) || 0) + 1, visible: false }

      expect(response).to be_not_found
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility" do
      account_admin_user_with_role_changes(active_all: true,
                                           account: @root_account,
                                           user: @user,
                                           role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      put :update, params: { account_id: @root_account.id, visible: false }

      expect(response).to be_unauthorized
    end

    describe "metrics collection" do
      before do
        account_admin_user(active_all: true, account: @root_account, user: @user)
        user_session(@user)
        allow(InstStatsd::Statsd).to receive(:gauge)
      end

      it "collects auto-subscribe on data" do
        put :update, params: { account_id: @root_account, auto_subscribe: true }
        expect(InstStatsd::Statsd).to have_received(:gauge).once.with("account_calendars.auto_subscribing", 1)
      end

      it "collects auto-subscribe off data" do
        put :update, params: { account_id: @root_account, auto_subscribe: false }
        expect(InstStatsd::Statsd).to have_received(:gauge).once.with("account_calendars.manual_subscribing", 1)
      end
    end
  end

  describe "PUT 'bulk_update'" do
    it "updates all specified calendars" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      @subaccount1.account_calendar_visible = false
      @subaccount1.account_calendar_subscription_type = "auto"
      @subaccount1.save!
      @subaccount2.update!(account_calendar_subscription_type: "auto")
      put :bulk_update, params: {
        account_id: @root_account,
        _json: [{ id: @root_account.id, visible: false, auto_subscribe: true }, { id: @subaccount1a.id, visible: false }, { id: @subaccount1.id, visible: true, auto_subscribe: false }]
      }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["message"]).to eq "Updated 3 accounts"

      expect(@root_account.reload.account_calendar_visible).to be_falsey
      expect(@subaccount1.reload.account_calendar_visible).to be_truthy
      expect(@subaccount1a.reload.account_calendar_visible).to be_falsey
      expect(@subaccount2.reload.account_calendar_visible).to be_truthy # unchanged

      expect(@root_account.account_calendar_subscription_type).to eq "auto"
      expect(@subaccount1.account_calendar_subscription_type).to eq "manual"
      expect(@subaccount1a.account_calendar_subscription_type).to eq "manual" # unchanged
      expect(@subaccount2.account_calendar_subscription_type).to eq "auto" # unchanged
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility on provided account" do
      account_admin_user_with_role_changes(active_all: true,
                                           account: @subaccount2,
                                           user: @user,
                                           role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      put :bulk_update, params: { account_id: @subaccount2.id, _json: [{ id: @subaccount2.id, visible: false }] }
      expect(response).to be_unauthorized

      put :bulk_update, params: { account_id: @subaccount2.id, _json: [{ id: @subaccount2.id, auto_subscribe: true }] }
      expect(response).to be_unauthorized
    end

    it "returns unauthorized for an admin attempting to change accounts at a higher level" do
      account_admin_user(active_all: true, account: @subaccount1, user: @user)
      user_session(@user)
      put :bulk_update, params: {
        account_id: @subaccount1.id,
        _json: [{ id: @subaccount1.id, visible: false }, { id: @root_account.id, visible: false }]
      }

      expect(response).to be_unauthorized
    end

    it "returns bad_request for malformed data" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)

      put :bulk_update, params: { account_id: @root_account.id }
      expect(response).to be_bad_request

      put :bulk_update, params: { account_id: @root_account.id, _json: [] }
      expect(response).to be_bad_request

      put :bulk_update, params: { account_id: @root_account.id, _json: [{}] }
      expect(response).to be_bad_request

      put :bulk_update, params: {
        account_id: @root_account.id,
        _json: [{ id: @root_account.id, visible: true }, { id: @root_account.id, visible: false }]
      }
      expect(response).to be_bad_request
    end

    it "only updates provided attributes" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      @subaccount1.update!(account_calendar_subscription_type: "auto")
      user_session(@user)
      put :bulk_update, params: {
        account_id: @root_account,
        _json: [{ id: @root_account.id, auto_subscribe: true }, { id: @subaccount1.id, visible: true }]
      }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["message"]).to eq "Updated 2 accounts"

      expect(@root_account.reload.account_calendar_visible).to be_truthy
      expect(@root_account.account_calendar_subscription_type).to eq "auto"
      expect(@subaccount1.reload.account_calendar_visible).to be_truthy
      expect(@subaccount1.account_calendar_subscription_type).to eq "auto"
    end

    describe "metrics collection" do
      before do
        account_admin_user(active_all: true, account: @root_account, user: @user)
        user_session(@user)
        allow(InstStatsd::Statsd).to receive(:gauge)
      end

      it "collects auto-subscribe data`" do
        put :bulk_update, params: {
          account_id: @root_account,
          _json: [
            { id: @root_account.id, auto_subscribe: true },
            { id: @subaccount1.id, auto_subscribe: true },
            { id: @subaccount2.id, auto_subscribe: false }
          ]
        }
        expect(InstStatsd::Statsd).to have_received(:gauge).once.with("account_calendars.auto_subscribing", 2)
        expect(InstStatsd::Statsd).to have_received(:gauge).once.with("account_calendars.manual_subscribing", 1)
      end
    end
  end

  describe "GET 'all_calendars'" do
    it "returns provided account calendar and first level of sub-accounts" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @root_account.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to contain_exactly(@root_account.id, @subaccount1.id, @subaccount2.id)
    end

    it "returns hidden calendars" do
      account_admin_user(active_all: true, account: @subaccount1, user: @user)
      @subaccount1.account_calendar_visible = false
      @subaccount1.save!
      user_session(@user)
      get :all_calendars, params: { account_id: @subaccount1.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to contain_exactly(@subaccount1.id, @subaccount1a.id)
    end

    it "returns only one account if provided account doesn't have subaccounts" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @subaccount2.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to contain_exactly(@subaccount2.id)
    end

    context "with a search term" do
      it "includes matching results if a search term is provided" do
        account_admin_user(active_all: true, account: @root_account, user: @user)
        user_session(@user)
        get :all_calendars, params: { account_id: @root_account.id, search_term: "sa-1" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json.pluck("id")).to contain_exactly(@subaccount1.id, @subaccount1a.id)
      end

      it "returns SearchTermTooShortError if search term is less than 2 characters" do
        account_admin_user(active_all: true, account: @root_account, user: @user)
        user_session(@user)
        get :all_calendars, params: { account_id: @root_account.id, search_term: "a" }

        expect(response).to be_bad_request
        json = json_parse(response.body)
        expect(json["errors"][0]["message"]).to eq("2 or more characters is required")
      end
    end

    context "with a filter" do
      before :once do
        @subaccount1.account_calendar_visible = false
        @subaccount1.save!
        account_admin_user(active_all: true, account: @root_account, user: @user)
      end

      before do
        user_session(@user)
      end

      it "only returns visible calendars if filter is 'visible'" do
        get :all_calendars, params: { account_id: @root_account.id, filter: "visible" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json.pluck("id")).to contain_exactly(@root_account.id, @subaccount1a.id, @subaccount2.id)
      end

      it "only returns hidden calendars if filter is 'hidden'" do
        get :all_calendars, params: { account_id: @root_account.id, filter: "hidden" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json.pluck("id")).to contain_exactly(@subaccount1.id)
      end

      it "returns bad_request if filter is not 'visible' or 'hidden'" do
        get :all_calendars, params: { account_id: @root_account.id, filter: "rando" }
        expect(response).to be_bad_request
      end
    end

    context "with a search term and a filter" do
      it "returns accounts matching the search term and filter" do
        @subaccount1a.account_calendar_visible = false
        @subaccount1a.save!
        account_admin_user(active_all: true, account: @root_account, user: @user)
        user_session(@user)
        get :all_calendars, params: { account_id: @root_account.id, search_term: "sa-1", filter: "visible" }

        expect(response).to be_successful
        json = json_parse(response.body)
        expect(json.pluck("id")).to contain_exactly(@subaccount1.id)
      end
    end

    it "returns not found for a fake account id" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: (Account.maximum(:id) || 0) + 1 }

      expect(response).to be_not_found
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility" do
      account_admin_user_with_role_changes(active_all: true,
                                           account: @root_account,
                                           user: @user,
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
      expect(json.pluck("id")).to contain_exactly(@subaccount2.id)
    end

    it "includes appropriate value for sub_account_count in the response" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :all_calendars, params: { account_id: @root_account.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.length).to be 3
      expect(json.find { |c| c["id"] == @root_account.id }["sub_account_count"]).to be 2
      expect(json.find { |c| c["id"] == @subaccount1.id }["sub_account_count"]).to be 1
      expect(json.find { |c| c["id"] == @subaccount2.id }["sub_account_count"]).to be 0
    end

    it "sorts response by account name, but includes requested account first" do
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      @root_account.name = "zzzz"
      @root_account.save!
      @subaccount2.name = "aaaa"
      @subaccount2.save!
      get :all_calendars, params: { account_id: @root_account.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json.pluck("id")).to eq([@root_account.id, @subaccount2.id, @subaccount1.id])
    end
  end

  describe "GET 'visible_calendars_count'" do
    it "returns the count of visible account calendars" do
      @subaccount1.account_calendar_visible = false
      @subaccount1.save!
      account_admin_user(active_all: true, account: @root_account, user: @user)
      user_session(@user)
      get :visible_calendars_count, params: { account_id: @root_account.id }

      expect(response).to be_successful
      json = json_parse(response.body)
      expect(json["count"]).to eq(3)
    end

    it "returns unauthorized for an admin without :manage_account_calendar_visibility" do
      account_admin_user_with_role_changes(active_all: true,
                                           account: @root_account,
                                           user: @user,
                                           role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      get :visible_calendars_count, params: { account_id: @root_account.id }

      expect(response).to be_unauthorized
    end
  end
end
