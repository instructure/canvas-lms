# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe TempCache do
  before do
    # Reset all class-level state so tests are independent of execution order
    TempCache.instance_variable_set(:@enabled, nil)
    TempCache.clear
  end

  describe ".enable" do
    it "yields the block" do
      called = false
      TempCache.enable { called = true }
      expect(called).to be true
    end

    it "enables caching within the block" do
      calls = 0
      TempCache.enable do
        2.times { TempCache.cache("k") { calls += 1 } }
      end
      expect(calls).to eq 1
    end

    it "clears the cache after the block exits" do
      TempCache.enable { TempCache.cache("k") { 1 } }
      TempCache.enable do
        expect(TempCache.exist?("k")).to be false
      end
    end

    it "clears the cache even when the block raises" do
      expect { TempCache.enable { raise "boom" } }.to raise_error("boom")
      TempCache.enable do
        expect(TempCache.exist?("k")).to be false
      end
    end

    it "is a no-op re-entrant — nested enable just yields without resetting" do
      calls = 0
      TempCache.enable do
        TempCache.cache("k") { calls += 1 }
        TempCache.enable do
          TempCache.cache("k") { calls += 1 } # should hit cache, not increment
        end
      end
      expect(calls).to eq 1
    end

    it "returns the value of the block" do
      result = TempCache.enable { 42 }
      expect(result).to eq 42
    end
  end

  describe ".clear" do
    it "resets cached entries" do
      TempCache.enable do
        TempCache.cache("k") { 1 }
        TempCache.clear
        expect(TempCache.exist?("k")).to be false
      end
    end

    it "allows re-computation after clearing" do
      calls = 0
      TempCache.enable do
        TempCache.cache("k") { calls += 1 }
        TempCache.clear
        TempCache.cache("k") { calls += 1 }
      end
      expect(calls).to eq 2
    end
  end

  describe ".create_key" do
    it "joins string arguments with /" do
      expect(TempCache.create_key("a", "b", "c")).to eq "a/b/c"
    end

    it "converts non-string scalars via to_s" do
      expect(TempCache.create_key(1, :sym)).to eq "1/sym"
    end

    it "flattens nested arrays recursively" do
      expect(TempCache.create_key("ns", ["a", "b"])).to eq "ns/a/b"
    end

    it "uses global_asset_string for ActiveRecord objects" do
      user = User.new
      allow(user).to receive(:global_asset_string).and_return("user_42")
      expect(TempCache.create_key(user)).to eq "user_42"
    end
  end

  describe ".cache" do
    context "when disabled" do
      it "always calls the block" do
        calls = 0
        2.times { TempCache.cache("k") { calls += 1 } }
        expect(calls).to eq 2
      end

      it "returns the block value" do
        expect(TempCache.cache("k") { 99 }).to eq 99
      end
    end

    context "when enabled" do
      it "calls the block only once for the same key" do
        calls = 0
        TempCache.enable do
          2.times { TempCache.cache("k") { calls += 1 } }
        end
        expect(calls).to eq 1
      end

      it "returns the cached value on the second call" do
        TempCache.enable do
          TempCache.cache("k") { 1 }
          expect(TempCache.cache("k") { 2 }).to eq 1
        end
      end

      it "stores nil as a valid cached value" do
        calls = 0
        TempCache.enable do
          2.times do
            TempCache.cache("k") do
              calls += 1
              nil
            end
          end
        end
        expect(calls).to eq 1
      end

      it "isolates keys from each other" do
        TempCache.enable do
          TempCache.cache("a") { 1 }
          expect(TempCache.cache("b") { 2 }).to eq 2
        end
      end

      it "builds the key from multiple arguments" do
        TempCache.enable do
          TempCache.cache("ns", "id") { 7 }
          expect(TempCache.cache("ns", "id") { 8 }).to eq 7
          expect(TempCache.cache("ns", "other") { 9 }).to eq 9
        end
      end
    end
  end

  describe ".exist?" do
    it "returns false when the cache is not enabled" do
      TempCache.cache("k") { "value" }
      expect(TempCache.exist?("k")).to be false
    end

    it "returns false for a key that has not been cached" do
      TempCache.enable do
        expect(TempCache.exist?("missing")).to be false
      end
    end

    it "returns true for a key that has been cached" do
      TempCache.enable do
        TempCache.cache("k") { "value" }
        expect(TempCache.exist?("k")).to be true
      end
    end

    it "returns false after the enable block exits" do
      TempCache.enable { TempCache.cache("k") { 1 } }
      expect(TempCache.exist?("k")).to be false
    end

    it "uses the same composite key as .cache" do
      TempCache.enable do
        TempCache.cache("ns", "a", "b") { 42 }
        expect(TempCache.exist?("ns", "a", "b")).to be true
        expect(TempCache.exist?("ns", "a")).to be false
      end
    end
  end
end
