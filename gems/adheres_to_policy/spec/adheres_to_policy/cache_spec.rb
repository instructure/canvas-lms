# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"

# rubocop:disable Style/RedundantFetchBlock it's a cache, not a Hash
describe AdheresToPolicy::Cache do
  def cached
    AdheresToPolicy::Cache.instance_variable_get(:@cache)
  end

  context "#fetch" do
    it "tries to read the key value" do
      AdheresToPolicy::Cache.write(:key, "value")
      expect(AdheresToPolicy::Cache).to_not receive(:write)
      value = AdheresToPolicy::Cache.fetch(:key) { "new_value" }
      expect(value).to eq ["value", :in_proc]
    end

    it "writes the key and value if it was not read" do
      expect(AdheresToPolicy::Cache).to receive(:write).with(:key, "value", an_instance_of(Hash))
      value = AdheresToPolicy::Cache.fetch(:key) { "value" }
      expect(value).to eq ["value", :generated]
    end

    it "does not write the key if the value is 'false'" do
      AdheresToPolicy::Cache.write(:key, false)
      expect(AdheresToPolicy::Cache).to_not receive(:write)
      value = AdheresToPolicy::Cache.fetch(:key) { "new_value" }
      expect(value).to eq [false, :in_proc]
    end

    it "times generating the value and sets Thread.current[:last_cache_generate]" do
      Thread.current[:last_cache_generate] = nil
      AdheresToPolicy::Cache.fetch(:key) { "new_value" }
      expect(Thread.current[:last_cache_generate]).to_not be_nil
    end

    it "must forward the value pased for use_rails_cache to .read and .write" do
      expect(AdheresToPolicy::Cache).to receive(:read)
        .with(an_instance_of(String), a_hash_including(use_rails_cache: false))
      expect(AdheresToPolicy::Cache).to receive(:write)
        .with(an_instance_of(String), an_instance_of(String), a_hash_including(use_rails_cache: false))

      AdheresToPolicy::Cache.fetch("foobar", use_rails_cache: false) { "new_value" }
    end
  end

  context "#write" do
    it "writes a value to the key provided" do
      expect(Rails.cache).to receive(:write).with(:key, "value", anything).and_return("value")
      AdheresToPolicy::Cache.write(:key, "value")
      expect(cached).to eq({ key: "value" })
    end

    it "must not write to the Rails cache when use_rails_cache is passed as false" do
      expect(Rails.cache).to_not receive(:write)
      AdheresToPolicy::Cache.write("foo", "bar", use_rails_cache: false)
    end
  end

  context "#read" do
    before do
      AdheresToPolicy::Cache.write(:key, "value")
    end

    it "reads the provided key" do
      expect(AdheresToPolicy::Cache.read(:key)).to eq ["value", :in_proc]
    end

    it "returns nil if the key does not exist" do
      expect(Rails.cache).to receive(:read).with(:key2)
      expect(AdheresToPolicy::Cache.read(:key2)).to eq [nil, :out_of_proc]
    end

    it "must not attempt to read from the rails cache when use_rails_cache is passed as false" do
      expect(Rails.cache).to_not receive(:read)
      expect(AdheresToPolicy::Cache.read(:key2, use_rails_cache: false)).to eq [nil, :out_of_proc]
    end
  end

  context "#clear" do
    before do
      AdheresToPolicy::Cache.write(:key1, "value1")
      AdheresToPolicy::Cache.write(:key2, "value2")
    end

    it "clears all the cached objects" do
      AdheresToPolicy::Cache.clear
      expect(cached).to be_nil
    end

    it "clears only the key provided" do
      AdheresToPolicy::Cache.clear(:key1)
      expect(cached).to eq({ key2: "value2" })
    end
  end
end
# rubocop:enable Style/RedundantFetchBlock
