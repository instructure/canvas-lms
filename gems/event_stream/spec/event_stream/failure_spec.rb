#
# Copyright (C) 2014 Instructure, Inc.
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

describe EventStream::Failure do
  describe "log!" do
    before do
      @record = double('record',
        :id => double('record_id', :to_s => 'record_id_string'),
        :attributes => { 'attribute' => 'attribute_value' },
        :changes => { 'changed_attribute' => 'changed_value' })

      @stream = double('stream',
        :identifier => 'stream_identifier',
        :raise_on_error => false)

      allow(@stream).to receive(:operation_payload).with(:insert, @record).and_return(@record.attributes)
      allow(@stream).to receive(:operation_payload).with(:update, @record).and_return(@record.changes)

      @exception = Exception.new
      allow(@exception).to receive(:message).and_return(double('exception_message', :to_s => 'exception_message_string'))
      allow(@exception).to receive(:backtrace).and_return([42])
    end

    it "creates a new db record" do
      expect {
        EventStream::Failure.log!(:insert, @stream, @record, @exception)
      }.to change(EventStream::Failure, :count)
    end

    it "saves the failed operation type" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.operation).to eq 'insert'

      failure = EventStream::Failure.log!(:update, @stream, @record, @exception)
      expect(failure.operation).to eq 'update'
    end

    it "saves the CanvasEvent stream identifier" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.event_stream).to eq @stream.identifier
    end

    it "saves the record id as a string" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.record_id).to eq @record.id.to_s
    end

    it "saves the operation-appropriate payload" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.payload).to eq @record.attributes

      failure = EventStream::Failure.log!(:update, @stream, @record, @exception)
      expect(failure.payload).to eq @record.changes
    end

    it "saves the exception message as a string" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.exception).to eq @exception.message.to_s
    end

    it "saves the exception backtrace" do
      failure = EventStream::Failure.log!(:insert, @stream, @record, @exception)
      expect(failure.backtrace.first).to equal 42
    end
  end
end
