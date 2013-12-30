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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe EventStream::Failure do
  describe "log!" do
    before do
      @record = stub('record',
        :id => stub('record_id', :to_s => 'record_id_string'),
        :attributes => { stub('attribute') => stub('attribute_value') },
        :changes => { stub('changed_attribute') => stub('changed_value') })

      @stream = stub('stream', :identifier => 'stream_identifier')
      @stream.stubs(:operation_payload).with(:insert, @record).returns(@record.attributes)
      @stream.stubs(:operation_payload).with(:update, @record).returns(@record.changes)

      @exception = Exception.new
      @exception.stubs(:message).returns(stub('exception_message', :to_s => 'exception_message_string'))
      @exception.stubs(:backtrace).returns([stub('exception_backtrace')])

      # By default the log! method raises exceptions in test env.  Override this
      # to log the event and not raise it for these tests.
      Rails.env.stubs(:test?).returns(false)
    end

    it "should create a new db record" do
      lambda{ EventStream::Failure.log!(:insert, @stream, @record, @exception) }.
        should change(EventStream::Failure, :count)
    end

    it "should save the failed operation type" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.operation.should == 'insert'

      failure = EventStream::Failure.log!(:update, @stream, @record, @exception)
      failure.operation.should == 'update'
    end

    it "should save the event stream identifier" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.event_stream.should == @stream.identifier
    end

    it "should save the record id as a string" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.record_id.should == @record.id.to_s
    end

    it "should save the operation-appropriate payload" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.payload.should == @record.attributes

      failure = EventStream::Failure.log!(:update, @stream, @record, @exception)
      failure.payload.should == @record.changes
    end

    it "should save the exception message as a string" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.exception.should == @exception.message.to_s
    end

    it "should save the exception backtrace" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      failure.backtrace.should == @exception.backtrace
    end
  end
end
