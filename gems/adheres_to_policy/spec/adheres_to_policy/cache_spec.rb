#
# Copyright (C) 2014 Instructure, Inc.
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
# You have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'spec_helper'

describe AdheresToPolicy::Cache do
  def cached
    AdheresToPolicy::Cache.instance_variable_get(:@cache)
  end

  context "#fetch" do
    it "tries to read the key value" do
      AdheresToPolicy::Cache.write(:key, 'value')
      expect(AdheresToPolicy::Cache).to_not receive(:write)
      value = AdheresToPolicy::Cache.fetch(:key){ 'new_value' }
      expect(value).to eq 'value'
    end

    it "writes the key and value if it was not read" do
      expect(AdheresToPolicy::Cache).to receive(:write).with(:key, 'value')
      value = AdheresToPolicy::Cache.fetch(:key){ 'value' }
      expect(value).to eq 'value'
    end
  end

  context "#write" do
    it "writes a value to the key provided" do
      expect(Rails.cache).to receive(:write).with(:key, 'value', anything).and_return('value')
      AdheresToPolicy::Cache.write(:key, 'value')
      expect(cached).to eq({ :key => 'value' })
    end
  end

  context "#read" do
    before do
      AdheresToPolicy::Cache.write(:key, 'value')
    end

    it "reads the provided key" do
      expect(AdheresToPolicy::Cache.read(:key)).to eq 'value'
    end

    it "returns nil if the key does not exist" do
      expect(Rails.cache).to receive(:read).with(:key2)
      expect(AdheresToPolicy::Cache.read(:key2)).to eq nil
    end
  end

  context "#clear" do
    before do
      AdheresToPolicy::Cache.write(:key1, 'value1')
      AdheresToPolicy::Cache.write(:key2, 'value2')
    end

    it "clears all the cached objects" do
      AdheresToPolicy::Cache.clear
      expect(cached).to eq nil
    end

    it "clears only the key provided" do
      AdheresToPolicy::Cache.clear(:key1)
      expect(cached).to eq({ :key2 => 'value2' })
    end
  end
end