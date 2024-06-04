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

describe CanvasCassandra::Database do
  let(:conn) { double }

  let(:db) do
    CanvasCassandra::Database.allocate.tap do |db|
      db.send(:instance_variable_set, :@db, conn)
      db.send(:instance_variable_set, :@logger, double.as_null_object)
      allow(db).to receive(:sanitize).and_return("")
    end
  end

  describe "#execute" do
    # I'm using %CONSISTENCY% as a query parameter here to make sure that the
    # execute code doesn't accidentally replace the string in those params
    def run_query(consistency)
      db.execute("SELECT a %CONSISTENCY% WHERE a = ?", "%CONSISTENCY%", consistency:)
    end

    describe "cql3" do
      before do
        allow(conn).to receive(:use_cql3?).and_return(true)
      end

      it "passes the consistency level as a param" do
        expect(conn).to receive(:execute_with_consistency).with("SELECT a WHERE a = ?", CassandraCQL::Thrift::ConsistencyLevel::ONE, "%CONSISTENCY%")
        run_query("ONE")
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
        run_query("ONE")
      end

      it "ignores a nil consistency" do
        expect(conn).to receive(:execute).with("SELECT a WHERE a = ?", "%CONSISTENCY%")
        run_query(nil)
      end
    end
  end

  describe "#available?" do
    it "asks #db.active?" do
      expect(db.db).to receive(:active?) { true }
      expect(db.available?).to be_truthy

      expect(db.db).to receive(:active?) { false }
      expect(db.available?).to be_falsey
    end
  end

  describe "#keyspace" do
    it "asks #db.keyspace" do
      keyspace_name = "keyspace"

      expect(db.db).to receive(:keyspace) { keyspace_name }
      expect(db.keyspace).to eq keyspace_name
    end

    it "aliases name" do
      keyspace_name = "keyspace"

      expect(db.db).to receive(:keyspace) { keyspace_name }
      expect(db.name).to eq keyspace_name
    end

    it "uses utf-8 encoding" do
      keyspace_name = "keyspace"

      expect(db.db).to receive(:keyspace) { keyspace_name }
      expect(db.keyspace.encoding.name).to eq "UTF-8"
    end
  end

  it "maps consistency level names to values" do
    expect(CanvasCassandra.consistency_level("LOCAL_QUORUM")).to eq CassandraCQL::Thrift::ConsistencyLevel::LOCAL_QUORUM
    expect { CanvasCassandra.consistency_level("XXX") }.to raise_error(NameError)
  end
end
