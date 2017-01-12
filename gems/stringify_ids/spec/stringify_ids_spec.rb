#
# Copyright (C) 2016 Instructure, Inc.
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

describe StringifyIds do
  describe '.recursively_stringify_ids' do
    it 'stringifies in a sub-hash' do
      input = { obj: { id: 1 } }
      StringifyIds.recursively_stringify_ids(input)
      expect(input[:obj][:id]).to eq "1"
    end

    it 'stringifies in a sub-array' do
      input = { objs: [{ id: 1 }] }
      StringifyIds.recursively_stringify_ids(input)
      expect(input[:objs][0][:id]).to eq "1"
    end

    it 'allows reversing' do
      input = { obj: { id: "1" } }
      StringifyIds.recursively_stringify_ids(input, reverse: true)
      expect(input[:obj][:id]).to eq 1
    end
  end

  describe '.stringify_ids' do
    it 'stringifies an "id" field' do
      input = { id: 1 }
      StringifyIds.stringify_ids(input)
      expect(input[:id]).to eq "1"
    end

    it 'stringifies a "something_id" field' do
      input = { something_id: 1 }
      StringifyIds.stringify_ids(input)
      expect(input[:something_id]).to eq "1"
    end

    it 'stringifies a "something_ids" array field' do
      input = { something_ids: [1, 2, 3] }
      StringifyIds.stringify_ids(input)
      expect(input[:something_ids]).to eq ["1", "2", "3"]
    end

    it 'allows reversing' do
      input = { id: "1" }
      StringifyIds.stringify_ids(input, reverse: true)
      expect(input[:id]).to eq 1
    end
  end

  describe '.stringify_id' do
    it 'converts an int to a string' do
      expect(StringifyIds.stringify_id(1)).to eq "1"
    end

    it 'passes a non-int through' do
      expect(StringifyIds.stringify_id(1.0)).to eq 1.0
    end

    it 'converts a string to an int with reverse specified' do
      expect(StringifyIds.stringify_id("1", reverse: true)).to eq 1
    end

    it 'passes a non-string through with reverse specified' do
      expect(StringifyIds.stringify_id(1.0, reverse: true)).to eq 1.0
    end
  end
end
