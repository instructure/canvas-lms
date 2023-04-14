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

require "canvas_cassandra"
require "spec_helper"

describe EventStream::Stream do
  let(:database) do
    database = double("database")
    def database.batch
      yield
    end

    def database.update_record(*); end

    def database.insert_record(*); end

    def database.update(*); end

    def database.available?
      true
    end

    def database.keyspace
      "test_db"
    end
    database
  end

  context "setup block" do
    before do
      double(to_s: double("table"))
    end

    it "sets values as expected" do
      # can't access spec ivars inside instance_exec
      database, table = self.database, @table
      id_column = double(to_s: double("id_column"))
      record_type = double("record_type")

      stream = EventStream::Stream.new do
        backend_strategy :cassandra
        self.database database
        self.table table
        self.id_column id_column
        self.record_type record_type
        read_consistency_level "ALL"
      end

      expect(stream.database).to eq database
      expect(stream.database_name).to eq database.keyspace
      expect(stream.table).to eq table.to_s
      expect(stream.id_column).to eq id_column.to_s
      expect(stream.record_type).to eq record_type
      expect(stream.read_consistency_level).to eq "ALL"
    end

    it "requires database_name and table" do
      # can't access spec ivars inside instance_exec
      database, table = self.database, @table

      expect do
        EventStream::Stream.new(database) { self.database database }
      end.to raise_exception ArgumentError

      expect do
        EventStream::Stream.new(database) { self.table table }
      end.to raise_exception ArgumentError
    end

    context "defaults" do
      before do
        # can't access spec ivars inside instance_exec
        database, table = self.database, @table
        @stream = EventStream::Stream.new do
          backend_strategy :cassandra
          self.database database
          self.table table
        end
      end

      it "defaults read_consistancy_level to nil" do
        expect(@stream.read_consistency_level).to be_nil
      end

      it "defaults id_column to 'id'" do
        expect(@stream.id_column).to eq "id"
      end

      it "defaults record_type to EventStream::Record" do
        expect(@stream.record_type).to eq EventStream::Record
      end
    end
  end

  context "#available?" do
    it "returns true when available and configured" do
      # can't access spec ivars inside instance_exec
      database, table = self.database, @table
      id_column = double(to_s: double("id_column"))
      record_type = double("record_type")

      stream = EventStream::Stream.new do
        backend_strategy :cassandra
        self.database -> { database }
        self.table table
        self.id_column id_column
        self.record_type record_type
        read_consistency_level "ALL"
      end

      expect(stream.database).to be database
      expect(stream.available?).to be true
    end

    it "returns false when not available" do
      # can't access spec ivars inside instance_exec
      database, table = self.database, @table
      allow(database).to receive(:available?).and_return(false)
      id_column = double(to_s: double("id_column"))
      record_type = double("record_type")

      stream = EventStream::Stream.new do
        backend_strategy :cassandra
        self.database database
        self.table table
        self.id_column id_column
        self.record_type record_type
        read_consistency_level "ALL"
      end

      expect(stream.database).to be database
      expect(stream.available?).to be false
    end

    it "returns false when not configured" do
      # can't access spec ivars inside instance_exec
      table = @table
      id_column = double(to_s: double("id_column"))
      record_type = double("record_type")

      stream = EventStream::Stream.new do
        backend_strategy :cassandra
        self.database -> {}
        self.table table
        self.id_column id_column
        self.record_type record_type
        read_consistency_level "ALL"
      end

      expect(stream.database).to be_nil
      expect(stream.available?).to be false
    end
  end

  describe ".database_name" do
    it "returns backend db name from AR" do
      # can't access spec ivars inside instance_exec
      table = @table
      id_column = double(to_s: double("id_column"))
      record_type = double("record_type")

      ar_type = Class.new do
        def self.connection
          self
        end

        def self.shard
          self
        end

        def self.name
          "active_record_db"
        end
      end

      stream = EventStream::Stream.new do
        backend_strategy -> { :active_record }
        self.database -> {}
        self.table table
        self.id_column id_column
        self.record_type record_type
        read_consistency_level "ALL"
        active_record_type ar_type
      end

      expect(stream.database_name).to eq("active_record_db")
    end
  end

  context "usage" do
    before do
      @table = double(to_s: "expected_table")
      database, table = self.database, @table
      @stream = EventStream::Stream.new do
        backend_strategy :cassandra
        self.database database
        self.table table
      end
    end

    describe "on_insert" do
      before do
        @record = double(id: double("id"), created_at: Time.now, attributes: double("attributes"))
      end

      it "registers callback for execution during insert" do
        spy = double("spy")
        @stream.on_insert { spy.trigger }
        expect(spy).to receive(:trigger).once
        @stream.insert(@record)
      end

      it "includes the record in the callback invocation" do
        spy = double("spy")
        @stream.on_insert { |record| spy.trigger(record) }
        expect(spy).to receive(:trigger).once.with(@record)
        @stream.insert(@record)
      end

      it "stacks multiple callbacks" do
        spy = double("spy")
        @stream.on_insert { spy.trigger1 }
        @stream.on_insert { spy.trigger2 }
        expect(spy).to receive(:trigger1).once
        expect(spy).to receive(:trigger2).once
        @stream.insert(@record)
      end
    end

    describe "current_backend" do
      it "changes at runtime with different setting" do
        strat_value = :cassandra
        stream = EventStream::Stream.new do
          backend_strategy -> { strat_value }
          self.table "table"
        end
        expect(stream.current_backend.class).to eq(EventStream::Backend::Cassandra)
        strat_value = :active_record
        expect(stream.current_backend.class).to eq(EventStream::Backend::ActiveRecord)
      end
    end

    describe "insert" do
      before do
        @timestamp = Time.now
        @record = double(id: double("id"), created_at: @timestamp, attributes: double("attributes"))
      end

      it "inserts into the configured database" do
        expect(database).to receive(:insert_record).once
        @stream.insert(@record)
      end

      it "inserts into the configured table" do
        expect(database).to receive(:insert_record).with(@table.to_s, anything, anything, anything)
        @stream.insert(@record)
      end

      it "inserts by the record's id into the configured id column" do
        id_column = double(to_s: double("id_column"))
        @stream.id_column id_column
        expect(database).to receive(:insert_record).with(anything, { id_column.to_s => @record.id }, anything, anything)
        @stream.insert(@record)
      end

      it "inserts the record's attributes" do
        expect(database).to receive(:insert_record).with(anything, anything, @record.attributes, anything)
        @stream.insert(@record)
      end

      it "sets the record's ttl" do
        expect(database).to receive(:insert_record).with(anything, anything, anything, @stream.ttl_seconds(@timestamp))
        @stream.insert(@record)
      end

      it "executes its commands in a batch" do
        spy = double("spy")
        @stream.on_insert { spy.trigger }
        expect(database).to receive(:batch).once
        expect(database).not_to receive(:insert_record)
        expect(spy).not_to receive(:trigger)
        @stream.insert(@record)
      end
    end

    describe "on_update" do
      before do
        @record = double(id: double("id"), created_at: Time.now, changes: double("changes"))
      end

      it "registers callback for execution during update" do
        spy = double("spy")
        @stream.on_update { spy.trigger }
        expect(spy).to receive(:trigger).once
        @stream.update(@record)
      end

      it "includes the record in the callback invocation" do
        spy = double("spy")
        @stream.on_update { |record| spy.trigger(record) }
        expect(spy).to receive(:trigger).once.with(@record)
        @stream.update(@record)
      end

      it "stacks multiple callbacks" do
        spy = double("spy")
        @stream.on_update { spy.trigger1 }
        @stream.on_update { spy.trigger2 }
        expect(spy).to receive(:trigger1).once
        expect(spy).to receive(:trigger2).once
        @stream.update(@record)
      end
    end

    describe "update" do
      before do
        @timestamp = Time.now
        @record = double(id: double("id"), created_at: @timestamp, changes: double("changes"))
      end

      it "updates in the configured database" do
        expect(database).to receive(:update_record).once
        @stream.update(@record)
      end

      it "updates in the configured table" do
        expect(database).to receive(:update_record).with(@table.to_s, anything, anything, anything)
        @stream.update(@record)
      end

      it "updates by the record's id in the configured id column" do
        id_column = double(to_s: double("id_column"))
        @stream.id_column id_column
        expect(database).to receive(:update_record).with(anything, { id_column.to_s => @record.id }, anything, anything)
        @stream.update(@record)
      end

      it "updates the record's changes" do
        expect(database).to receive(:update_record).with(anything, anything, @record.changes, anything)
        @stream.update(@record)
      end

      it "sets the record's ttl" do
        expect(database).to receive(:update_record).with(anything, anything, anything, @stream.ttl_seconds(@timestamp))
        @stream.update(@record)
      end

      it "executes its commands in a batch" do
        spy = double("spy")
        @stream.on_update { spy.trigger }
        expect(database).to receive(:batch).once
        expect(database).not_to receive(:update_record)
        expect(spy).not_to receive(:trigger)
        @stream.update(@record)
      end
    end

    describe "fetch" do
      before do
        @results = double(fetch: nil)
      end

      it "uses the configured database" do
        expect(database).to receive(:execute).once.and_return(@results)
        @stream.fetch([1])
      end

      it "uses the configured table" do
        expect(database).to receive(:execute).once.with(/ FROM #{@table} /, anything, anything).and_return(@results)
        @stream.fetch([1])
      end

      it "uses the configured id column" do
        id_column = double(to_s: "expected_id_column")
        @stream.id_column id_column
        expect(database).to receive(:execute).once.with(/ WHERE #{id_column}/, anything, anything).and_return(@results)
        @stream.fetch([1])
      end

      it "passes the given ids to the execute" do
        ids = double("ids", empty?: false)
        expect(database).to receive(:execute).once.with(anything, ids, anything).and_return(@results)
        @stream.fetch(ids)
      end

      it "maps the returned rows to the configured record type" do
        record_type = double("record_type")
        raw_result = double("raw_result")
        cql_result = double("cql_result", to_hash: raw_result)
        typed_result = double("typed_result")
        expect(record_type).to receive(:from_attributes).with(raw_result).and_return(typed_result)

        @stream.record_type record_type
        expect(@results).to receive(:fetch).and_yield(cql_result)
        expect(database).to receive(:execute).once.and_return(@results)
        results = @stream.fetch([1])
        expect(results).to eq [typed_result]
      end

      it "skips the fetch if no ids were given" do
        expect(database).not_to receive(:execute)
        @stream.fetch([])
      end

      it "uses the configured consistency level" do
        expect(database).to receive(:execute).once.with(/%CONSISTENCY% WHERE/, anything, consistency: nil).and_return(@results)
        @stream.fetch([1])

        @stream.reset_backend!
        @stream.read_consistency_level "ALL"
        expect(database).to receive(:execute).once.with(/%CONSISTENCY% WHERE/, anything, consistency: "ALL").and_return(@results)
        @stream.fetch([1])
      end

      it "can fetch batch one-by-one" do
        expect(database).to receive(:execute).exactly(3).times.and_return(@results)
        @stream.fetch(%w[asdf sdfg dfgh], strategy: :serial)
      end
    end

    describe "add_index" do
      before do
        @table = double("table")
        table = @table
        @index = @stream.add_index :thing do
          self.table table
          entry_proc ->(record) { record.entry }
        end
        @index_strategy = @index.strategy_for(:cassandra)

        @key = double("key")
        @entry = double("entry", key: @key)
      end

      describe "generated on_insert callback" do
        before do
          @record = double(
            id: double("id"),
            created_at: Time.now,
            attributes: double("attributes"),
            changes: double("changes"),
            entry: @entry
          )
        end

        it "inserts the provided record into the index" do
          expect(@index_strategy).to receive(:insert).once.with(@record, anything)
          @stream.insert(@record)
        end

        it "translates the record through the entry_proc for the key" do
          expect(@index_strategy).to receive(:insert).once.with(anything, @entry)
          @stream.insert(@record)
        end

        it "skips insert if entry_proc and_return nil" do
          @index.entry_proc ->(_record) {}
          expect(@index_strategy).not_to receive(:insert)
          @stream.insert(@record)
        end

        it "translates the result of the entry_proc through the key_proc if present" do
          @index.key_proc ->(entry) { entry.key }
          expect(@index_strategy).to receive(:insert).once.with(anything, @key)
          @stream.insert(@record)
        end

        it "does not index in cassandra if a backend override is supplied" do
          expect(@index_strategy).to_not receive(:insert)
          @stream.insert(@record, backend_strategy: :active_record)
        end
      end

      describe "generated for_thing method" do
        it "forwards argument to index's find_with" do
          expect(@index).to receive(:find_with).once.with([@entry], { strategy: :cassandra })
          @stream.for_thing(@entry)
        end
      end
    end

    describe "failure" do
      before do
        @database = double("database")
        def @database.available?
          true
        end
        allow(@stream).to receive(:database).and_return(@database)
        @record = double(
          id: "id",
          created_at: Time.zone.now,
          attributes: { "attribute" => "attribute_value" },
          changes: { "changed_attribute" => "changed_value" }
        )
        @exception = StandardError.new
      end

      shared_examples_for "error callbacks" do
        it "triggers callbacks on failed inserts" do
          spy = double("spy")
          @stream.on_error { |*args| spy.capture(*args) }
          expect(spy).to receive(:capture).once.with(:insert, @record, @exception)
          @stream.insert(@record)
        end

        it "triggers callbacks on failed updates" do
          spy = double("spy")
          @stream.on_error { |*args| spy.capture(*args) }
          expect(spy).to receive(:capture).once.with(:update, @record, @exception)
          @stream.update(@record)
        end

        it "raises error if raises_on_error is true, but still calls callbacks" do
          spy = double("spy")
          @stream.raise_on_error = true
          @stream.on_error { spy.trigger }
          expect(spy).to receive(:trigger).once
          expect { @stream.insert(@record) }.to raise_exception(StandardError)
        end
      end

      context "failing database" do
        before do
          allow(@database).to receive(:batch).and_raise(@exception)
        end

        include_examples "error callbacks"
      end

      context "failing callbacks" do
        before do
          allow(@database).to receive(:batch).and_yield
          allow(@database).to receive(:insert_record)
          allow(@database).to receive(:update_record)
          allow(@database).to receive(:keyspace)

          exception = @exception
          @stream.on_insert { raise exception }
          @stream.on_update { raise exception }
        end

        it "does not insert a record when insert callback fails" do
          expect(@database).not_to receive(:execute)
          @stream.insert(@record)
        end

        it "does not update a record when update callback fails" do
          expect(@database).not_to receive(:execute)
          @stream.update(@record)
        end

        include_examples "error callbacks"
      end
    end
  end
end
