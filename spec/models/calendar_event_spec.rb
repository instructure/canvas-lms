#
# Copyright (C) 2011 - 2013 Instructure, Inc.
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

  describe "default_values" do
    before(:once) do
      course_model
      @original_start_at =  Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
      @original_end_at = @original_start_at + 2.hours

      # Create the initial event
      @event = calendar_event_model(
          :start_at => @original_start_at,
          :end_at => @original_end_at,
          :time_zone_edited => "Mountain Time (US & Canada)"
      )
    end

    it "should get localized start_at" do
      df = "%Y-%m-%d %H:%M"
      @event.start_at.strftime(df).should == "2008-09-03 12:05"
      @event.zoned_start_at.strftime(df).should == "2008-09-03 06:05"
    end

    it "should populate missing dates" do
      event_1 = calendar_event_model
      event_1.start_at = @original_start_at
      event_1.end_at = nil
      event_1.send(:populate_missing_dates)
      event_1.end_at.should eql(event_1.start_at)

      event_2 = calendar_event_model
      event_2.start_at = nil
      event_2.end_at = @original_end_at
      event_2.send(:populate_missing_dates)
      event_2.start_at.should eql(event_2.end_at)

      event_3 = calendar_event_model
      event_3.start_at = @original_end_at
      event_3.end_at = @original_start_at
      event_3.send(:populate_missing_dates)
      event_3.end_at.should eql(event_3.start_at)
    end

    it "should populate all day flag" do
      midnight = Time.at(1361862000) # 2013-02-26 00:00:00

      event_1 = calendar_event_model(:time_zone_edited => "Mountain Time (US & Canada)")
      event_1.start_at = event_1.end_at = midnight
      event_1.send(:populate_all_day_flag)
      event_1.all_day?.should be_true
      event_1.all_day_date.strftime("%Y-%m-%d").should == "2013-02-26"

      event_2 = calendar_event_model(:time_zone_edited => "Mountain Time (US & Canada)")
      event_2.start_at = @original_start_at
      event_2.end_at = @original_end_at
      event_2.send(:populate_all_day_flag)
      event_2.all_day?.should be_false

      event_3 = calendar_event_model(
          :start_at => midnight,
          :end_at => midnight + 1.hour,
          :time_zone_edited => "Mountain Time (US & Canada)"
      )
      event_3.start_at = midnight
      event_3.end_at = midnight + 30.minutes
      event_3.all_day = true
      event_3.send(:populate_all_day_flag)
      event_3.all_day?.should be_true
      event_3.end_at.should eql(event_3.start_at)
    end

    it "should retain all day flag when date is changed (calls :default_values)" do
      # Flag the event as all day
      @event.update_attributes({ :start_at => @original_start_at, :end_at => @original_end_at, :all_day => true })
      @event.all_day?.should be_true
      @event.all_day_date.strftime("%Y-%m-%d").should == "2008-09-03"
      @event.zoned_start_at.strftime("%H:%M").should == "00:00"
      @event.end_at.should eql(@event.zoned_start_at)

      # Change the date but keep the all day flag as true
      @event.update_attributes({ :start_at => @event.start_at - 1.day, :end_at => @event.end_at - 1.day, :all_day => true })
      @event.all_day?.should be_true
      @event.all_day_date.strftime("%Y-%m-%d").should == "2008-09-02"
      @event.zoned_start_at.strftime("%H:%M").should == "00:00"
      @event.end_at.should eql(@event.zoned_start_at)
    end
  end

  context "ical" do
    describe "to_ics" do
      it "should not fail for null times" do
        calendar_event_model(:start_at => "", :end_at => "")
        res = @event.to_ics
        res.should_not be_nil
        res.match(/DTSTART/).should be_nil
      end

      it "should not return data for null times" do
        calendar_event_model(:start_at => "", :end_at => "")
        res = @event.to_ics(false)
        res.should be_nil
      end

      it "should return string data for events with times" do
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

      it "should return string data for events with times in correct tz" do
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

      it "should return data for events with times" do
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

      it "should return data for events with times in correct tz" do
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

      it "should return string dates for all_day events" do
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        @event.all_day.should eql(true)
        @event.end_at.should eql(@event.start_at)
        res = @event.to_ics
        res.match(/DTSTART;VALUE=DATE:20080903/).should_not be_nil
        res.match(/DTEND;VALUE=DATE:20080903/).should_not be_nil
      end

      it "should return a plain-text description" do
        calendar_event_model(:start_at => "Sep 3 2008 12:00am", :description => <<-HTML)
      <p>
        This assignment is due December 16th. <b>Please</b> do the reading.
        <br/>
        <a href="www.example.com">link!</a>
      </p>
      HTML
        ev = @event.to_ics(false)
        ev.description.should match_ignoring_whitespace("This assignment is due December 16th. Please do the reading.
 

[link!](www.example.com)")
        ev.x_alt_desc.should == @event.description
      end

      it "should add a course code to the summary of an event that has a course as an effective_context" do
        course_model
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        @event.effective_context_code = @course.asset_string
        ics = @event.to_ics
        ics.should include("SUMMARY:#{@event.title} [#{@course.course_code}]")
      end

      it "should add a course code to the summary of an event that has a course as its effective_context's context" do
        course_model
        group(:context => @course)
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        @event.effective_context_code = @group.asset_string
        ics = @event.to_ics
        ics.should include("SUMMARY:#{@event.title} [#{@course.course_code}]")
      end
    end
  end

  context "for_user_and_context_codes" do
    before :once do
      course_with_student(:active_all => true)
      @student = @user
      @e1 = @course.calendar_events.create!
      @e2 = @student.calendar_events.create!
      @e3 = Course.create.calendar_events.create!
    end

    it "should return events explicitly tied to the contexts" do
      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).sort_by(&:id).
        should eql [@e1]

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string, @student.asset_string]).sort_by(&:id).
        should eql [@e1, @e2]
    end

    it "should return events implicitly tied to the contexts (via effective_context_string)" do
      @teacher = user
      @course.enroll_teacher(@teacher).accept!
      course1 = @course
      course_with_teacher(:user => @teacher)
      course2, @course = @course, course1
      g1 = AppointmentGroup.create!(:title => "foo", :contexts => [course1, course2])
      g1.publish!
      ae1 = g1.appointments.create!
      a1 = ae1.reserve_for(@student, @student)
      g2 = AppointmentGroup.create!(:title => "foo", :contexts => [@course], :sub_context_codes => [@course.default_section.asset_string])
      g2.publish!
      ae2 = g2.appointments.create!
      a2 = ae2.reserve_for(@student, @student)
      g3 = AppointmentGroup.create!(:title => "foo", :contexts => [@course])
      g3.publish!
      ae3 = g3.appointments.create!
      pe = @course.calendar_events.create!
      section = @course.default_section
      se = pe.child_events.build
      se.context = section
      se.save!

      CalendarEvent.for_user_and_context_codes(@student, [@student.asset_string]).sort_by(&:id).
        should eql [@e2] # none of the appointments even though they technically are on the user

      CalendarEvent.for_user_and_context_codes(@student, [section.asset_string]).sort_by(&:id).
        should eql [] # none of the appointments even though they technically are on the section

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string, @student.asset_string]).sort_by(&:id).
        should eql [@e1, @e2, a1, a2, pe, se]

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).sort_by(&:id).
        should eql [@e1, a1, a2, pe, se]

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).events_without_child_events.sort_by(&:id).
        should eql [@e1, a1, a2, se]

      CalendarEvent.for_user_and_context_codes(@student, [g1.asset_string, g2.asset_string, g3.asset_string]).sort_by(&:id).
        should eql [ae1, ae2, ae3]

      CalendarEvent.for_user_and_context_codes(@teacher, [g1.asset_string, g2.asset_string, g3.asset_string]).events_with_child_events.sort_by(&:id).
        should eql [ae1, ae2]
    end
  end

  context "notifications" do
    before :once do
      Notification.create(:name => 'New Event Created', :category => "TestImmediately")
      Notification.create(:name => 'Event Date Changed', :category => "TestImmediately")
      course_with_student(:active_all => true)
      @teacher = user(:active_all => true)
      @course.enroll_teacher(@teacher).accept!
      channel = @student.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
      channel.confirm
    end

    it "should send notifications to participants" do
      course_with_student(:active_all => true)
      event1 = @course.calendar_events.build(:title => "test")
      event1.updating_user = @teacher
      event1.save!
      event1.messages_sent.should be_include("New Event Created")
      users = event1.messages_sent["New Event Created"].map(&:user_id)
      users.should include(@student.id)
      users.should_not include(@teacher.id)
      event1.messages_sent["New Event Created"].each do |message|
        message.url.should include "/courses/#{@course.id}/calendar_events/#{event1.id}"
      end

      event1.update_attributes(:start_at => Time.now, :end_at => Time.now)
      event1.messages_sent.should be_include("Event Date Changed")
      users = event1.messages_sent["Event Date Changed"].map(&:user_id)
      users.should include(@student.id)
      users.should_not include(@teacher.id)
      event1.messages_sent["Event Date Changed"].each do |message|
        message.url.should include "/courses/#{@course.id}/calendar_events/#{event1.id}"
      end

      event2 = @course.default_section.calendar_events.build(:title => "test")
      event2.updating_user = @teacher
      event2.save!
      event2.messages_sent.should be_include("New Event Created")
      users = event1.messages_sent["New Event Created"].map(&:user_id)
      users.should include(@student.id)
      users.should_not include(@teacher.id)
      event2.messages_sent["New Event Created"].each do |message|
        message.url.should include "/course_sections/#{@course.default_section.id}/calendar_events/#{event2.id}"
      end

      event2.update_attributes(:start_at => Time.now, :end_at => Time.now)
      event2.messages_sent.should be_include("Event Date Changed")
      users = event1.messages_sent["Event Date Changed"].map(&:user_id)
      users.should include(@student.id)
      users.should_not include(@teacher.id)
      event2.messages_sent["Event Date Changed"].each do |message|
        message.url.should include "/course_sections/#{@course.default_section.id}/calendar_events/#{event2.id}"
      end
    end

    it "should not send notifications to participants if hidden" do
      course_with_student(:active_all => true)
      event = @course.calendar_events.build(:title => "test", :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}])
      event.updating_user = @teacher
      event.save!
      event.messages_sent.should be_empty

      event.update_attribute(:child_event_data, [{:start_at => "2012-01-02", :end_at => "2012-01-03", :context_code => @course.default_section.asset_string}])
      event.messages_sent.should be_empty
    end
  end

  context "appointments" do
    before :once do
      course_with_student(:active_all => true)
      @student1 = @user
      @other_section = @course.course_sections.create!
      @other_course = Course.create!
      @ag = AppointmentGroup.create(:title => "test", :contexts => [@course])
      @ag.publish!
      @appointment = @ag.appointments.create(:start_at => '2012-01-01 12:00:00', :end_at => '2012-01-01 13:00:00')
    end

    context "notifications" do
      before do
        Notification.create(:name => 'Appointment Canceled By User', :category => "TestImmediately")
        Notification.create(:name => 'Appointment Deleted For User', :category => "TestImmediately")
        Notification.create(:name => 'Appointment Reserved By User', :category => "TestImmediately")
        Notification.create(:name => 'Appointment Reserved For User', :category => "TestImmediately")

        @teacher = user(:active_all => true)
        @course.enroll_teacher(@teacher).accept!

        student_in_course(:course => @course, :active_all => true)
        @student2 = @user

        c1 = group_category
        @group = c1.groups.create(:context => @course)
        @group.users << @student1 << @student2

        @ag2 = AppointmentGroup.create!(:title => "test", :contexts => [@course], :sub_context_codes => [c1.asset_string])
        @ag2.publish!
        @appointment2 = @ag2.appointments.create(:start_at => '2012-01-01 12:00:00', :end_at => '2012-01-01 13:00:00')

        [@teacher, @student1, @student2].each do |user|
          channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
          channel.confirm
        end
      end

      it "should notify all participants except the person reserving" do
        reservation = @appointment2.reserve_for(@group, @student1)
        Message.where(notification_id: BroadcastPolicy.notification_finder.by_name("Appointment Reserved For User"), user_id: [@student1, @student2]).pluck(:user_id).should == [@student2.id]
      end

      it "should notify all participants except the person canceling the reservation" do
        reservation = @appointment2.reserve_for(@group, @student1)
        reservation.updating_user = @student1
        reservation.destroy
        Message.where(notification_id: BroadcastPolicy.notification_finder.by_name("Appointment Deleted For User"), user_id: [@student1, @student2]).pluck(:user_id).should == [@student2.id]
      end

      it "should notify participants if teacher deletes the appointment time slot" do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        @appointment2.destroy
        Message.where(notification_id: BroadcastPolicy.notification_finder.by_name("Appointment Deleted For User"), user_id: [@student1, @student2]).pluck(:user_id).sort.should == [@student1.id, @student2.id]
      end

      it "should notify all participants when the the time slot is canceled" do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        @appointment2.destroy
        @appointment2.messages_sent.should be_empty
        Message.where(notification_id: BroadcastPolicy.notification_finder.by_name("Appointment Deleted For User"), user_id: [@student1, @student2]).pluck(:user_id).sort.should == [@student1.id, @student2.id]
      end

      it "should notify admins when a user reserves" do
        reservation = @appointment.reserve_for(@user, @user)
        reservation.messages_sent.should be_include("Appointment Reserved By User")
        reservation.messages_sent["Appointment Reserved By User"].map(&:user_id).sort.uniq.should eql @course.instructors.map(&:id).sort
      end

      it "should notify admins when a user cancels" do
        reservation = @appointment.reserve_for(@student1, @student1)
        reservation.updating_user = @student1
        reservation.destroy
        reservation.messages_sent.should be_include("Appointment Canceled By User")
        reservation.messages_sent["Appointment Canceled By User"].map(&:user_id).sort.uniq.should eql @course.instructors.map(&:id).sort
      end
    end

    it "should allow multiple participants in an appointment, up to the limit" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 2,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first

      student_in_course(:course => @course, :active_all => true)
      @other_student = @user
      student_in_course(:course => @course, :active_all => true)
      @unlucky_student = @user

      appointment.reserve_for(@student1, @student1).should_not be_nil
      appointment.reserve_for(@other_student, @other_student).should_not be_nil
      lambda { appointment.reserve_for(@unlucky_student, @unlucky_student) }.should raise_error
    end

    it "should give preference to the calendar's appointment limit" do
      ag = AppointmentGroup.create!(
        :title => "testing...",
        :contexts => [@course],
        :participants_per_appointment => 2,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment.participants_per_appointment = 3
      appointment.save!

      s1, s2, s3 = 3.times.map {
        student_in_course(:course => @course, :active_all => true)
        @user
      }

      appointment.reserve_for(@student1, @student1).should_not be_nil
      appointment.reserve_for(s1, s1).should_not be_nil
      appointment.reserve_for(s2, s2).should_not be_nil
      lambda { appointment.reserve_for(s3, s3).should_not be_nil }.should raise_error

      # should be able to unset the participant limit too
      appointment.participants_per_appointment = nil
      appointment.save!
      appointment.reserve_for(s3, s3).should_not be_nil
    end

    it "should revert to the appointment group's participant_limit when appropriate" do
      ag = AppointmentGroup.create!(
        :title => "testing...",
        :contexts => [@course],
        :participants_per_appointment => 2,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!

      appointment = ag.appointments.first
      appointment.participants_per_appointment = 3
      appointment.save!
      appointment.participants_per_appointment.should eql 3

      appointment.participants_per_appointment = 2
      appointment.save!
      appointment.read_attribute(:participants_per_limit).should be_nil
      appointment.override_participants_per_appointment?.should be_false
      appointment.participants_per_appointment.should eql 2
    end

    it "should not let participants exceed max_appointments_per_participant" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :max_appointments_per_participant => 1,
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00'], ['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      appointment.reserve_for(@student1, @student1)
      lambda { appointment2.reserve_for(@student1, @student1) }.should raise_error
    end

    it "should cancel existing reservations if cancel_existing = true" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :max_appointments_per_participant => 1,
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00'], ['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      r1 = appointment.reserve_for(@student1, @student1)
      lambda { appointment2.reserve_for(@student1, @student1, :cancel_existing => true) }.should_not raise_error
      r1.reload.should be_deleted
    end

    it "should enforce the section" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course.course_sections.create],
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first

      lambda { appointment.reserve_for(@student1, @student1) }.should raise_error
    end

    it "should enforce the group category" do
      teacher = user(:active_all => true)
      @course.enroll_teacher(teacher).accept!
      c1 = group_category
      g1 = c1.groups.create(:context => @course)
      c2 = group_category(name: "bar")
      g2 = c2.groups.create(:context => @course)

      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :sub_context_codes => [c1.asset_string],
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      appointment = ag.appointments.first
      ag.publish!

      lambda { appointment.reserve_for(g2, teacher) }.should raise_error
      lambda { appointment.reserve_for(g1, teacher) }.should_not raise_error
    end

    it "should only accept users with StudentEnrollments as valid user participants" do
      @ag.eligible_participant?(@student1).should be_true
      lambda { @appointment.reserve_for(@student1, @student1) }.should_not raise_error

      # both a student and a teacher
      student_in_course(:course => @course, :active_all => true)
      @user.teacher_enrollments.create!(:course => @course)
      @ag.eligible_participant?(@user).should be_true
      lambda { @appointment.reserve_for(@user, @user) }.should_not raise_error

      # just a teacher
      user(:active_all => true)
      @course.enroll_teacher(@user).accept!
      @ag.eligible_participant?(@user).should be_false
      lambda { @appointment.reserve_for(@user, @user) }.should raise_error
    end

    it "should lock the appointment once it is reserved" do
      @appointment.should be_active
      @appointment.reserve_for(@student1, @student1).should_not be_nil
      @appointment.should be_locked
    end

    it "should unlock the appointment when the last reservation is canceled" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 2,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      appointment = ag.appointments.first
      student_in_course(:course => @course, :active_all => true)
      @other_student = @user

      appointment.should be_active
      r1 = appointment.reserve_for(@student1, @student1).reload
      appointment.should be_locked
      r2 = appointment.reserve_for(@other_student, @other_student).reload
      r2.destroy
      appointment.reload.should be_locked
      r1.destroy
      appointment.reload.should be_active
    end

    it "should copy the group attributes to the initial appointments" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :description => "hello\nworld",
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      e = ag.appointments.first
      e.title.should eql 'test'
      e.description.should eql "hello<br/>\r\nworld"
    end

    it "should copy changed group attributes to existing appointments" do
      @ag.update_attributes(:title => 'changed!', :description => "test\n123")
      e = @ag.appointments.first.reload
      e.title.should eql 'changed!'
      e.description.should eql "test<br/>\r\n123"
    end

    it "should not copy group description if appointment is overridden" do
      @appointment.description = "pizza party"
      @appointment.save!

      @ag.description = "boring meeting"
      @ag.save!

      @appointment.description.should == "pizza party"
      @ag.description.should == "boring meeting"
    end

    it "should copy the group attributes to subsequent appointments" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course])
      ag.update_attributes(
        :title => 'haha',
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      e = ag.appointments.first
      e.title.should eql 'haha'
    end

    it "should ignore changes to locked attributes on the appointment" do
      @appointment.update_attributes(:start_at => '2012-01-01 12:30:00', :title => 'you wish')
      @appointment.title.should eql 'test'
      @appointment.start_at.should eql Time.parse('2012-01-01 12:30:00Z')
    end

    it "should allow a user to re-reserve a slot after canceling" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 1,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      appointment = ag.appointments.first

      r1 = appointment.reserve_for(@student1, @student1).reload
      ag.reload.available_slots.should eql 0
      r1.destroy
      ag.reload.available_slots.should eql 1
      lambda { appointment.reserve_for(@student1, @student1) }.should_not raise_error
      ag.reload.available_slots.should eql 0
    end

    it "should always allow editing the description on an appointment" do
      @appointment.update_attribute :workflow_state, "locked"
      @appointment.description = "bacon"
      @appointment.save!
      @appointment.description.should == "bacon"
    end
  end

  context "child_events" do
    it "should delete child events when deleting the parent" do
      calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
      child = @event.child_events.build
      child.context = user
      child.save!

      @event.destroy

      @event.reload.should be_deleted
      child.reload.should be_deleted
    end

    context "bulk updating" do
      before :once do
        course_with_teacher
      end

      it "should validate child events" do
        lambda {
          @course.calendar_events.create! :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string}
            ]
        }.should raise_error(/Can't update child events unless an updating_user is set/)

        lambda {
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => "invalid_1"}
            ]
          event.updating_user = @user
          event.save!
        }.should raise_error(/Invalid child event context/)

        lambda {
          other_section = Course.create!.default_section
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => other_section.asset_string}
            ]
          event.updating_user = @user
          event.save!
        }.should raise_error(/Invalid child event context/)

        lambda {
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
              {:start_at => "2012-01-01 13:00:00", :end_at => "2012-01-01 14:00:00", :context_code => @course.default_section.asset_string}
            ]
          event.updating_user = @user
          event.save!
        }.should raise_error(/Duplicate child event contexts/)
      end

      it "should create child events" do
        s2 = @course.course_sections.create!
        e1 = @course.calendar_events.build :title => "ohai",
          :child_event_data => [
            {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
            {:start_at => "2012-01-02 12:00:00", :end_at => "2012-01-02 13:00:00", :context_code => s2.asset_string},
          ]
        e1.updating_user = @user
        e1.save!

        e1.reload
        events = e1.child_events.sort_by(&:id)
        events.map(&:context_code).should eql [@course.default_section.asset_string, s2.asset_string]
        events.map(&:effective_context_code).uniq.should eql [@course.asset_string]
        e1.start_at.should eql events.first.start_at
        e1.end_at.should eql events.last.end_at
      end

      it "should update child events" do
        s2 = @course.course_sections.create!
        s3 = @course.course_sections.create!
        e1 = @course.calendar_events.build :title => "ohai",
          :child_event_data => [
            {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
            {:start_at => "2012-01-02 12:00:00", :end_at => "2012-01-02 13:00:00", :context_code => s2.asset_string},
          ]
        e1.updating_user = @user
        e1.save!
        e1.reload
        events1 = e1.child_events.sort_by(&:id)

        e1.update_attributes :child_event_data => [
            {:start_at => "2012-01-01 13:00:00", :end_at => "2012-01-01 14:00:00", :context_code => @course.default_section.asset_string},
            {:start_at => "2012-01-02 12:00:00", :end_at => "2012-01-02 13:00:00", :context_code => s3.asset_string},
          ]
        e1.reload
        events2 = e1.child_events.sort_by(&:id)
        events2.size.should eql 2

        events1.first.reload.should eql events2.first
        events1.last.reload.should be_deleted
      end

      it "should not try to migrate resources to section context" do
        attachment_with_context(@course)
        s2 = @course.course_sections.create!
        e1 = @course.calendar_events.build :title => "ohai",
                                           :description => "<img src='/courses/#{@course.id}/files/#{@attachment.id}/preview'>",
                                           :child_event_data => [
                                               {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
                                               {:start_at => "2012-01-02 12:00:00", :end_at => "2012-01-02 13:00:00", :context_code => s2.asset_string},
                                           ]
        e1.updating_user = @user
        e1.save!
        e1.child_event_data = [
            {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
            {:start_at => "2012-01-02 22:00:00", :end_at => "2012-01-02 23:00:00", :context_code => s2.asset_string},
        ]
        lambda { e1.save! }.should_not raise_error
      end

      it "should delete all child events" do
        s2 = @course.course_sections.create!
        s3 = @course.course_sections.create!
        e1 = @course.calendar_events.build :title => "ohai",
          :child_event_data => [
            {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
            {:start_at => "2012-01-02 12:00:00", :end_at => "2012-01-02 13:00:00", :context_code => s2.asset_string},
          ]
        e1.updating_user = @user
        e1.save!
        e1.reload
        e1.update_attributes :remove_child_events => true
        e1.child_events.reload.should be_empty
      end
    end

    context "cascading" do
      it "should copy cascaded attributes when creating a child event" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.save!
        child.start_at.should be_nil
        child.title.should eql @event.title
      end
  
      it "should update cascaded attributes on the child events whenever the parent is updated" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.save!
        child.reload
        orig_start_at = child.start_at
  
        @event.title = 'asdf'
        @event.start_at = Time.now.utc
        @event.save!
        child.reload.title.should eql 'asdf'
        child.start_at.should eql orig_start_at
      end
  
      it "should disregard attempted changes to cascaded attributes" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.save!
        child.reload
        orig_start_at = child.start_at

        child.title = 'asdf'
        child.start_at = Time.now.utc
        child.save!
        child.title.should eql 'some event'
        child.start_at.should_not eql orig_start_at
      end
    end

    context "locking" do
      it "should copy all attributes when creating a locked child event" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.workflow_state = :locked
        child.save!
        child.start_at.should eql @event.start_at
        child.title.should eql @event.title
      end
  
      it "should update locked child events whenever the parent is updated" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.workflow_state = :locked
        child.save!
  
        @event.title = 'asdf'
        @event.save!
        child.reload.title.should eql 'asdf'
      end
  
      it "should disregard attempted changes to locked attributes" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user
        child.workflow_state = :locked
        child.save!
  
        child.title = 'asdf'
        child.save!
        child.title.should eql 'some event'
      end
  
      it "should unlock events when the last child is deleted" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        @event.workflow_state = :locked
        @event.save!
        child = @event.child_events.build
        child.context = user
        child.workflow_state = :locked
        child.save!
  
        child.destroy
        @event.reload.should be_active
        child.reload.should be_deleted
      end
    end
  end
end
