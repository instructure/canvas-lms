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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe EventStream::Failure do
  describe "Record" do
    class EventRecord < ::EventStream::Record
      attributes :attribute1,
                 :attribute2
    end

    before do
      @request_id = CanvasUUID.generate
      @event = EventRecord.new(
        'attribute1' => 'value1',
        'attribute2' => 'value2',
        'request_id' => @request_id
      )
    end

    it "responds to as_json with attributes" do
      hash = @event.as_json
      expect(hash.keys).to include(*%w[attribute1 attribute2 request_id])
    end

    it "sets default values" do
      expect(@event.id).to_not eq nil
      expect(@event.created_at).to_not eq nil
      expect(@event.event_type).to eq "event_record"
      expect(@event.request_id).to eq @request_id
    end

    it "allows overrided default values" do
      attributes = {
        'id' => CanvasUUID.generate,
        'event_type' => 'other_type',
        'request_id' => CanvasUUID.generate,
        'created_at' => Time.zone.now
      }
      event = EventRecord.new(attributes)

      expect(event.id).to eq attributes['id']
      expect(event.created_at).to eq Time.zone.at(attributes['created_at'].to_i)
      expect(event.event_type).to eq attributes['event_type']
      expect(event.request_id).to eq attributes['request_id']
    end

    it "defines accessors for attributes" do
      expect((defined? @event.attribute1)).to eq "method"
      expect((defined? @event.attribute2)).to eq "method"

      expect(@event.attribute1).to eq 'value1'
      expect(@event.attribute2).to eq 'value2'
    end

    it "converts request_id to string" do
      request_id = 42

      attributes = {
        'id' => CanvasUUID.generate,
        'event_type' => 'other_type',
        'request_id' => request_id,
        'created_at' => Time.zone.now
      }
      event = EventRecord.new(attributes)
      expect(event.request_id).to eq request_id.to_s

      event.request_id = request_id
      expect(event.request_id).to eq request_id.to_s
    end
  end
end
