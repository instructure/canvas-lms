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

describe EventStream::Stream do
  subject(:stream) do
    # can't access spec methods from the instance_eval block
    record_type = self.record_type
    EventStream::Stream.new { self.record_type record_type }
  end

  let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::AbstractAdapter, active?: true) }
  let(:record_type) { double("record_type", connection:, create_from_event_stream!: nil, update_from_event_stream!: nil) } # rubocop:disable RSpec/VerifiedDoubles
  let(:created_at) { Time.zone.now }
  let(:record_class) do
    Class.new do
      include ActiveModel::Attributes

      attr :id
      attr :created_at
    end
  end
  let(:record) { double(record_class, id: "id", created_at:, attributes: {}) } # rubocop:disable RSpec/VerifiedDoubles

  context "setup block" do
    it "sets values as expected" do
      expect(stream.record_type).to be record_type
    end
  end

  describe "#available?" do
    it "returns true when available and configured" do
      expect(stream.available?).to be true
    end

    it "returns false when not available" do
      allow(connection).to receive(:active?).and_return(false)

      expect(stream.available?).to be false
    end
  end

  describe ".database_name" do
    it "returns backend db name from AR" do
      allow(record_type).to receive_messages(
        connection: record_type,
        shard: record_type,
        name: "active_record_db"
      )

      expect(stream.database_name).to eq("active_record_db")
    end
  end

  context "usage" do
    describe "on_insert" do
      it "registers callback for execution during insert" do
        triggered = 0
        stream.on_insert { triggered += 1 }
        stream.insert(record)
        expect(triggered).to be 1
      end

      it "includes the record in the callback invocation" do
        captured_record = nil
        stream.on_insert { |record| captured_record = record }
        stream.insert(record)
        expect(captured_record).to eq(record)
      end

      it "stacks multiple callbacks" do
        triggered1 = 0
        triggered2 = 0
        stream.on_insert { triggered1 += 1 }
        stream.on_insert { triggered2 += 1 }
        stream.insert(record)
        expect(triggered1).to be 1
        expect(triggered2).to be 1
      end
    end

    describe "insert" do
      it "inserts into the configured model" do
        expect(record_type).to receive(:create_from_event_stream!).with(record).once
        stream.insert(record)
      end
    end

    describe "on_update" do
      it "registers callback for execution during update" do
        triggered = 0
        stream.on_update { triggered += 1 }
        stream.update(record)
        expect(triggered).to be 1
      end

      it "includes the record in the callback invocation" do
        captured_record = nil
        stream.on_update { |r| captured_record = r }
        stream.update(record)
        expect(captured_record).to eq(record)
      end

      it "stacks multiple callbacks" do
        triggered1 = 0
        triggered2 = 0
        stream.on_update { triggered1 += 1 }
        stream.on_update { triggered2 += 1 }
        stream.update(record)
        expect(triggered1).to be 1
        expect(triggered2).to be 1
      end
    end

    describe "update" do
      it "updates in the configured model" do
        expect(record_type).to receive(:update_from_event_stream!).with(record).once
        stream.update(record)
      end
    end

    describe "fetch" do
      it "uses the configured model" do
        expect(record_type).to receive(:where).with(uuid: [1]).once.and_return([])
        stream.fetch([1])
      end
    end

    describe "add_index" do
      let(:index) { stream.add_index :thing }

      describe "generated for_thing method" do
        it "forwards argument to index's find_with" do
          entry = Object.new
          expect(index).to receive(:find_with).once.with([entry], {})
          stream.for_thing(entry)
        end
      end
    end

    describe "failure" do
      let(:exception) { StandardError.new }

      shared_examples_for "error callbacks" do
        it "triggers callbacks on failed inserts" do
          spy = double("spy") # rubocop:disable RSpec/VerifiedDoubles
          stream.on_error { |*args| spy.capture(*args) }
          expect(spy).to receive(:capture).with(:insert, record, exception)
          stream.insert(record)
        end

        it "triggers callbacks on failed updates" do
          spy = double("spy") # rubocop:disable RSpec/VerifiedDoubles
          stream.on_error { |*args| spy.capture(*args) }
          expect(spy).to receive(:capture).once.with(:update, record, exception)
          stream.update(record)
        end

        it "raises error if raises_on_error is true, but still calls callbacks" do
          spy = double("spy") # rubocop:disable RSpec/VerifiedDoubles
          stream.raise_on_error = true
          stream.on_error { spy.trigger }
          expect(spy).to receive(:trigger).once
          expect { stream.insert(record) }.to raise_exception(StandardError)
        end
      end

      context "failing database" do
        before do
          allow(record_type).to receive(:create_from_event_stream!).and_raise(exception)
          allow(record_type).to receive(:update_from_event_stream!).and_raise(exception)
        end

        it_behaves_like "error callbacks"
      end

      context "failing callbacks" do
        before do
          exception = self.exception
          stream.on_insert { raise exception }
          stream.on_update { raise exception }
        end

        it_behaves_like "error callbacks"
      end
    end
  end
end
