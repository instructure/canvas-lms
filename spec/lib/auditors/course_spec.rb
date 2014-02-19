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
  end

  context "nominal cases" do
    it "should include event" do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)
      Auditors::Course.for_course(@course).paginate(:per_page => 5).should include(@event)
    end
  end

  context "event source" do
    it "should default event source to :manual" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes)
      @event.event_source.should == :manual
    end

    it "should log event with api source" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :api)
      @event.event_source.should == :api
    end

    it "should log event with sis_batch_id and event source of sis" do
      @event = Auditors::Course.record_created(@course, @teacher, @course.changes, source: :sis, sis_batch_id: 42)
      @event.event_source.should == :sis
      @event.sis_batch_id.should == 42
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

    it "should log unconcluded event" do
      @event = Auditors::Course.record_unconcluded(@course, @teacher)
      @event.course.should == @course
      @event.event_type.should == "unconcluded"
      @event.event_data.should == {}
    end

    it "should log published event" do
      @event = Auditors::Course.record_published(@course, @teacher)
      @event.course.should == @course
      @event.event_type.should == "published"
      @event.event_data.should == {}
    end

    it "should log deleted event" do
      @event = Auditors::Course.record_deleted(@course, @teacher)
      @event.course.should == @course
      @event.event_type.should == "deleted"
      @event.event_data.should == {}
    end

    it "should log restored event" do
      @event = Auditors::Course.record_restored(@course, @teacher)
      @event.course.should == @course
      @event.event_type.should == "restored"
      @event.event_data.should == {}
    end


    it "should log copied event" do
      @course, @copy_course = @course, course(:active_all => true)
      @from_event, @to_event = Auditors::Course.record_copied(@course, @copy_course, @teacher, source: :api)

      @from_event.course.should == @copy_course
      @from_event.event_type.should == "copied_from"
      @from_event.event_data.should == { :"copied_from" => Shard.global_id_for(@course) }

      @to_event.course.should == @course
      @to_event.event_type.should == "copied_to"
      @to_event.event_data.should == { :"copied_to" => Shard.global_id_for(@copy_course) }
    end
  end

  describe "options forwarding" do
    before do
      @event = Auditors::Course.record_updated(@course, @teacher, @course.changes)

      record = Auditors::Course::Record.new(
        'course' => @course,
        'user' => @teacher,
        'event_type' => 'updated',
        'event_data' => @course.changes,
        'event_source' => 'manual',
        'sis_batch_id' => nil,
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
