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

    it ".to_ics should return a plain-text description" do
      calendar_event_model(:start_at => "Sep 3 2008 12:00am", :description => <<-HTML)
      <p>
        This assignment is due December 16th. Plz discuss the reading.
        <p> </p>
        <p> </p>
        <p> </p>
        <p> </p>
        <p>Test.</p>
      </p>
      HTML
      ev = @event.to_ics(false)
      ev.description.should == "This assignment is due December 16th. Plz discuss the reading.
         
         
         
         
        Test."
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

  context "for_user_and_context_codes" do
    before do
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
      g1 = @course.appointment_groups.create(:title => "foo")
      g1.publish!
      a1 = g1.appointments.create.reserve_for(@student, @student)
      g2 = @course.appointment_groups.create(:title => "foo", :sub_context_code => @course.default_section.asset_string)
      g2.publish!
      a2 = g2.appointments.create.reserve_for(@student, @student)

      CalendarEvent.for_user_and_context_codes(@student, [@student.asset_string]).sort_by(&:id).
        should eql [@e2] # none of the appointments even though they technically are on the user

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string, @student.asset_string]).sort_by(&:id).
        should eql [@e1, @e2, a1, a2]

      CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).sort_by(&:id).
        should eql [@e1, a1, a2]
    end
  end

  context "appointments" do
    before do
      course_with_student(:active_all => true)
      @student1 = @user
      @other_section = @course.course_sections.create!
      @other_course = Course.create!
      @ag = AppointmentGroup.create(:title => "test", :context => @course)
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

        c1 = @course.group_categories.create
        @group = c1.groups.create(:context => @course)
        @group.users << @student1 << @student2

        @ag2 = AppointmentGroup.create!(:title => "test", :context => @course, :sub_context_code => c1.asset_string)
        @ag2.publish!
        @appointment2 = @ag2.appointments.create(:start_at => '2012-01-01 12:00:00', :end_at => '2012-01-01 13:00:00')

        [@teacher, @student1, @student2].each do |user|
          channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
          channel.confirm
        end
      end

      it "should notify all participants except the person reserving" do
        reservation = @appointment2.reserve_for(@group, @student1)
        reservation.messages_sent.should be_include("Appointment Reserved For User")
        reservation.messages_sent["Appointment Reserved For User"].map(&:user_id).sort.uniq.should eql [@student2.id]
      end

      it "should notify all participants except the person canceling the reservation" do
        reservation = @appointment2.reserve_for(@group, @student1)
        reservation.updating_user = @student1
        reservation.destroy
        reservation.messages_sent.should be_include("Appointment Deleted For User")
        reservation.messages_sent["Appointment Deleted For User"].map(&:user_id).sort.uniq.should eql [@student2.id]
      end

      it "should notify participants if teacher deletes the appointment time slot" do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        @appointment2.destroy
        reservation.messages_sent.should be_include("Appointment Deleted For User")
        reservation.messages_sent["Appointment Deleted For User"].map(&:user_id).sort.uniq.should eql [@student1.id, @student2.id]
      end

      it "should notify all participants when the the time slot is canceled" do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        @appointment2.destroy
        @appointment2.messages_sent.should be_empty
        reservation.messages_sent.should be_include("Appointment Deleted For User")
        reservation.messages_sent["Appointment Deleted For User"].map(&:user_id).sort.uniq.should eql [@student1.id, @student2.id]
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
      ag = AppointmentGroup.create(:title => "test", :context => @course, :participants_per_appointment => 2,
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
        :context => @course,
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
        :context => @course,
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
      ag = AppointmentGroup.create(:title => "test", :context => @course, :max_appointments_per_participant => 1,
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00'], ['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      appointment.reserve_for(@student1, @student1)
      lambda { appointment2.reserve_for(@student1, @student1) }.should raise_error
    end

    it "should cancel existing reservations if cancel_existing = true" do
      ag = AppointmentGroup.create(:title => "test", :context => @course, :max_appointments_per_participant => 1,
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
      ag = AppointmentGroup.create(:title => "test", :context => @course.course_sections.create,
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first

      lambda { appointment.reserve_for(@student1, @student1) }.should raise_error
    end

    it "should enforce the group category" do
      teacher = user(:active_all => true)
      @course.enroll_teacher(teacher).accept!
      c1 = @course.group_categories.create
      g1 = c1.groups.create(:context => @course)
      c2 = @course.group_categories.create
      g2 = c2.groups.create(:context => @course)

      ag = AppointmentGroup.create(:title => "test", :context => @course, :sub_context_code => c1.asset_string,
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

    it "should unlock the appointment when the last reservation is cancelled" do
      ag = AppointmentGroup.create(:title => "test", :context => @course, :participants_per_appointment => 2,
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
      ag = AppointmentGroup.create(:title => "test", :context => @course, :description => "hello\nworld",
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
      ag = AppointmentGroup.create(:title => "test", :context => @course)
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
      ag = AppointmentGroup.create(:title => "test", :context => @course, :participants_per_appointment => 1,
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

    it "should delete child events when deleting the parent" do
      calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
      child = @event.child_events.build
      child.context = user
      child.workflow_state = :locked
      child.save!

      @event.destroy

      @event.reload.should be_deleted
      child.reload.should be_deleted
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
