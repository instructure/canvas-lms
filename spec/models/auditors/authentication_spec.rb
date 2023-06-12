# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe Auditors::Authentication do
  before do
    shard_class = Class.new do
      define_method(:activate) { |&b| b.call }
    end
    EventStream.current_shard_lookup = lambda do
      shard_class.new
    end
    allow(RequestContextGenerator).to receive_messages(request_id:)
  end

  let(:request_id) { 42 }

  before do
    @account = Account.default
    user_with_pseudonym(active_all: true)
    @raw_event = Auditors::Authentication.record(@pseudonym, "login")
    @event = Auditors::ActiveRecord::AuthenticationRecord.where(uuid: @raw_event.id).first
  end

  context "nominal cases" do
    it "returns the event on generation" do
      expect(@raw_event.class).to eq(Auditors::Authentication::Record)
    end

    it "includes event for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(per_page: 1))
        .to include(@event)
    end

    it "includes event for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(per_page: 1))
        .to include(@event)
    end

    it "includes event at user" do
      expect(Auditors::Authentication.for_user(@user).paginate(per_page: 1))
        .to include(@event)
    end

    it "sets request_id" do
      expect(@event.request_id).to eq request_id.to_s
    end
  end

  context "with a second account (same user)" do
    before do
      @account = account_model
      user_with_pseudonym(user: @user, account: @account, active_all: true)
    end

    it "does not include cross-account events for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(per_page: 1))
        .not_to include(@event)
    end

    it "does not include cross-account events for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(per_page: 1))
        .not_to include(@event)
    end

    it "includes cross-account events for user" do
      expect(Auditors::Authentication.for_user(@user).paginate(per_page: 1))
        .to include(@event)
    end
  end

  context "with a second user (same account)" do
    before do
      user_with_pseudonym(active_all: true)
    end

    it "does not include cross-user events for pseudonym" do
      expect(Auditors::Authentication.for_pseudonym(@pseudonym).paginate(per_page: 1))
        .not_to include(@event)
    end

    it "includes cross-user events for account" do
      expect(Auditors::Authentication.for_account(@account).paginate(per_page: 1))
        .to include(@event)
    end

    it "does not include cross-user events for user" do
      expect(Auditors::Authentication.for_user(@user).paginate(per_page: 1))
        .not_to include(@event)
    end
  end

  describe "options forwarding" do
    before do
      @raw_event2 = @pseudonym.shard.activate do
        record = Auditors::Authentication::Record.new(
          "id" => SecureRandom.uuid,
          "created_at" => 1.day.ago,
          "pseudonym" => @pseudonym,
          "event_type" => "login"
        )
        Auditors::Authentication::Stream.insert(record)
      end
      @event2 = Auditors::ActiveRecord::AuthenticationRecord.where(uuid: @raw_event2.id).first
    end

    it "recognizes :oldest for pseudonyms" do
      page = Auditors::Authentication
             .for_pseudonym(@pseudonym, oldest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "recognizes :newest for pseudonyms" do
      page = Auditors::Authentication
             .for_pseudonym(@pseudonym, newest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end

    it "recognizes :oldest for accounts" do
      page = Auditors::Authentication
             .for_account(@account, oldest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "recognizes :newest for accounts" do
      page = Auditors::Authentication
             .for_account(@account, newest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end

    it "recognizes :oldest for users" do
      page = Auditors::Authentication
             .for_user(@user, oldest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event)
      expect(page).not_to include(@event2)
    end

    it "recognizes :newest for users" do
      page = Auditors::Authentication
             .for_user(@user, newest: 12.hours.ago)
             .paginate(per_page: 1)
      expect(page).to include(@event2)
      expect(page).not_to include(@event)
    end
  end

  describe "sharding" do
    specs_require_sharding

    before(:once) do
      [Shard.current, @shard1, @shard2].each do |s|
        s.activate { Auditors::ActiveRecord::Partitioner.process }
      end
    end

    context "different shard, db auditors" do
      before do
        @shard2.activate do
          @account = account_model
          user_with_pseudonym(account: @account, active_all: true)
          @event1 = Auditors::Authentication.record(@pseudonym, "login")
        end
        user_with_pseudonym(user: @user, active_all: true)
        @event2 = Auditors::Authentication.record(@pseudonym, "login")
      end

      it "includes events from the user's native shard" do
        records = Auditors::Authentication.for_user(@user).paginate(per_page: 2)
        uuids = records.map(&:uuid)
        expect(uuids).to include(@event1.id)
      end

      it "includes events from the other pseudonym's shard" do
        records = Auditors::Authentication.for_user(@user).paginate(per_page: 2)
        uuids = records.map(&:uuid)
        expect(uuids).to include(@event2.id)
      end
    end
  end
end
