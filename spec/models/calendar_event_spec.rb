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
      Time.zone = 'UTC'
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      # force known value so we can check serialization
      @event.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @event.to_ics
      res.should_not be_nil
      res.match(/DTSTART:20080903T115500Z/).should_not be_nil
      res.match(/DTEND:20080903T120000Z/).should_not be_nil
      res.match(/DTSTAMP:20080903T120500Z/).should_not be_nil
    end
    
    it ".to_ics should return string data for events with times in correct tz" do
      Time.zone = 'Alaska' # -0800
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      # force known value so we can check serialization
      @event.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @event.to_ics
      res.should_not be_nil
      res.match(/DTSTART:20080903T195500Z/).should_not be_nil
      res.match(/DTEND:20080903T200000Z/).should_not be_nil
      res.match(/DTSTAMP:20080903T200500Z/).should_not be_nil
    end

    it ".to_ics should return data for events with times" do
      Time.zone = 'UTC'
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      # force known value so we can check serialization
      @event.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      res = @event.to_ics(false)
      res.should_not be_nil
      res.start.icalendar_tzid.should == 'UTC'
      res.start.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.end.icalendar_tzid.should == 'UTC'
      res.end.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:00pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.dtstamp.icalendar_tzid.should == 'UTC'
      res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
    end

    it ".to_ics should return data for events with times in correct tz" do
      Time.zone = 'Alaska' # -0800
      calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
      # force known value so we can check serialization
      @event.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
      res = @event.to_ics(false)
      res.should_not be_nil
      res.start.icalendar_tzid.should == 'UTC'
      res.start.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.end.icalendar_tzid.should == 'UTC'
      res.end.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:00pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      res.end.icalendar_tzid.should == 'UTC'
      res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S').should == Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
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
