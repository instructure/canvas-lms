#
# Copyright (C) 2011 Instructure, Inc.
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

describe CalendarEvent do

  before(:each) do
    Time.zone = "UTC"
    Account.default.update_attribute(:default_time_zone, 'UTC')
  end
  
  it "should sanitize description" do
    course_model
    @c = CalendarEvent.new
    @c.description = "<a href='#' onclick='alert(12);'>only this should stay</a>"
    @c.context_id = @course.id
    @c.context_type = 'Course'
    @c.save!
    @c.description.should eql("<a href=\"#\">only this should stay</a>")
  end
  
  context "ical" do
    it ".to_ics should not fail for null times" do
      calendar_event_model(:start_at => "", :end_at => "")
      res = @event.to_ics
      res.should_not be_nil
      res.match(/DTSTART/).should be_nil
    end
    
    it ".to_ics should not return data for null times" do
      calendar_event_model(:start_at => "", :end_at => "")
      res = @event.to_ics(false)
      res.should be_nil
    end
    
    it ".to_ics should return string data for events with times" do
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      res = @event.to_ics
      res.should_not be_nil
      res.match(/DTSTART:20080903T115500Z/).should_not be_nil
      res.match(/DTEND:20080903T120000Z/).should_not be_nil
    end

    it ".to_ics should return data for events with times" do
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      res = @event.to_ics(false)
      res.should_not be_nil
      res.start.strftime('%Y-%m-%dT%H:%M:00z').should == (ActiveSupport::TimeWithZone.new(Time.parse("Sep 3 2008 11:55am"), Time.zone).strftime('%Y-%m-%dT%H:%M:00z'))
      res.end.strftime('%Y-%m-%dT%H:%M:00z').should == (ActiveSupport::TimeWithZone.new(Time.parse("Sep 3 2008 12:00pm"), Time.zone).strftime('%Y-%m-%dT%H:%M:00z'))
    end
    
    it ".to_ics should return string dates for all_day events" do
      calendar_event_model(:start_at => "Sep 3 2008 12:00am")
      @event.all_day.should eql(true)
      @event.end_at.should eql(@event.start_at)
      res = @event.to_ics
      res.match(/DTSTART;VALUE=DATE:20080903/).should_not be_nil
      res.match(/DTEND;VALUE=DATE:20080903/).should_not be_nil      
    end
  end
  
  context "clone_for" do
    it "should clone for another context" do
      calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
      course
      @new_event = @event.clone_for(@course)
      @new_event.context.should_not eql(@event.context)
      @new_event.context.should eql(@course)
      @new_event.start_at.should eql(@event.start_at)
      @new_event.title.should eql(@event.title)
    end
  end
end
