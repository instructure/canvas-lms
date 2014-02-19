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
  describe "Record" do
    class EventRecord < ::EventStream::Record
      attributes :attribute1,
                 :attribute2
    end

    before do
      @request_id = UUIDSingleton.instance.generate
      RequestContextGenerator.stubs( :request_id => @request_id, :cassandra? => true )
      @event = EventRecord.new(
        'attribute1' => 'value1',
        'attribute2' => 'value2'
      )
    end

    it "should set default values" do
      @event.id.should_not == nil
      @event.created_at.should_not == nil
      @event.event_type.should == "event_record"
      @event.request_id.should == @request_id
    end

    it "should allow overrided default values" do
      attributes = {
        'id' => UUIDSingleton.instance.generate,
        'event_type' => 'other_type',
        'request_id' => UUIDSingleton.instance.generate,
        'created_at' => Time.zone.now
      }
      event = EventRecord.new(attributes)

      event.id.should == attributes['id']
      event.created_at.should == Time.zone.at(attributes['created_at'].to_i)
      event.event_type.should == attributes['event_type']
      event.request_id.should == attributes['request_id']
    end

    it "should return page_view when it is available for request_id" do
      @event.page_view.should be_nil

      @page_view = PageView.new { |p|
        p.assign_attributes({
          :request_id => @request_id
        }, :without_protection => true)
      }
      PageView.stubs( :find_by_id => @page_view )
      @event.page_view.should == @page_view
    end

    it "should define accessors for attributes" do
      (defined? @event.attribute1).should == "method"
      (defined? @event.attribute2).should == "method"

      @event.attribute1.should == 'value1'
      @event.attribute2.should == 'value2'
    end

    it "should work when request_id is an integer" do
      @request_id = 42

      RequestContextGenerator.stubs( :request_id => @request_id, :cassandra? => true )
      @event = EventRecord.new(
        'attribute1' => 'value1',
        'attribute2' => 'value2'
      )

      @event.request_id.should == @request_id.to_s
    end

    it "should work when request_id is nil" do
      RequestContextGenerator.stubs( :request_id => nil, :cassandra? => true )
      @event = EventRecord.new(
        'attribute1' => 'value1',
        'attribute2' => 'value2'
      )
      @event.request_id.should be_nil
    end
  end
end
