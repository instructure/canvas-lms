# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

describe Utils::HashUtils do
  describe "#sort_nested_hash" do
    it "sorts differently ordered hashes to be equal" do
      hash1 = {
        "a" => "1",
        "b" => ["1"],
        "@a" => "2",
        "@b" => "2"
      }
      hash2 = {
        "@b" => "2",
        "a" => "1",
        "@a" => "2",
        "b" => ["1"],
      }
      expect(Utils::HashUtils.sort_nested_data(hash1)).to eq(Utils::HashUtils.sort_nested_data(hash2))
    end

    it "sorts nested hash data" do
      hash1 = {
        "a" => "1",
        "b" => {
          "a" => {
            "b" => "2",
            "a" => "1"
          },
          "b" => "2"
        }
      }
      hash2 = {
        "a" => "1",
        "b" => {
          "b" => "2",
          "a" => {
            "a" => "1",
            "b" => "2"
          }
        }
      }
      expect(Utils::HashUtils.sort_nested_data(hash1)).to eq(Utils::HashUtils.sort_nested_data(hash2))
    end

    it "sorts arrays inside hashes" do
      hash1 = {
        "a" => %w[3 4 2 1]
      }
      hash2 = {
        "a" => %w[1 3 2 4]
      }
      expect(Utils::HashUtils.sort_nested_data(hash1)).to eq(Utils::HashUtils.sort_nested_data(hash2))
    end

    it "sorts an array of hashes to be equal" do
      array1 = [
        {
          "c" => "3",
          "e" => "5"
        },
        {
          "b" => "2",
          "a" => "1"
        },
        {
          "d" => "4",
          "f" => "6"
        }
      ]
      array2 = [
        {
          "f" => "6",
          "d" => "4"
        },
        {
          "a" => "1",
          "b" => "2"
        },
        {
          "e" => "5",
          "c" => "3"
        }
      ]
      expect(Utils::HashUtils.sort_nested_data(array1)).to eq(Utils::HashUtils.sort_nested_data(array2))
    end

    it "doesn't fail on non-string key/values" do
      hash1 = {
        :a => [true, false, 1, :a, false],
        "b" => {
          c: [],
          d: {},
          e: "",
          f: "!",
          g: :a1
        }
      }
      hash2 = {
        :b => {
          g: :a1,
          e: "",
          c: [],
          f: "!",
          d: {}
        },
        "a" => [false, 1, false, :a, true]
      }
      expect(Utils::HashUtils.sort_nested_data(hash1)).to eq(Utils::HashUtils.sort_nested_data(hash2))
    end

    it "can sort nested keys" do
      hash1 = {
        [1, 2, 3] => 1,
        [2, 3, 4] => 2
      }
      hash2 = {
        [2, 3, 4] => 2,
        [1, 2, 3] => 1
      }
      expect(Utils::HashUtils.sort_nested_data(hash1)).to eq(Utils::HashUtils.sort_nested_data(hash2))
    end
  end

  describe "#nested_compact" do
    subject { Utils::HashUtils.nested_compact(hash) }

    context "with simple hash" do
      let(:hash) { { a: 1, b: 2, c: nil } }

      it "compacts hash" do
        expect(subject).to eq({ a: 1, b: 2 })
      end
    end

    context "with array of hashes" do
      let(:hash) { [{ a: 1, b: 2, c: nil }, { d: 3, e: nil }] }

      it "compacts inner hashes" do
        expect(subject).to eq([{ a: 1, b: 2 }, { d: 3 }])
      end
    end

    context "with nested hash" do
      let(:hash) { { a: 1, b: { c: 2, d: nil } } }

      it "compacts nested hash" do
        expect(subject).to eq({ a: 1, b: { c: 2 } })
      end
    end

    context "with hash containing array of hashes" do
      let(:hash) { { a: 1, b: [{ c: 2, d: nil }, { e: 3, f: nil }] } }

      it "compacts inner hashes" do
        expect(subject).to eq({ a: 1, b: [{ c: 2 }, { e: 3 }] })
      end
    end

    context "with complex nested hash" do
      let(:hash) do
        { a: 1, b: { c: 2, d: nil, e: [{ f: 3, g: nil, h: [{ i: 4, j: nil }] }] } }
      end

      it "compacts all hashes" do
        expect(subject).to eq({ a: 1, b: { c: 2, e: [{ f: 3, h: [{ i: 4 }] }] } })
      end
    end
  end
end
