# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

require 'spec_helper'

describe ConfigFile do
  describe ".cache_object" do
    before(:each) do
      ConfigFile.unstub
      target_location = Pathname.new(File.join(File.dirname(__FILE__), 'fixtures'))
      allow(Rails).to receive(:root).and_return(target_location)
    end

    after(:each) do
      ConfigFile.unstub
    end

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

    it "does not give you the ability to mess with the cached data" do
      ConfigFile.load("database", "test")
      v2 = ConfigFile.load("database", "test")
      expect { v2['foo'] = 'bar' }.to raise_error(RuntimeError)
    end

    describe "deep freezing" do
      it "can deep freeze arrays" do
        array = ["asdf","sdfg","dfgh","fghj"]
        out = ConfigFile.deep_freeze_cached_value(array)
        expect(out).to be_frozen
        expect(out.class).to eq(Array)
        expect(out[0]).to eq("asdf")
        expect(out[0]).to be_frozen
      end

      it "can deep freeze hashes" do
        hash = { "asdf" => "sdfg","dfgh" => "fghj" }
        out = ConfigFile.deep_freeze_cached_value(hash)
        expect(out).to be_frozen
        expect(out.class).to eq(Hash)
        expect(out["asdf"]).to be_frozen
        expect(out["asdf"]).to eq("sdfg")
      end

      it "handles integers ok" do
        array = [1,2,3,4]
        out = ConfigFile.deep_freeze_cached_value(array)
        expect(out).to be_frozen
        expect(out.class).to eq(Array)
        expect(out[0]).to eq(1)
        expect(out[0]).to be_frozen
      end
    end
  end
end
