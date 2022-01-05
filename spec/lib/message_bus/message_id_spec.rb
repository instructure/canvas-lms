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

describe MessageBus::MessageId do
  describe "parsing and serializing" do
    it "chokes on malformed data" do
      expect { MessageBus::MessageId.from_string("not-a-message-id") }.to raise_error(ArgumentError)
    end

    it "correctly slots each ID value" do
      mid = MessageBus::MessageId.from_string("(2802,0,-1,0)")
      expect(mid.ledger_id).to eq(2802)
      expect(mid.entry_id).to eq(0)
      expect(mid.partition_id).to eq(-1)
      expect(mid.batch_index).to eq(0)
    end

    it "doesn't re-parse a previously parsed message id" do
      mid = MessageBus::MessageId.from_string("(2800,1,-1,0)")
      mid2 = MessageBus::MessageId.from_string(mid)
      mid3 = MessageBus::MessageId.from_string(mid2)
      expect(mid3.ledger_id).to eq(2800)
      expect(mid3.entry_id).to eq(1)
      expect(mid3.partition_id).to eq(-1)
      expect(mid3.batch_index).to eq(0)
    end

    it "can also parse hash representations" do
      input = { ledger_id: 1234, entry_id: 2, partition_id: -1, batch_index: 0 }
      mid = MessageBus::MessageId.from_hash(input)
      expect(mid.ledger_id).to eq(1234)
      expect(mid.entry_id).to eq(2)
      expect(mid.partition_id).to eq(-1)
      expect(mid.batch_index).to eq(0)
    end

    it "re-formats to string or hash safely" do
      mid = MessageBus::MessageId.from_string("(2820,3,-1,0)")
      expect(mid.to_s).to eq("(2820,3,-1,0)")
      expect(mid.to_h[:entry_id]).to eq(3)
    end
  end

  describe "comparable interface" do
    it "orders co-partition ids by ledger" do
      mid1 = MessageBus::MessageId.from_string("(2820,13,-1,0)")
      mid2 = MessageBus::MessageId.from_string("(2819,20,-1,0)")
      mid3 = MessageBus::MessageId.from_string("(2821,6,-1,0)")
      expect(mid1).to be > mid2
      expect(mid3).to be > mid2
      expect(mid3).to be > mid1
    end

    it "orders co-ledger ids by entry id" do
      mid1 = MessageBus::MessageId.from_string("(140,13,-1,4)")
      mid2 = MessageBus::MessageId.from_string("(140,20,-1,7)")
      mid3 = MessageBus::MessageId.from_string("(140,6,-1,9)")
      expect(mid1).to be < mid2
      expect(mid3).to be < mid2
      expect(mid3).to be < mid1
    end

    it "orders co-entry ids by batch index" do
      mid1 = MessageBus::MessageId.from_string("(140,13,-1,4)")
      mid2 = MessageBus::MessageId.from_string("(140,13,-1,7)")
      mid3 = MessageBus::MessageId.from_string("(140,13,-1,9)")
      expect(mid1).to be < mid2
      expect(mid3).to be > mid2
      expect(mid3).to be > mid1
    end

    it "recognizes equality" do
      mid1 = MessageBus::MessageId.from_string("(140,13,-1,0)")
      mid2 = MessageBus::MessageId.from_string("(140,13,-1,0)")
      mid3 = MessageBus::MessageId.from_string("(140,13,-1,0)")
      expect(mid1).to_not be < mid2
      expect(mid3).to_not be > mid2
      expect(mid3).to_not be > mid1
      expect(mid1).to be == mid2
      expect(mid3).to be == mid2
      expect(mid3).to be == mid1
    end

    it "only compares ids from the same partition" do
      mid1 = MessageBus::MessageId.from_string("(140,13,3,0)")
      mid2 = MessageBus::MessageId.from_string("(140,13,2,0)")
      expect { mid1 > mid2 }.to raise_error(ArgumentError)
    end
  end
end
