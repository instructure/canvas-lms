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

require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../cassandra_spec_helper')

describe CourseAuditApiController do
  include_examples "cassandra audit logs"

  before do
    RequestContextGenerator.stubs( :request_id => 'xyz' )

    @account = Account.default
    @sub_account = Account.create!(:parent_account => @account)
    @sub_sub_account = Account.create!(:parent_account => @sub_account)

    course_with_teacher(course_name: "Course 1", account: @sub_sub_account)

    @course.name = "Course 2"
    @course.start_at = Date.today
    @course.conclude_at = Date.today + 7.days

    @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
  end

  context "nominal cases" do
    it "should include event" do
      Auditors::Course.for_course(@course).paginate(:per_page => 5).should include(@event)
    end
  end

  context "type specific" do
    it "should log created event" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      @event.course.should == @course
      @event.event_type.should == "created"
      @event.event_data.should == @course.changes
    end

    it "should log updated event" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      @event.course.should == @course
      @event.event_type.should == "updated"
      @event.event_data.should == @course.changes
    end

    it "should log concluded event" do
      @event = Auditors::Course.record_concluded(@course, @teacher)
      @event.course.should == @course
      @event.event_type.should == "concluded"
      @event.event_data.should == {}
    end
  end

  describe "options forwarding" do
    before do
      record = Auditors::Course::Record.new(
        'course' => @course,
        'user' => @teacher,
        'event_type' => 'updated',
        'event_data' => @course.changes,
        'created_at' => 1.day.ago
      )
      @event2 = Auditors::Course::Stream.insert(record)
    end

    it "should recognize :oldest" do
      page = Auditors::Course.for_course(@course, oldest: 12.hours.ago).paginate(:per_page => 2)
      page.should include(@event)
      page.should_not include(@event2)
    end

    it "should recognize :newest" do
      page = Auditors::Course.for_course(@course, newest: 12.hours.ago).paginate(:per_page => 2)
      page.should include(@event2)
      page.should_not include(@event)
    end
  end
end
