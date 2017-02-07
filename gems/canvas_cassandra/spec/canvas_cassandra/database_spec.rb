#
# Copyright (C) 2012 Instructure, Inc.
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

describe CanvasCassandra do
  let(:conn) { double() }

  let(:db) do
    CanvasCassandra::Database.allocate.tap do |db|
      db.send(:instance_variable_set, :@db, conn)
      db.send(:instance_variable_set, :@logger, double().as_null_object)
      allow(db).to receive(:sanitize).and_return("")
    end
  end

  describe "#execute" do
    # I'm using %CONSISTENCY% as a query parameter here to make sure that the
    # execute code doesn't accidentally replace the string in those params
    def run_query(consistency)
      db.execute("SELECT a %CONSISTENCY% WHERE a = ?", "%CONSISTENCY%", consistency: consistency)
    end

    describe "cql3" do
      before do
        allow(conn).to receive(:use_cql3?).and_return(true)
      end

      it "passes the consistency level as a param" do
        expect(conn).to receive(:execute_with_consistency).with("SELECT a WHERE a = ?", CassandraCQL::Thrift::ConsistencyLevel::ONE, "%CONSISTENCY%")
        run_query('ONE')
      end

      it "ignores a nil consistency" do
        expect(conn).to receive(:execute).with("SELECT a WHERE a = ?", "%CONSISTENCY%")
        run_query(nil)
      end
    end

    describe "cql2" do
      before do
        allow(conn).to receive(:use_cql3?).and_return(false)
      end

      it "passes the consistency level in the query string" do
        expect(conn).to receive(:execute).with("SELECT a USING CONSISTENCY ONE WHERE a = ?", "%CONSISTENCY%")
        run_query('ONE')
      end

      it "ignores a nil consistency" do
        expect(conn).to receive(:execute).with("SELECT a WHERE a = ?", "%CONSISTENCY%")
        run_query(nil)
      end
    end
  end

  describe "#batch" do
    it "does nothing for empty batches" do
      expect(db).to_not receive(:execute)
      expect(db).to_not be_in_batch
      db.batch do
        expect(db).to be_in_batch
      end
      expect(db).to_not be_in_batch
    end

    it "does update statements in a batch" do
      expect(db).to receive(:execute).with("1")
      db.batch { db.update("1") }

      expect(db).to receive(:execute).with("BEGIN BATCH UPDATE ? ? UPDATE ? ? APPLY BATCH", 1, 2, 3, 4)
      db.batch { db.update("UPDATE ? ?", 1, 2); db.update("UPDATE ? ?", 3, 4) }
    end

    it "does not batch up execute statements" do
      expect(db).to receive(:execute).with("SELECT").and_return("RETURN")
      expect(db).to receive(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      db.batch do
        db.update("1")
        expect(db.execute("SELECT")).to eq "RETURN"
        db.update("2")
      end
    end

    it "allows nested batch calls" do
      expect(db).to receive(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      db.batch do
        db.update("1")
        db.batch do
          expect(db).to be_in_batch
          db.update("2")
        end
      end
      expect(db).to_not be_in_batch
    end

    it "recovers from exceptions" do
      expect(db).to receive(:execute).with("2")
      begin
        db.batch do
          db.update("1")
          raise "oh noes"
        end
      rescue
        expect(db).to_not be_in_batch
      end
      db.batch do
        db.update("2")
      end
    end

    it "batches counter calls separately for cql3" do
      allow(db.db).to receive(:use_cql3?).and_return(true)
      expect(db).to receive(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      expect(db).to receive(:execute).with("BEGIN COUNTER BATCH 3 4 APPLY BATCH")

      db.batch do
        db.update("1")
        db.update("2")
        db.update_counter("3")
        db.update_counter("4")
      end
    end

    it "does not batch counter calls separately for older cassandra" do
      allow(db.db).to receive(:use_cql3?).and_return(false)
      expect(db).to receive(:execute).with("BEGIN BATCH 1 2 APPLY BATCH")
      db.batch do
        db.update("1")
        db.update_counter("2")
      end
    end
  end

  describe "#build_where_conditions" do
    it "should build a where clause given a hash" do
      expect(db.build_where_conditions(name: "test1")).to eq ["name = ?", ["test1"]]
      expect(db.build_where_conditions(state: "ut", name: "test1")).to eq ["name = ? AND state = ?", ["test1", "ut"]]
    end
  end

  describe "#update_record" do
    it "does nothing if there are no updates or deletes" do
      expect(db).to_not receive(:execute)
      db.update_record("test_table", {:id => 5}, {})
    end

    it "does lone updates" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.update_record("test_table", {:id => 5}, {:name => "test"})
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.update_record("test_table", {:id => 5}, {:name => [nil, "test"]})
    end

    it "does multi-updates" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ?, nick = ? WHERE id = ?", "test", "new", 5)
      db.update_record("test_table", {:id => 5}, {:name => "test", :nick => ["old", "new"]})
    end

    it "does lone deletes" do
      expect(db).to receive(:execute).with("DELETE name FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", {:id => 5}, {:name => nil})
      expect(db).to receive(:execute).with("DELETE name FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", {:id => 5}, {:name => ["old", nil]})
    end

    it "does multi-deletes" do
      expect(db).to receive(:execute).with("DELETE name, nick FROM test_table WHERE id = ?", 5)
      db.update_record("test_table", {:id => 5}, {:name => nil, :nick => ["old", nil]})
    end

    it "does combined updates and deletes" do
      expect(db).to receive(:execute).with("BEGIN BATCH UPDATE test_table SET name = ? WHERE id = ? DELETE nick FROM test_table WHERE id = ? APPLY BATCH", "test", 5, 5)
      db.update_record("test_table", {:id => 5}, {:name => "test", :nick => nil})
    end

    it "works when already in a batch" do
      expect(db).to receive(:execute).with("BEGIN BATCH UPDATE ? UPDATE test_table SET name = ? WHERE id = ? DELETE nick FROM test_table WHERE id = ? UPDATE ? APPLY BATCH", 1, "test", 5, 5, 2)
      db.batch do
        db.update("UPDATE ?", 1)
        db.update_record("test_table", {:id => 5}, {:name => "test", :nick => nil})
        db.update("UPDATE ?", 2)
      end
    end

    it "handles compound primary keys" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ? AND sub_id = ?", "test", 5, "sub!")
      db.update_record("test_table", {:id => 5, :sub_id => "sub!"}, {:name => "test", :id => 5, :sub_id => [nil, "sub!"]})
    end

    it "does not allow changing a primary key component" do
      expect {
        db.update_record("test_table", {:id => 5, :sub_id => "sub!"}, {:name => "test", :id => 5, :sub_id => ["old", "sub!"]})
      }.to raise_error(ArgumentError)
    end
  end

  describe "#insert_record" do
    it "constructs correct queries when the params are strings" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.insert_record("test_table", {'id' => 5}, {'name' => "test"})
    end

    it "constructs correct queries when the params are symbols" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.insert_record("test_table", {:id => 5}, {:name => "test"})
    end

    it "should not update given nil values in an AR#attributes style hash" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.insert_record("test_table", {:id => 5}, {:name => "test", :nick => nil})
    end

    it "should not update given nil values in an AR#changes style hash" do
      expect(db).to receive(:execute).with("UPDATE test_table SET name = ? WHERE id = ?", "test", 5)
      db.insert_record("test_table", {:id => 5}, {:name => [nil, "test"], :nick => [nil, nil]})
    end
  end

  describe "#available?" do
    it 'asks #db.active?' do
      expect(db.db).to receive(:active?) { true }
      expect(db.available?).to be_truthy

      expect(db.db).to receive(:active?) { false }
      expect(db.available?).to be_falsey
    end
  end

  describe "#keyspace" do
    it 'asks #db.keyspace' do
      keyspace_name = 'keyspace'

      expect(db.db).to receive(:keyspace) { keyspace_name }
      expect(db.keyspace).to eq keyspace_name
    end

    it 'aliases name' do
      keyspace_name = 'keyspace'

      expect(db.db).to receive(:keyspace) { keyspace_name }
      expect(db.name).to eq keyspace_name
    end
  end

  it "should map consistency level names to values" do
    expect(CanvasCassandra.consistency_level("LOCAL_QUORUM")).to eq CassandraCQL::Thrift::ConsistencyLevel::LOCAL_QUORUM
    expect { CanvasCassandra.consistency_level("XXX") }.to raise_error(NameError)
  end
end
