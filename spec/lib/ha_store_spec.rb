#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "../spec_helper.rb"

describe ActiveSupport::Cache::HaStore do
  before do
    skip unless Canvas.redis_enabled?
  end

  let(:store) { ActiveSupport::Cache::HaStore.new(url: Canvas.redis.id, expires_in: 5.minutes.to_i, race_condition_ttl: 7.days.to_i, consul_event: 'invalidate') }

  describe "#fetch" do
    it "locks for a new key" do
      expect(store).to receive(:read_entry).and_return(nil)
      expect(store).to receive(:lock).and_return("nonce")
      expect(store).to receive(:write_entry)
      expect(store).to receive(:unlock)
      expect(store.fetch('bob') { 42 }).to eq 42
    end

    it "doesn't lock for an existing key" do
      store.write("bob", 42)
      expect(store).to receive(:lock).never
      expect(store).to receive(:unlock).never
      expect(store.fetch('bob') { raise "not reached" }).to eq 42
    end

    it "doesn't populate for a stale key that someone else is populating" do
      store.write("bob", 42, expires_in: -1)
      expect(store).to receive(:lock).and_return(false)
      expect(store).to receive(:unlock).never

      expect(store.fetch('bob') { raise "not reached" }).to eq 42
    end

    it "waits to get a lock for a non-existent key" do
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return(false).ordered
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return('nonce').ordered
      expect(store).to receive(:write_entry)
      expect(store).to receive(:unlock)
      expect(store.fetch('bob') { 42 }).to eq 42
    end

    it "waits and then reads fresh data for a non-existent key" do
      store.write("bob", 42)
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return(false).ordered
      expect(store).to receive(:read_entry).and_call_original.ordered
      expect(store).to receive(:unlock).never
      expect(store.fetch('bob') { raise "not reached" }).to eq 42
    end

    it "returns stale data if there is an exception calculating new data" do
      store.write("bob", 42, expires_in: 1)
      Timecop.travel(5) do
        exception = RuntimeError.new("die")
        expect(Canvas::Errors).to receive(:capture).with(exception)
        expect(store.fetch('bob') { raise exception }).to eq 42
      end
    end

    it "calculates anyway if we couldn't contact the cache" do
      expect(store).to receive(:read_entry).and_return(nil)
      expect(store).to receive(:lock).and_return(true)
      expect(store).to receive(:write_entry)
      expect(store).to receive(:unlock).never
      expect(store.fetch('bob') { 42 }).to eq 42
    end
  end

  describe "#delete" do
    it "triggers a consul event when configured" do
      # will get called twice; once with rails52: prefix, once without
      expect(Imperium::Events.default_client).to receive(:fire).with("invalidate", match(/mykey$/), anything).twice
      store.delete('mykey')
    end
  end

  describe "consume_consul_events" do
    it "works" do
      # check that Canvas.redis is equivalent to Redis.new that consume_consule_events uses
      # I would normally compare against `id`, but that might have localhost vs. 127.0.0.1
      redis = Redis.new(connect_timeout: 0.5)
      secret_key = SecureRandom.uuid
      Canvas.redis.set(secret_key, "1", ex: 5)
      skip "Can't run this spec unless redis is default configured" unless (redis.get(secret_key) rescue nil) == "1"
      consul_event_id = SecureRandom.uuid

      Bundler.with_clean_env do
        payload = [{ ID: consul_event_id, Payload: Base64.strict_encode64(secret_key) }].to_json

        `echo #{Shellwords.escape(payload)} | #{Rails.root}/script/consume_consul_events`
        expect($?).to be_success
      end
      expect(redis.get(secret_key)).to be_nil
      expect(redis.zrank("consul_events", consul_event_id)).not_to be_nil
    end
  end
end
