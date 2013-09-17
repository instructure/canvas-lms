#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe EventStream do
  before do
    @database_name = stub(:to_s => stub('database_name'))
    @database = stub('database')
    def @database.batch; yield; end
    def @database.update_record(*args); end
    def @database.insert_record(*args); end
    def @database.update(*args); end
    ::Canvas::Cassandra::Database.stubs(:from_config).with(@database_name.to_s).returns(@database)
    ::Canvas::Cassandra::Database.stubs(:configured?).with(@database_name.to_s).returns(true)
  end

  context "setup block" do
    before do
      @table = stub(:to_s => stub('table'))
    end

    it "should set values as expected" do
      # can't access spec ivars inside instance_exec
      database_name = @database_name
      table = @table
      id_column = stub(:to_s => stub('id_column'))
      record_type = stub('record_type')

      stream = EventStream.new do
        self.database_name database_name
        self.table table
        self.id_column id_column
        self.record_type record_type
      end

      stream.database_name.should == database_name.to_s
      stream.database.should == @database
      stream.table.should == table.to_s
      stream.id_column.should == id_column.to_s
      stream.record_type.should == record_type
    end

    it "should require database_name and table" do
      # can't access spec ivars inside instance_exec
      database_name = @database_name
      table = @table

      lambda{ EventStream.new{ self.database_name database_name } }.should raise_exception ArgumentError
      lambda{ EventStream.new{ self.table table } }.should raise_exception ArgumentError
    end

    context "defaults" do
      before do
        # can't access spec ivars inside instance_exec
        database_name = @database_name
        table = @table
        @stream = EventStream.new do
          self.database_name database_name
          self.table table
        end
      end

      it "should default id_column to 'id'" do
        @stream.id_column.should == 'id'
      end

      it "should default record_type to EventStream::Record" do
        @stream.record_type.should == EventStream::Record
      end
    end
  end

  context "usage" do
    before do
      @table = stub(:to_s => "expected_table")
      database_name, table = @database_name, @table
      @stream = EventStream.new do
        self.database_name database_name
        self.table table
      end
    end

    describe "on_insert" do
      before do
        @record = stub(:id => stub('id'), :created_at => Time.now, :attributes => stub('attributes'))
      end

      it "should register callback for execution during insert" do
        spy = stub('spy')
        @stream.on_insert{ spy.trigger }
        spy.expects(:trigger).once
        @stream.insert(@record)
      end

      it "should include the record in the callback invocation" do
        spy = stub('spy')
        @stream.on_insert{ |record| spy.trigger(record) }
        spy.expects(:trigger).once.with(@record)
        @stream.insert(@record)
      end

      it "should stack multiple callbacks" do
        spy = stub('spy')
        @stream.on_insert{ spy.trigger1 }
        @stream.on_insert{ spy.trigger2 }
        spy.expects(:trigger1).once
        spy.expects(:trigger2).once
        @stream.insert(@record)
      end
    end

    describe "insert" do
      before do
        @timestamp = Time.now
        @record = stub(:id => stub('id'), :created_at => @timestamp, :attributes => stub('attributes'))
      end

      it "should insert into the configured database" do
        @database.expects(:insert_record).once
        @stream.insert(@record)
      end

      it "should insert into the configured table" do
        @database.expects(:insert_record).with(@table.to_s, anything, anything, anything)
        @stream.insert(@record)
      end

      it "should insert by the record's id into the configured id column" do
        id_column = stub(:to_s => stub('id_column'))
        @stream.id_column id_column
        @database.expects(:insert_record).with(anything, { id_column.to_s => @record.id }, anything, anything)
        @stream.insert(@record)
      end

      it "should insert the record's attributes" do
        @database.expects(:insert_record).with(anything, anything, @record.attributes, anything)
        @stream.insert(@record)
      end

      it "should set the record's ttl" do
        @database.expects(:insert_record).with(anything, anything, anything, @stream.ttl_seconds(@timestamp))
        @stream.insert(@record)
      end

      it "should execute its commands in a batch" do
        spy = stub('spy')
        @stream.on_insert{ spy.trigger }
        @database.expects(:batch).once
        @database.expects(:insert_record).never
        spy.expects(:trigger).never
        @stream.insert(@record)
      end
    end

    describe "on_update" do
      before do
        @record = stub(:id => stub('id'), :created_at => Time.now, :changes => stub('changes'))
      end

      it "should register callback for execution during update" do
        spy = stub('spy')
        @stream.on_update{ spy.trigger }
        spy.expects(:trigger).once
        @stream.update(@record)
      end

      it "should include the record in the callback invocation" do
        spy = stub('spy')
        @stream.on_update{ |record| spy.trigger(record) }
        spy.expects(:trigger).once.with(@record)
        @stream.update(@record)
      end

      it "should stack multiple callbacks" do
        spy = stub('spy')
        @stream.on_update{ spy.trigger1 }
        @stream.on_update{ spy.trigger2 }
        spy.expects(:trigger1).once
        spy.expects(:trigger2).once
        @stream.update(@record)
      end
    end

    describe "update" do
      before do
        @timestamp = Time.now
        @record = stub(:id => stub('id'), :created_at => @timestamp, :changes => stub('changes'))
      end

      it "should update in the configured database" do
        @database.expects(:update_record).once
        @stream.update(@record)
      end

      it "should update in the configured table" do
        @database.expects(:update_record).with(@table.to_s, anything, anything, anything)
        @stream.update(@record)
      end

      it "should update by the record's id in the configured id column" do
        id_column = stub(:to_s => stub('id_column'))
        @stream.id_column id_column
        @database.expects(:update_record).with(anything, { id_column.to_s => @record.id }, anything, anything)
        @stream.update(@record)
      end

      it "should update the record's changes" do
        @database.expects(:update_record).with(anything, anything, @record.changes, anything)
        @stream.update(@record)
      end

      it "should set the record's ttl" do
        @database.expects(:update_record).with(anything, anything, anything, @stream.ttl_seconds(@timestamp))
        @stream.update(@record)
      end

      it "should execute its commands in a batch" do
        spy = stub('spy')
        @stream.on_update{ spy.trigger }
        @database.expects(:batch).once
        @database.expects(:update_record).never
        spy.expects(:trigger).never
        @stream.update(@record)
      end
    end

    describe "fetch" do
      before do
        @results = stub(:fetch => nil)
      end

      it "should use the configured database" do
        @database.expects(:execute).once.returns(@results)
        @stream.fetch([1])
      end

      it "should use the configured table" do
        @database.expects(:execute).once.with(regexp_matches(/ FROM #{@table} /), anything).returns(@results)
        @stream.fetch([1])
      end

      it "should use the configured id column" do
        id_column = stub(:to_s => "expected_id_column")
        @stream.id_column id_column
        @database.expects(:execute).once.with(regexp_matches(/ WHERE #{id_column} /), anything).returns(@results)
        @stream.fetch([1])
      end

      it "should pass the given ids to the execute" do
        ids = stub('ids', :empty? => false)
        @database.expects(:execute).once.with(anything, ids).returns(@results)
        @stream.fetch(ids)
      end

      it "should map the returned rows to the configured record type" do
        record_type = stub('record_type')
        raw_result = stub('raw_result')
        cql_result = stub('cql_result', :to_hash => raw_result)
        typed_result = stub('typed_result')
        record_type.expects(:from_attributes).with(raw_result).returns(typed_result)

        @stream.record_type record_type
        @results.expects(:fetch).yields(cql_result)
        @database.expects(:execute).once.returns(@results)
        results = @stream.fetch([1])
        results.should == [typed_result]
      end

      it "should skip the fetch if no ids were given" do
        @database.expects(:execute).never
        @stream.fetch([])
      end
    end

    describe "add_index" do
      before do
        @table = stub('table')
        table = @table
        @index = @stream.add_index :thing do
          self.table table
          self.entry_proc lambda{ |record| record.entry }
        end

        @key = stub('key')
        @entry = stub('entry', :key => @key)
      end

      describe "generated on_insert callback" do
        before do
          @record = stub(
            :id => stub('id'),
            :created_at => Time.now,
            :attributes => stub('attributes'),
            :changes => stub('changes'),
            :entry => @entry
          )
        end

        it "should insert the provided record into the index" do
          @index.expects(:insert).once.with(@record, anything)
          @stream.insert(@record)
        end

        it "should translate the record through the entry_proc for the key" do
          @index.expects(:insert).once.with(anything, @entry)
          @stream.insert(@record)
        end

        it "should skip insert if entry_proc returns nil" do
          @index.entry_proc lambda{ |record| nil }
          @index.expects(:insert).never
          @stream.insert(@record)
        end

        it "should translate the result of the entry_proc through the key_proc if present" do
          @index.key_proc lambda{ |entry| entry.key }
          @index.expects(:insert).once.with(anything, @key)
          @stream.insert(@record)
        end
      end

      describe "generated for_thing method" do
        it "should forward argument to index's for_key" do
          @index.expects(:for_key).once.with(@entry, {})
          @stream.for_thing(@entry)
        end

        it "should translate argument through key_proc if present" do
          @index.key_proc lambda{ |entry| entry.key }
          @index.expects(:for_key).once.with(@key, {})
          @stream.for_thing(@entry)
        end

        it "should permit and forward options" do
          options = {oldest: 1.day.ago}
          @index.expects(:for_key).once.with(@entry, options)
          @stream.for_thing(@entry, options)
        end
      end
    end

    describe "failure" do
      before do
        @database = stub('database')
        @stream.stubs(:database).returns(@database)
        @record = stub(
          :id => 'id',
          :created_at => Time.now,
          :attributes => {'attribute' => 'attribute_value'},
          :changes => {'changed_attribute' => 'changed_value'})
        @exception = Exception.new
      end

      shared_examples_for "recording failures" do
        it "should record failed inserts" do
          EventStream::Failure.expects(:log!).once.with(:insert, @stream, @record, @exception)
          @stream.insert(@record)
        end

        it "should record failed updates" do
          EventStream::Failure.expects(:log!).once.with(:update, @stream, @record, @exception)
          @stream.update(@record)
        end
      end

      context "failing database" do
        before do
          @database.stubs(:batch).raises(@exception)
        end

        it_should_behave_like "recording failures"
      end

      context "failing callbacks" do
        before do
          @database.stubs(:batch).yields
          @database.stubs(:insert_record)
          @database.stubs(:update_record)

          exception = @exception
          @stream.on_insert{ raise exception }
          @stream.on_update{ raise exception }
        end

        it "should not insert a record when insert callback fails" do
          @database.expects(:execute).never
          @stream.insert(@record)
        end

        it "should not update a record when update callback fails" do
          @database.expects(:execute).never
          @stream.update(@record)
        end

        it_should_behave_like "recording failures"
      end
    end
  end
end
