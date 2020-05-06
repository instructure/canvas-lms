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

require 'spec_helper'

describe EventStream::Index do
  before do
    @database = double('database')

    def @database.batch;
      yield;
    end

    def @database.update_record(*args)
      ;
    end

    def @database.update(*args)
      ;
    end

    def @database.keyspace
      'test_db'
    end

    @stream = double('stream',
                     :database => @database,
                     :record_type => EventStream::Record,
                     :ttl_seconds => 1.year,
                     :read_consistency_level => nil)
  end

  context "setup block" do
    before do
      @table = double(:to_s => double('table'))
      @entry_proc = -> { "entry" }
    end

    it "sets values as expected" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc
      id_column = double(:to_s => double('id_column'))
      key_column = double(:to_s => double('key_column'))
      bucket_size = double(:to_i => double('bucket_size'))
      scrollback_limit = double(:to_i => double('scrollback_limit'))
      key_proc = -> { "key" }

      index = EventStream::Index.new(@stream) do
        self.table table
        self.entry_proc entry_proc
        self.id_column id_column
        self.key_column key_column
        self.bucket_size bucket_size
        self.scrollback_limit scrollback_limit
        self.key_proc key_proc
      end

      expect(index.table).to eq table.to_s
      expect(index.entry_proc).to eq entry_proc
      expect(index.id_column).to eq id_column.to_s
      expect(index.key_column).to eq key_column.to_s
      expect(index.bucket_size).to eq bucket_size.to_i
      expect(index.scrollback_limit).to eq scrollback_limit.to_i
      expect(index.key_proc).to eq key_proc
    end

    it "requires table and entry_proc" do
      # can't access spec ivars inside instance_exec
      table = @table
      entry_proc = @entry_proc

      expect {
        EventStream::Index.new(@stream) { self.table table }
      }.to raise_exception ArgumentError
      expect {
        EventStream::Index.new(@stream) { self.entry_proc entry_proc }
      }.to raise_exception ArgumentError
    end

    context "defaults" do
      before do
        # can't access spec ivars inside instance_exec
        table = @table
        entry_proc = @entry_proc
        @index = EventStream::Index.new(@stream) do
          self.table table
          self.entry_proc entry_proc
        end
      end

      it "defaults id_column to 'id'" do
        expect(@index.id_column).to eq 'id'
      end

      it "defaults key_column to 'key'" do
        expect(@index.key_column).to eq 'key'
      end

      it "defaults bucket_size to 1 week" do
        expect(@index.bucket_size).to eq 60 * 60 * 24 * 7
      end

      it "defaults scrollback_limit to 52 weeks" do
        expect(@index.scrollback_limit).to eq 52.weeks
      end

      it "defaults key_proc to nil" do
        expect(@index.key_proc).to be_nil
      end
    end
  end
end
