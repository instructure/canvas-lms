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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe Auditors::Authentication do
  include_examples "cassandra audit logs"

  let(:request_id) { 42 }

  before do
    shard_class = Class.new {
      define_method(:activate) { |&b| b.call }
    }

    EventStream.current_shard_lookup = lambda {
      shard_class.new
    }

    RequestContextGenerator.stubs( :request_id => request_id )
    @account = Account.default
    user_with_pseudonym(active_all: true)
    @event = Auditors::Authentication.record(@pseudonym, 'login')
  end

  context "nominal cases" do
    it "should include event for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1)).
        to include(@event)
    end

    it "should include event for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(:per_page => 1)).
        to include(@event)
    end

    it "should include event at user" do
      expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 1)).
        to include(@event)
    end

    it "should set request_id" do
      expect(@event.request_id).to eq request_id.to_s
    end
  end

  context "with a second account (same user)" do
    before do
      @account = account_model
      user_with_pseudonym(user: @user, account: @account, active_all: true)
    end

    it "should not include cross-account events for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1)).
        not_to include(@event)
    end

    it "should not include cross-account events for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(:per_page => 1)).
        not_to include(@event)
    end

    it "should include cross-account events for user" do
      expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 1)).
        to include(@event)
    end
  end

  context "with a second user (same account)" do
    before do
      user_with_pseudonym(active_all: true)
    end

    it "should not include cross-user events for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(:per_page => 1)).
        not_to include(@event)
    end

    it "should include cross-user events for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(:per_page => 1)).
        to include(@event)
    end

    it "should not include cross-user events for user" do
      expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 1)).
        not_to include(@event)
    end
  end

  describe "options forwarding" do
    before do
      @event2 = @pseudonym.shard.activate do
        record = Auditors::Authentication::Record.new(
          'id' => CanvasUUID.generate,
          'created_at' => 1.day.ago,
          'pseudonym' => @pseudonym,
          'event_type' => 'login')
        Auditors::Authentication::Stream.insert(record)
      end
    end

    it "should recognize :oldest for pseudonyms" do
      page = Auditors::Authentication.
        for_pseudonym(@pseudonym, oldest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "should recognize :newest for pseudonyms" do
      page = Auditors::Authentication.
        for_pseudonym(@pseudonym, newest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end

    it "should recognize :oldest for accounts" do
      page = Auditors::Authentication.
        for_account(@account, oldest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "should recognize :newest for accounts" do
      page = Auditors::Authentication.
        for_account(@account, newest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end

    it "should recognize :oldest for users" do
      page = Auditors::Authentication.
        for_user(@user, oldest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "should recognize :newest for users" do
      page = Auditors::Authentication.
        for_user(@user, newest: 12.hours.ago).
        paginate(:per_page => 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end
  end

  describe "sharding" do
    specs_require_sharding

    context "different shard, same database server" do
      before do
        @shard1.activate do
          @account = account_model
          user_with_pseudonym(account: @account, active_all: true)
          @event1 = Auditors::Authentication.record(@pseudonym, 'login')
        end
        user_with_pseudonym(user: @user, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, 'login')
      end

      it "should include events from the user's native shard" do
        expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 2)).
          to include(@event1)
      end

      it "should include events from the other pseudonym's shard" do
        expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 2)).
          to include(@event2)
      end

      it "should not include duplicate events" do
        expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 4).
          size).to eq 2
      end
    end

    context "different shard, different database server" do
      before do
        @shard2.activate do
          @account = account_model
          user_with_pseudonym(account: @account, active_all: true)
          @event1 = Auditors::Authentication.record(@pseudonym, 'login')
        end
        user_with_pseudonym(user: @user, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, 'login')
      end

      it "should include events from the user's native shard" do
        expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 2)).
          to include(@event1)
      end

      it "should include events from the other pseudonym's shard" do
        expect(Auditors::Authentication.for_user(@user).paginate(:per_page => 2)).
          to include(@event2)
      end
    end
  end
end
