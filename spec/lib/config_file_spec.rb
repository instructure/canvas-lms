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
#

require_relative '../spec_helper.rb'

describe ConfigFile do
  describe ".cache_object" do
    before { ConfigFile.unstub }

    it "caches objects" do
      expect(File).to receive(:exist?).and_return(true)
      expect(File).to receive(:read).and_return('test: {}')
      hit_block = 0
      result1 = ConfigFile.cache_object('my_config') do |config|
        hit_block += 1
        expect(config).to eq({})
        Object.new
      end
      expect(hit_block).to eq 1
      expect(result1.class).to eq Object
      result2 = ConfigFile.cache_object('my_config') do
        hit_block += 1
        Object.new
      end
      expect(hit_block).to eq 1
      expect(result2).to eq result1
    end

    it "caches YAML even if it has to load multiple objects" do
      expect(File).to receive(:exist?).once.and_return(true)
      expect(File).to receive(:read).once.and_return("test: a\nenv2: b")
      hit_block = 0
      result1 = ConfigFile.cache_object('my_config') do |config|
        hit_block += 1
        expect(config).to eq('a')
        Object.new
      end
      expect(hit_block).to eq 1
      expect(result1.class).to eq Object
      result2 = ConfigFile.cache_object('my_config', 'env2') do |config|
        hit_block += 1
        expect(config).to eq('b')
        Object.new
      end
      expect(hit_block).to eq 2
      expect(result2).not_to eq result1
      result3 = ConfigFile.cache_object('my_config', 'env3') do
        hit_block += 1
        Object.new
      end
      expect(hit_block).to eq 2
      expect(result3).to be_nil
    end
  end
end
