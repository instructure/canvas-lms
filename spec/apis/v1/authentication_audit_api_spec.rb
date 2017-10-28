#
# Copyright (C) 2013 - 2014 Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe "AuthenticationAudit API", type: :request do
  context "not configured" do
    before do
      allow(Canvas::Cassandra::DatabaseBuilder).to receive(:configured?).with('auditors').and_return(false)
      site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
    end

    it "should 404" do
      raw_api_call(:get, "/api/v1/audit/authentication/logins/#{@pseudonym.id}", controller: 'authentication_audit_api', action: "for_login", :login_id => @pseudonym.id.to_s, format: 'json')
      assert_status(404)
    end
  end

  context "configured" do
    include_examples "cassandra audit logs"

    before do
      Setting.set('enable_page_views', 'cassandra')
      @request_id = SecureRandom.uuid
      allow(RequestContextGenerator).to receive_messages( :request_id => @request_id )

      @viewing_user = site_admin_user(user: user_with_pseudonym(account: Account.site_admin))
      @account = Account.default
      @custom_role = custom_account_role('CustomAdmin', :account => @account)
      @custom_sa_role = custom_account_role('CustomAdmin', :account => Account.site_admin)
      user_with_pseudonym(active_all: true)

      @page_view = PageView.new
      @page_view.user = @viewing_user
      @page_view.request_id = @request_id
      @page_view.remote_ip = '10.10.10.10'
      @page_view.created_at = Time.now
      @page_view.updated_at = Time.now
      @page_view.save!

      @event = Auditors::Authentication.record(@pseudonym, 'login')
    end

    def fetch_for_context(context, options={})
      type = context.class.to_s.downcase unless type = options.delete(:type)
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
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .to include([event.id, event.event_type])
      json
    end

    def forbid_event_for_context(context, event, options={})
      json = options.delete(:json)
      json ||= fetch_for_context(context, options)
      expect(json['events'].map{ |e| [e['id'], e['event_type']] })
                    .not_to include([event.id, event.event_type])
      json
    end

    describe "formatting" do
      before do
        @json = fetch_for_context(@user)
      end

      it "should have correct root keys" do
        expect(@json.keys.sort).to eq %w{events linked links}
      end

      it "should have a formatted links key" do
        links = {
          "events.login" => nil,
          "events.account" => "http://www.example.com/api/v1/accounts/{events.account}",
          "events.user" => nil,
          "events.page_view" => nil
        }
        expect(@json['links']).to eq links
      end

      it "should have a formatted linked key" do
        expect(@json['linked'].keys.sort).to eq %w{accounts logins page_views users}
        expect(@json['linked']['accounts'].is_a?(Array)).to be_truthy
        expect(@json['linked']['logins'].is_a?(Array)).to be_truthy
        expect(@json['linked']['page_views'].is_a?(Array)).to be_truthy
        expect(@json['linked']['users'].is_a?(Array)).to be_truthy
      end

      describe "events collection" do
        before do
          @json = @json['events']
        end

        it "should be formatted as an array of AuthenticationEvent objects" do
          expect(@json).to eq [{
            "id" => @event.id,
            "created_at" => @event.created_at.in_time_zone.iso8601,
            "event_type" => @event.event_type,
            "links" => {
              "login" => @pseudonym.id,
              "account" => @account.id,
              "user" => @user.id,
              "page_view" => @event.request_id
            }
          }]
        end
      end

      describe "logins collection" do
        before do
          @json = @json['linked']['logins']
        end

        it "should be formatted as an array of Pseudonym objects" do
          expect(@json).to eq [{
            "id" => @pseudonym.id,
            "account_id" => @account.id,
            "user_id" => @user.id,
            "unique_id" => @pseudonym.unique_id,
            "sis_user_id" => nil,
            "integration_id" => nil,
            "authentication_provider_id" => nil
          }]
        end
      end

      describe "accounts collection" do
        before do
          @json = @json['linked']['accounts']
        end

        it "should be formatted as an array of Account objects" do
          expect(@json).to eq [{
            "id" => @account.id,
            "uuid" => @account.uuid,
            "name" => @account.name,
            "parent_account_id" => nil,
            "root_account_id" => nil,
            "workflow_state" => 'active',
            "default_time_zone" => @account.default_time_zone.tzinfo.name,
            "default_storage_quota_mb" => @account.default_storage_quota_mb,
            "default_user_storage_quota_mb" => @account.default_user_storage_quota_mb,
            "default_group_storage_quota_mb" => @account.default_group_storage_quota_mb
          }]
        end
      end

      describe "users collection" do
        before do
          @json = @json['linked']['users']
        end

        it "should be formatted as an array of User objects" do
          expect(@json).to eq [{
            "id" => @user.id,
            "name" => @user.name,
            "sortable_name" => @user.sortable_name,
            "short_name" => @user.short_name,
            "sis_user_id"=>nil,
            "integration_id"=>nil,
            "sis_import_id"=>nil,
            "login_id" => @pseudonym.unique_id
          }]
        end
      end

      describe "page_views collection" do
        before do
          @json = @json['linked']['page_views']
        end

        it "should be formatted as an array of page_view objects" do
          expect(@json.size).to eql(1)
        end
      end
    end

    context "nominal cases" do
      it "should include events at login endpoint" do
        expect_event_for_context(@pseudonym, @event, type: 'login')
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

      it "should not include cross-account events at login endpoint" do
        forbid_event_for_context(@pseudonym, @event, type: 'login')
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

      it "should not include cross-user events at login endpoint" do
        forbid_event_for_context(@pseudonym, @event, type: 'login')
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
            'id' => SecureRandom.uuid,
            'created_at' => 1.day.ago,
            'pseudonym' => @pseudonym,
            'event_type' => 'logout')
          Auditors::Authentication::Stream.insert(record)
        end
      end

      it "should recognize :start_time for logins" do
        expect_event_for_context(@pseudonym, @event, start_time: 12.hours.ago, type: 'login')
        forbid_event_for_context(@pseudonym, @event2, start_time: 12.hours.ago, type: 'login')
      end

      it "should recognize :newest for logins" do
        expect_event_for_context(@pseudonym, @event2, end_time: 12.hours.ago, type: 'login')
        forbid_event_for_context(@pseudonym, @event, end_time: 12.hours.ago, type: 'login')
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
      it "should 404 for inactive logins" do
        @pseudonym.destroy
        fetch_for_context(@pseudonym, expected_status: 404, type: 'login')
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

      it "should not allow other account models" do
        new_root_account = Account.create!(name: 'New Account')
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(new_root_account)
        @user, @pseudonym, @viewing_user = @user, @pseudonym, user_with_pseudonym(account: new_root_account)

        fetch_for_context(@pseudonym, expected_status: 401, type: 'login')
        fetch_for_context(@account, expected_status: 401)
        fetch_for_context(@user, expected_status: 401)
      end

      context "no permission on account" do
        it "should not authorize the login endpoint" do
          fetch_for_context(@pseudonym, expected_status: 401, type: 'login')
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
            :role => @custom_role,
            :role_changes => {:view_statistics => true})
        end

        it "should authorize the login endpoint" do
          fetch_for_context(@pseudonym, expected_status: 200, type: 'login')
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
            :role => @custom_role,
            :role_changes => {:manage_user_logins => true})
        end

        it "should authorize the login endpoint" do
          fetch_for_context(@pseudonym, expected_status: 200, type: 'login')
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
            :role => @custom_sa_role,
            :role_changes => {:view_statistics => true})
        end

        it "should authorize the login endpoint" do
          fetch_for_context(@pseudonym, expected_status: 200, type: 'login')
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
            :role => @custom_sa_role,
            :role_changes => {:manage_user_logins => true})
        end

        it "should authorize the login endpoint" do
          fetch_for_context(@pseudonym, expected_status: 200, type: 'login')
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
          custom_role = custom_account_role('CustomAdmin', :account => @account)
          @user, _ = @user, account_admin_user_with_role_changes(
            :account => @account, :user => @viewing_user,
            :role => custom_role,
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
              :role => @custom_sa_role,
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
            custom_role = custom_account_role("CustomAdmin", :account => @account)
            account_admin_user_with_role_changes(
              :account => @account, :user => @viewing_user,
              :role => custom_role,
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
        expect(@json['events'].size).to eq 2
      end

      it "should have pagination headers" do
        expect(response.headers['Link']).to match(/rel="next"/)
      end
    end
  end
end
