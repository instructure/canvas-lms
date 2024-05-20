# frozen_string_literal: true

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

require_relative "../../../spec_helper"

# rubocop:disable Style/RedundantFetchBlock it's a cachestore, not a Hash
describe ActiveSupport::Cache::SafeRedisRaceCondition do
  before do
    skip unless Canvas.redis_enabled?
  end

  let(:store) do
    Class.new(ActiveSupport::Cache::RedisCacheStore) do
      include ActiveSupport::Cache::SafeRedisRaceCondition
      def self.name
        "TestCache"
      end
    end.new(url: Canvas.redis.id, expires_in: 5.minutes.to_i, race_condition_ttl: 7.days.to_i)
  end

  describe "#fetch" do
    it "locks for a new key" do
      expect(store).to receive(:read_entry).and_return(nil)
      expect(store).to receive(:lock).and_return("nonce")
      expect(store).to receive(:write_entry)
      expect(store).to receive(:unlock)
      expect(store.fetch("bob") { 42 }).to eq 42
    end

    it "doesn't lock for an existing key" do
      store.write("bob", 42)
      expect(store).not_to receive(:lock)
      expect(store).not_to receive(:unlock)
      expect(store.fetch("bob") { raise "not reached" }).to eq 42
    end

    it "doesn't populate for a stale key that someone else is populating" do
      store.write("bob", 42, expires_in: 0)
      expect(store).to receive(:lock).and_return(false)
      expect(store).not_to receive(:unlock)

      Timecop.travel(1.second) do
        expect(store.fetch("bob") { raise "not reached" }).to eq 42
      end
    end

    it "waits to get a lock for a non-existent key" do
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return(false).ordered
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return("nonce").ordered
      expect(store).to receive(:write_entry)
      expect(store).to receive(:unlock)
      expect(store.fetch("bob") { 42 }).to eq 42
    end

    it "waits and then reads fresh data for a non-existent key" do
      store.write("bob", 42)
      expect(store).to receive(:read_entry).and_return(nil).ordered
      expect(store).to receive(:lock).and_return(false).ordered
      expect(store).to receive(:read_entry).and_call_original.ordered
      expect(store).not_to receive(:unlock)
      expect(store.fetch("bob") { raise "not reached" }).to eq 42
    end

    it "returns stale data if there is an exception calculating new data" do
      store.write("bob", 42, expires_in: 1)
      Timecop.travel(5) do
        exception = RuntimeError.new("die")
        expect(Canvas::Errors).to receive(:capture).with(exception)
        expect(store.fetch("bob") { raise exception }).to eq 42
      end
    end

    it "doesn't return bogus stale data if there is an exception calculating new data" do
      store.write("adam", 42, expires_in: 1)
      Timecop.travel(5) do
        exception = RuntimeError.new("die")
        expect(Canvas::Errors).to receive(:capture).with(exception)
        expect(store.fetch("adam") { raise exception }).to eq 42
        expect { store.fetch("jill") { raise exception } }.to raise_error exception
      end
    end

    it "calculates anyway if we couldn't contact the cache" do
      expect(store).to receive(:read_entry).and_return(nil)
      expect(store).to receive(:lock).and_return(true)
      expect(store).to receive(:write_entry)
      expect(store).not_to receive(:unlock)
      expect(store.fetch("bob") { 42 }).to eq 42
    end
  end
end
# rubocop:enable Style/RedundantFetchBlock
