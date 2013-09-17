#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe "AuthenticationAudit API", type: :integration do
  it_should_behave_like "cassandra audit logs"

  before do
    @viewing_user = site_admin_user
    @account = Account.default
    user_with_pseudonym(active_all: true)
    @event = Auditors::Authentication.record(@pseudonym, 'login')
  end

  def fetch_for_context(context, options={})
    type = context.class.to_s.downcase
    id = context.id.to_s

    arguments = { controller: 'authentication_audit_api', action: "for_#{type}", :"#{type}_id" => id, format: 'json' }
    query_string = []

    if per_page = options.delete(:per_page)
      arguments[:per_page] = per_page.to_s
      query_string << "per_page=#{arguments[:per_page]}"
    end

    if start_time = options.delete(:start_time)
      arguments[:start_time] = start_time.iso8601
      query_string << "start_time=#{arguments[:start_time]}"
    end

    if end_time = options.delete(:end_time)
      arguments[:end_time] = end_time.iso8601
      query_string << "end_time=#{arguments[:end_time]}"
    end

    path = "/api/v1/audit/authentication/#{type.pluralize}/#{id}"
    path += "?" + query_string.join('&') if query_string.present?
    api_call_as_user(@viewing_user, :get, path, arguments, {}, {}, options.slice(:expected_status))
  end

  def expect_event_for_context(context, event, options={})
    json = fetch_for_context(context, options)
    json['events'].map{ |e| [Shard.global_id_for(e['pseudonym_id']), e['event_type']] }.
      should include([event.pseudonym_id, event.event_type])
  end

  def forbid_event_for_context(context, event, options={})
    json = fetch_for_context(context, options)
    json['events'].map{ |e| [e['pseudonym_id'], e['event_type']] }.
      should_not include([event.pseudonym_id, event.event_type])
  end

  describe "formatting" do
    before do
      @json = fetch_for_context(@user)
    end

    it "should have a meta key with primaryCollection=events" do
      @json['meta']['primaryCollection'].should == 'events'
    end

    describe "events collection" do
      before do
        @json = @json['events']
      end

      it "should be formatted as an array of AuthenticationEvent objects" do
        @json.should == [{
          "created_at" => @event.created_at.in_time_zone.iso8601,
          "event_type" => @event.event_type,
          "pseudonym_id" => @pseudonym.id,
          "account_id" => @account.id,
          "user_id" => @user.id
        }]
      end
    end

    describe "pseudonyms collection" do
      before do
        @json = @json['pseudonyms']
      end

      it "should be formatted as an array of Pseudonym objects" do
        @json.should == [{
          "id" => @pseudonym.id,
          "account_id" => @account.id,
          "user_id" => @user.id,
          "unique_id" => @pseudonym.unique_id,
          "sis_user_id" => nil
        }]
      end
    end

    describe "accounts collection" do
      before do
        @json = @json['accounts']
      end

      it "should be formatted as an array of Account objects" do
        @json.should == [{
          "id" => @account.id,
          "name" => @account.name,
          "parent_account_id" => nil,
          "root_account_id" => nil,
          "default_time_zone" => @account.default_time_zone.tzinfo.name,
          "default_storage_quota_mb" => @account.default_storage_quota_mb,
          "default_user_storage_quota_mb" => @account.default_user_storage_quota_mb,
          "default_group_storage_quota_mb" => @account.default_group_storage_quota_mb
        }]
      end
    end

    describe "users collection" do
      before do
        @json = @json['users']
      end

      it "should be formatted as an array of User objects" do
        @json.should == [{
          "id" => @user.id,
          "name" => @user.name,
          "sortable_name" => @user.sortable_name,
          "short_name" => @user.short_name,
          "login_id" => @pseudonym.unique_id
        }]
      end
    end
  end

  context "nominal cases" do
    it "should include events at pseudonym endpoint" do
      expect_event_for_context(@pseudonym, @event)
    end

    it "should include events at account endpoint" do
      expect_event_for_context(@account, @event)
    end

    it "should include events at user endpoint" do
      expect_event_for_context(@user, @event)
    end
  end

  context "with a second account (same user)" do
    before do
      @account = account_model
      user_with_pseudonym(user: @user, account: @account, active_all: true)
    end

    it "should not include cross-account events at pseudonym endpoint" do
      forbid_event_for_context(@pseudonym, @event)
    end

    it "should not include cross-account events at account endpoint" do
      forbid_event_for_context(@account, @event)
    end

    it "should include cross-account events at user endpoint" do
      expect_event_for_context(@user, @event)
    end
  end

  context "with a second user (same account)" do
    before do
      user_with_pseudonym(active_all: true)
    end

    it "should not include cross-user events at pseudonym endpoint" do
      forbid_event_for_context(@pseudonym, @event)
    end

    it "should include cross-user events at account endpoint" do
      expect_event_for_context(@account, @event)
    end

    it "should not include cross-user events at user endpoint" do
      forbid_event_for_context(@user, @event)
    end
  end

  describe "start_time and end_time" do
    before do
      @event2 = @pseudonym.shard.activate do
        record = Auditors::Authentication::Record.new(
          'id' => UUIDSingleton.instance.generate,
          'created_at' => 1.day.ago,
          'pseudonym' => @pseudonym,
          'event_type' => 'logout')
        Auditors::Authentication::Stream.insert(record)
      end
    end

    it "should recognize :start_time for pseudonyms" do
      expect_event_for_context(@pseudonym, @event, start_time: 12.hours.ago)
      forbid_event_for_context(@pseudonym, @event2, start_time: 12.hours.ago)
    end

    it "should recognize :newest for pseudonyms" do
      expect_event_for_context(@pseudonym, @event2, end_time: 12.hours.ago)
      forbid_event_for_context(@pseudonym, @event, end_time: 12.hours.ago)
    end

    it "should recognize :start_time for accounts" do
      expect_event_for_context(@account, @event, start_time: 12.hours.ago)
      forbid_event_for_context(@account, @event2, start_time: 12.hours.ago)
    end

    it "should recognize :newest for accounts" do
      expect_event_for_context(@account, @event2, end_time: 12.hours.ago)
      forbid_event_for_context(@account, @event, end_time: 12.hours.ago)
    end

    it "should recognize :start_time for users" do
      expect_event_for_context(@user, @event, start_time: 12.hours.ago)
      forbid_event_for_context(@user, @event2, start_time: 12.hours.ago)
    end

    it "should recognize :newest for users" do
      expect_event_for_context(@user, @event2, end_time: 12.hours.ago)
      forbid_event_for_context(@user, @event, end_time: 12.hours.ago)
    end
  end

  context "deleted entities" do
    it "should 404 for inactive pseudonyms" do
      @pseudonym.destroy
      fetch_for_context(@pseudonym, expected_status: 404)
    end

    it "should 404 for inactive accounts" do
      # can't just delete Account.default
      @account = account_model
      @account.destroy
      fetch_for_context(@account, expected_status: 404)
    end

    it "should 404 for inactive users" do
      @user.destroy
      fetch_for_context(@user, expected_status: 404)
    end
  end

  describe "permissions" do
    before do
      @user, @viewing_user = @user, user_model
    end

    context "no permission on account" do
      it "should not authorize the pseudonym endpoint" do
        fetch_for_context(@pseudonym, expected_status: 401)
      end

      it "should not authorize the account endpoint" do
        fetch_for_context(@account, expected_status: 401)
      end

      it "should not authorize the user endpoint" do
        fetch_for_context(@user, expected_status: 401)
      end
    end

    context "with :view_statistics permission on account" do
      before do
        @user, _ = @user, account_admin_user_with_role_changes(
          :account => @account, :user => @viewing_user,
          :membership_type => 'CustomAdmin',
          :role_changes => {:view_statistics => true})
      end

      it "should authorize the pseudonym endpoint" do
        fetch_for_context(@pseudonym, expected_status: 200)
      end

      it "should authorize the account endpoint" do
        fetch_for_context(@account, expected_status: 200)
      end

      it "should authorize the user endpoint" do
        fetch_for_context(@user, expected_status: 200)
      end
    end

    context "with :manage_user_logins permission on account" do
      before do
        @user, _ = @user, account_admin_user_with_role_changes(
          :account => @account, :user => @viewing_user,
          :membership_type => 'CustomAdmin',
          :role_changes => {:manage_user_logins => true})
      end

      it "should authorize the pseudonym endpoint" do
        fetch_for_context(@pseudonym, expected_status: 200)
      end

      it "should authorize the account endpoint" do
        fetch_for_context(@account, expected_status: 200)
      end

      it "should authorize the user endpoint" do
        fetch_for_context(@user, expected_status: 200)
      end
    end

    context "with :view_statistics permission on site admin account" do
      before do
        @user, _ = @user, account_admin_user_with_role_changes(
          :account => Account.site_admin, :user => @viewing_user,
          :membership_type => 'CustomAdmin',
          :role_changes => {:view_statistics => true})
      end

      it "should authorize the pseudonym endpoint" do
        fetch_for_context(@pseudonym, expected_status: 200)
      end

      it "should authorize the account endpoint" do
        fetch_for_context(@account, expected_status: 200)
      end

      it "should authorize the user endpoint" do
        fetch_for_context(@user, expected_status: 200)
      end
    end

    context "with :manage_user_logins permission on site admin account" do
      before do
        @user, _ = @user, account_admin_user_with_role_changes(
          :account => Account.site_admin, :user => @viewing_user,
          :membership_type => 'CustomAdmin',
          :role_changes => {:manage_user_logins => true})
      end

      it "should authorize the pseudonym endpoint" do
        fetch_for_context(@pseudonym, expected_status: 200)
      end

      it "should authorize the account endpoint" do
        fetch_for_context(@account, expected_status: 200)
      end

      it "should authorize the user endpoint" do
        fetch_for_context(@user, expected_status: 200)
      end
    end

    describe "per-account permissions when fetching by user" do
      before do
        @account = account_model
        user_with_pseudonym(user: @user, account: @account, active_all: true)
        @user, _ = @user, account_admin_user_with_role_changes(
          :account => @account, :user => @viewing_user,
          :membership_type => 'CustomAdmin',
          :role_changes => {:manage_user_logins => true})
      end

      context "without permission on the second account" do
        it "should not include cross-account events at user endpoint" do
          forbid_event_for_context(@user, @event)
        end
      end

      context "with permission on the site admin account" do
        before do
          @user, _ = @user, account_admin_user_with_role_changes(
            :account => Account.site_admin, :user => @viewing_user,
            :membership_type => 'CustomAdmin',
            :role_changes => {:manage_user_logins => true})
        end

        it "should include cross-account events at user endpoint" do
          expect_event_for_context(@user, @event)
        end
      end

      context "when viewing self" do
        before do
          @viewing_user = @user
        end

        it "should include cross-account events at user endpoint" do
          expect_event_for_context(@user, @event)
        end
      end
    end
  end

  describe "per-account with sharding when fetching by user" do
    specs_require_sharding

    before do
      @shard2.activate do
        @account = account_model
        user_with_pseudonym(user: @user, account: @account, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, 'logout')
      end
    end

    it "should see events on both shards" do
      expect_event_for_context(@user, @event)
      expect_event_for_context(@user, @event2)
    end

    context "with permission on only a subset of accounts" do
      before do
        @user, @viewing_user = @user, @shard2.activate{ user_model }
        @user, _ = @user, @shard2.activate do
          account_admin_user_with_role_changes(
            :account => @account, :user => @viewing_user,
            :membership_type => 'CustomAdmin',
            :role_changes => {:manage_user_logins => true})
        end
      end

      it "should include events from visible accounts" do
        expect_event_for_context(@user, @event2)
      end

      it "should not include events from non-visible accounts" do
        forbid_event_for_context(@user, @event)
      end
    end
  end

  describe "pagination" do
    before do
      # 3 events total
      Auditors::Authentication.record(@pseudonym, 'logout')
      Auditors::Authentication.record(@pseudonym, 'login')
      @json = fetch_for_context(@user, :per_page => 2)
    end

    it "should only return one page of results" do
      @json['events'].size.should == 2
    end

    it "should have pagination headers" do
      response.headers['Link'].should match(/rel="next"/)
    end
  end
end
