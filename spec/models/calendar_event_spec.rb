#
# Copyright (C) 2011 - present Instructure, Inc.
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
    expect(@c.description).to eql("<a href=\"#\">only this should stay</a>")
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
      expect(@event.start_at.strftime(df)).to eq "2008-09-03 12:05"
      expect(@event.zoned_start_at.strftime(df)).to eq "2008-09-03 06:05"
    end

    it "should populate missing dates" do
      event_1 = calendar_event_model
      event_1.start_at = @original_start_at
      event_1.end_at = nil
      event_1.send(:populate_missing_dates)
      expect(event_1.end_at).to eql(event_1.start_at)

      event_2 = calendar_event_model
      event_2.start_at = nil
      event_2.end_at = @original_end_at
      event_2.send(:populate_missing_dates)
      expect(event_2.start_at).to eql(event_2.end_at)

      event_3 = calendar_event_model
      event_3.start_at = @original_end_at
      event_3.end_at = @original_start_at
      event_3.send(:populate_missing_dates)
      expect(event_3.end_at).to eql(event_3.start_at)
    end

    it "should populate all day flag" do
      midnight = Time.at(1361862000) # 2013-02-26 00:00:00

      event_1 = calendar_event_model(:time_zone_edited => "Mountain Time (US & Canada)")
      event_1.start_at = event_1.end_at = midnight
      event_1.send(:populate_all_day_flag)
      expect(event_1.all_day?).to be_truthy
      expect(event_1.all_day_date.strftime("%Y-%m-%d")).to eq "2013-02-26"

      event_2 = calendar_event_model(:time_zone_edited => "Mountain Time (US & Canada)")
      event_2.start_at = @original_start_at
      event_2.end_at = @original_end_at
      event_2.send(:populate_all_day_flag)
      expect(event_2.all_day?).to be_falsey

      event_3 = calendar_event_model(
          :start_at => midnight,
          :end_at => midnight + 1.hour,
          :time_zone_edited => "Mountain Time (US & Canada)"
      )
      event_3.start_at = midnight
      event_3.end_at = midnight + 30.minutes
      event_3.all_day = true
      event_3.send(:populate_all_day_flag)
      expect(event_3.all_day?).to be_truthy
      expect(event_3.end_at).to eql(event_3.start_at)
    end

    it "should retain all day flag when date is changed (calls :default_values)" do
      # Flag the event as all day
      @event.update_attributes({ :start_at => @original_start_at, :end_at => @original_end_at, :all_day => true })
      expect(@event.all_day?).to be_truthy
      expect(@event.all_day_date.strftime("%Y-%m-%d")).to eq "2008-09-03"
      expect(@event.zoned_start_at.strftime("%H:%M")).to eq "00:00"
      expect(@event.end_at).to eql(@event.zoned_start_at)

      # Change the date but keep the all day flag as true
      @event.update_attributes({ :start_at => @event.start_at - 1.day, :end_at => @event.end_at - 1.day, :all_day => true })
      expect(@event.all_day?).to be_truthy
      expect(@event.all_day_date.strftime("%Y-%m-%d")).to eq "2008-09-02"
      expect(@event.zoned_start_at.strftime("%H:%M")).to eq "00:00"
      expect(@event.end_at).to eql(@event.zoned_start_at)
    end
  end

  context "ical" do
    describe "to_ics" do
      it "should not fail for null times" do
        calendar_event_model(:start_at => "", :end_at => "")
        res = @event.to_ics
        expect(res).not_to be_nil
        expect(res.match(/DTSTART/)).to be_nil
      end

      it "should not return data for null times" do
        calendar_event_model(:start_at => "", :end_at => "")
        res = @event.to_ics(in_own_calendar: false)
        expect(res).to be_nil
      end

      it "should return string data for events with times" do
        Time.zone = 'UTC'
        calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
        # force known value so we can check serialization
        @event.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
        res = @event.to_ics
        expect(res).not_to be_nil
        expect(res.match(/DTSTART:20080903T115500Z/)).not_to be_nil
        expect(res.match(/DTEND:20080903T120000Z/)).not_to be_nil
        expect(res.match(/DTSTAMP:20080903T120500Z/)).not_to be_nil
      end

      it "should return string data for events with times in correct tz" do
        Time.zone = 'Alaska' # -0800
        calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
        # force known value so we can check serialization
        @event.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
        res = @event.to_ics
        expect(res).not_to be_nil
        expect(res.match(/DTSTART:20080903T195500Z/)).not_to be_nil
        expect(res.match(/DTEND:20080903T200000Z/)).not_to be_nil
        expect(res.match(/DTSTAMP:20080903T200500Z/)).not_to be_nil
      end

      it "should return data for events with times" do
        Time.zone = 'UTC'
        calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
        # force known value so we can check serialization
        @event.updated_at = Time.at(1220443500) # 3 Sep 2008 12:05pm (UTC)
        res = @event.to_ics(in_own_calendar: false)
        expect(res).not_to be_nil
        expect(res.start.icalendar_tzid).to eq 'UTC'
        expect(res.start.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
        expect(res.end.icalendar_tzid).to eq 'UTC'
        expect(res.end.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:00pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
        expect(res.dtstamp.icalendar_tzid).to eq 'UTC'
        expect(res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      end

      it "should return data for events with times in correct tz" do
        Time.zone = 'Alaska' # -0800
        calendar_event_model(:start_at => "Sep 3 2008 11:55am", :end_at => "Sep 3 2008 12:00pm")
        # force known value so we can check serialization
        @event.updated_at = Time.at(1220472300) # 3 Sep 2008 12:05pm (AKDT)
        res = @event.to_ics(in_own_calendar: false)
        expect(res).not_to be_nil
        expect(res.start.icalendar_tzid).to eq 'UTC'
        expect(res.start.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 11:55am").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
        expect(res.end.icalendar_tzid).to eq 'UTC'
        expect(res.end.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:00pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
        expect(res.end.icalendar_tzid).to eq 'UTC'
        expect(res.dtstamp.strftime('%Y-%m-%dT%H:%M:%S')).to eq Time.zone.parse("Sep 3 2008 12:05pm").in_time_zone('UTC').strftime('%Y-%m-%dT%H:%M:00')
      end

      it 'should not fail with no date for all_day event' do
        res = calendar_event_model(all_day: true).to_ics
        expect(res).not_to be_nil
      end

      it "should return string dates for all_day events" do
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        expect(@event.all_day).to eql(true)
        expect(@event.end_at).to eql(@event.start_at)
        res = @event.to_ics
        expect(res.match(/DTSTART;VALUE=DATE:20080903/)).not_to be_nil
        expect(res.match(/DTEND;VALUE=DATE:20080903/)).not_to be_nil
      end

      it "should return a plain-text description" do
        calendar_event_model(:start_at => "Sep 3 2008 12:00am", :description => <<-HTML)
      <p>
        This assignment is due December 16th. <b>Please</b> do the reading.
        <br/>
        <a href="www.example.com">link!</a>
      </p>
      HTML
        ev = @event.to_ics(in_own_calendar: false)
        expect(ev.description).to match_ignoring_whitespace("This assignment is due December 16th. Please do the reading.


[link!](www.example.com)")
        expect(ev.x_alt_desc).to eq @event.description
      end

      it "should not add verifiers to files unless course or attachment is public" do
        attachment_model(:context => course_factory)
        html = %{<div><a href="/courses/#{@course.id}/files/#{@attachment.id}/download?wrap=1">here</a></div>}
        calendar_event_model(:start_at => "Sep 3 2008 12:00am", :description => html)
        ev = @event.to_ics(in_own_calendar: false)
        expect(ev.description).to_not include("verifier")

        @attachment.file_state = 'public'
        @attachment.save!

        AdheresToPolicy::Cache.clear
        ev = @event.to_ics(in_own_calendar: false)
        expect(ev.description).to include("verifier")

        @attachment.file_state = 'hidden'
        @attachment.save!
        @course.offer
        @course.is_public = true
        @course.save!

        AdheresToPolicy::Cache.clear
        ev = @event.to_ics(in_own_calendar: false)
        expect(ev.description).to include("verifier")
      end

      it "should work with media comments in course section events" do
        course_model
        @course.offer
        @course.is_public = true

        @course.media_objects.create!(:media_id => '0_12345678')
        event = @course.default_section.calendar_events.create!(:start_at => "Sep 3 2008 12:00am",
          :description => %{<p><a id="media_comment_0_12345678" class="instructure_inline_media_comment video_comment" href="/media_objects/0_12345678">media comment</a></p>})
        event.effective_context_code = @course.asset_string
        event.save!

        ics = event.to_ics
        expect(ics.gsub(/\s+/, '')).to include("/courses/#{@course.id}/media_download?entryId=0_12345678")
      end

      it "should add a course code to the summary of an event that has a course as an effective_context" do
        course_model
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        @event.effective_context_code = @course.asset_string
        ics = @event.to_ics
        expect(ics).to include("SUMMARY:#{@event.title} [#{@course.course_code}]")
      end

      it "should add a course code to the summary of an event that has a course as its effective_context's context" do
        course_model
        group(:context => @course)
        calendar_event_model(:start_at => "Sep 3 2008 12:00am")
        @event.effective_context_code = @group.asset_string
        ics = @event.to_ics
        expect(ics).to include("SUMMARY:#{@event.title} [#{@course.course_code}]")
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
      expect(CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).sort_by(&:id)).
        to eql [@e1]

      expect(CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string, @student.asset_string]).sort_by(&:id)).
        to eql [@e1, @e2]
    end

    it "should return events implicitly tied to the contexts (via effective_context_string)" do
      @teacher = user_factory
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

      expect(CalendarEvent.for_user_and_context_codes(@student, [@student.asset_string]).sort_by(&:id)).
        to eql [@e2] # none of the appointments even though they technically are on the user

      expect(CalendarEvent.for_user_and_context_codes(@student, [section.asset_string]).sort_by(&:id)).
        to eql [] # none of the appointments even though they technically are on the section

      expect(CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string, @student.asset_string]).sort_by(&:id)).
        to eql [@e1, @e2, a1, a2, pe, se]

      expect(CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).sort_by(&:id)).
        to eql [@e1, a1, a2, pe, se]

      expect(CalendarEvent.for_user_and_context_codes(@student, [@course.asset_string]).events_without_child_events.sort_by(&:id)).
        to eql [@e1, a1, a2, se]

      expect(CalendarEvent.for_user_and_context_codes(@student, [g1.asset_string, g2.asset_string, g3.asset_string]).sort_by(&:id)).
        to eql [ae1, ae2, ae3]

      expect(CalendarEvent.for_user_and_context_codes(@teacher, [g1.asset_string, g2.asset_string, g3.asset_string]).events_with_child_events.sort_by(&:id)).
        to eql [ae1, ae2]
    end
  end

  context "notifications" do
    before :once do
      Notification.create(:name => 'New Event Created', :category => "TestImmediately")
      Notification.create(:name => 'Event Date Changed', :category => "TestImmediately")
      course_with_student(:active_all => true)
      @teacher = user_factory(active_all: true)
      @course.enroll_teacher(@teacher).accept!
      channel = @student.communication_channels.create(:path => "test_channel_email_#{user_factory.id}", :path_type => "email")
      channel.confirm
    end

    context "with calendar event created" do
      before :once do
        course_with_student(active_all: true)
        course_with_observer(active_all: true, active_cc: true, associated_user_id: @student.id, course: @course)
        @event1 = @course.calendar_events.build(title: "test")
        @event1.updating_user = @teacher
        @event1.save!
      end

      context "creation notification" do
        before :once do
          @users = @event1.messages_sent["New Event Created"].map(&:user_id)
        end

        it "should send to participants", priority: "1", test_id: 186751 do
          expect(@event1.messages_sent).to be_include("New Event Created")
          expect(@users).to include(@student.id)
        end

        it "should have correct URL" do
          @event1.messages_sent["New Event Created"].each do |message|
            expect(message.url).to include "/courses/#{@course.id}/calendar_events/#{@event1.id}"
          end
        end

        it "should not send to creating teacher" do
          expect(@users).not_to include(@teacher.id)
        end

        it "sends to observers" do
          expect(@users).to include(@observer.id)
        end
      end

      context "with event date edited" do
        before :once do
          @event1.update_attributes(start_at: Time.now, end_at: Time.now)
        end

        context "edit notification" do
          before :once do
            @users = @event1.messages_sent["Event Date Changed"].map(&:user_id)
          end

          it "should send to participants", priority: "1", test_id: 193162 do
            expect(@event1.messages_sent).to be_include("Event Date Changed")
            expect(@users).to include(@student.id)
          end

          it "should have correct url" do
            @event1.messages_sent["Event Date Changed"].each do |message|
              expect(message.url).to include "/courses/#{@course.id}/calendar_events/#{@event1.id}"
            end
          end

          it "should not send to editing teacher" do
            expect(@users).not_to include(@teacher.id)
          end

          it "sends to observers" do
            expect(@users).to include(@observer.id)
          end
        end
      end
    end

    it "should not send notifications to participants if hidden" do
      course_with_student(:active_all => true)
      event = @course.calendar_events.build(:title => "test", :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}])
      event.updating_user = @teacher
      event.save!
      expect(event.messages_sent).to be_empty

      event.update_attribute(:child_event_data, [{:start_at => "2012-01-02", :end_at => "2012-01-03", :context_code => @course.default_section.asset_string}])
      expect(event.messages_sent).to be_empty
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

        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher).accept!

        student_in_course(:course => @course, :active_all => true)
        @student2 = @user

        c1 = group_category
        @group = c1.groups.create(:context => @course)
        @group.users << @student1 << @student2

        @ag2 = AppointmentGroup.create!(:title => "test", :contexts => [@course], :sub_context_codes => [c1.asset_string])
        @ag2.publish!
        @appointment2 = @ag2.appointments.create(:start_at => '2012-01-01 12:00:00', :end_at => '2012-01-01 13:00:00')

        course_with_observer(active_all: true, course: @course, associated_user_id: @student1.id)

        [@teacher, @student1, @student2, @observer].each do |user|
          channel = user.communication_channels.create(:path => "test_channel_email_#{user.id}", :path_type => "email")
          channel.confirm
        end

        @expected_users = [@teacher.id, @student1.id, @student2.id, @observer.id].sort
      end

      def message_recipients_for(notification_name)
        Message.where(notification_id: BroadcastPolicy.notification_finder.by_name(notification_name), user_id: @expected_users).pluck(:user_id).sort
      end

      it "should notify all participants except the person reserving", priority: "1", test_id: 193149 do
        reservation = @appointment2.reserve_for(@group, @student1)
        expect(message_recipients_for('Appointment Reserved For User')).to eq @expected_users - [@student1.id, @teacher.id]
      end

      it "should notify all participants except the person canceling the reservation" do
        reservation = @appointment2.reserve_for(@group, @student1)
        reservation.updating_user = @student1
        reservation.destroy
        expect(message_recipients_for('Appointment Deleted For User')).to eq @expected_users - [@student1.id, @teacher.id]
      end

      it "should notify participants if teacher deletes the appointment time slot", priority: "1", test_id: 193148 do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        @appointment2.destroy
        expect(message_recipients_for('Appointment Deleted For User')).to eq @expected_users - [@teacher.id]
      end

      it "should notify all participants when the the time slot is canceled", priority: "1", test_id: 502005 do
        reservation = @appointment2.reserve_for(@group, @student1)
        @appointment2.updating_user = @teacher
        user_evt = CalendarEvent.where(context_type: 'Group').first
        user_evt.updating_user = @teacher
        user_evt.destroy
        expect(message_recipients_for('Appointment Deleted For User')).to eq @expected_users - [@teacher.id]
      end

      it "should notify admins and observers when a user reserves", priority: "1", test_id: 193144 do
        reservation = @appointment.reserve_for(@student1, @student1)
        expect(reservation.messages_sent).to be_include("Appointment Reserved By User")
        expect(reservation.messages_sent["Appointment Reserved By User"].map(&:user_id).sort.uniq).to eql (@course.instructors.map(&:id) + [@observer.id]).sort
      end

      it "should notify admins and observers when a user reserves a group appointment" do
        reservation = @appointment2.reserve_for(@group, @student1)
        expect(reservation.messages_sent).to be_include("Appointment Reserved By User")
        expect(reservation.messages_sent["Appointment Reserved By User"].map(&:user_id).sort.uniq).to eql (@course.instructors.map(&:id) + [@observer.id]).sort
      end

      it "should notify admins and observers when a user cancels", priority: "1", test_id: 193147 do
        reservation = @appointment.reserve_for(@student1, @student1)
        reservation.updating_user = @student1
        reservation.destroy
        expect(reservation.messages_sent).to be_include("Appointment Canceled By User")
        expect(reservation.messages_sent["Appointment Canceled By User"].map(&:user_id).sort.uniq).to eql (@course.instructors.map(&:id) + [@observer.id]).sort
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

      expect(appointment.reserve_for(@student1, @student1)).not_to be_nil
      expect(appointment.reserve_for(@other_student, @other_student)).not_to be_nil
      expect { appointment.reserve_for(@unlucky_student, @unlucky_student) }.to raise_error(CalendarEvent::ReservationError)
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

      expect(appointment.reserve_for(@student1, @student1)).not_to be_nil
      expect(appointment.reserve_for(s1, s1)).not_to be_nil
      expect(appointment.reserve_for(s2, s2)).not_to be_nil
      expect { appointment.reserve_for(s3, s3) }.to raise_error(CalendarEvent::ReservationError)

      # should be able to unset the participant limit too
      appointment.participants_per_appointment = nil
      appointment.save!
      expect(appointment.reserve_for(s3, s3)).not_to be_nil
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
      expect(appointment.participants_per_appointment).to eql 3

      appointment.participants_per_appointment = 2
      appointment.save!
      expect(appointment.read_attribute(:participants_per_limit)).to be_nil
      expect(appointment.override_participants_per_appointment?).to be_falsey
      expect(appointment.participants_per_appointment).to eql 2
    end

    it "should not let participants exceed max_appointments_per_participant" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :max_appointments_per_participant => 1,
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00'], ['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      appointment.reserve_for(@student1, @student1)
      expect { appointment2.reserve_for(@student1, @student1) }.to raise_error(CalendarEvent::ReservationError)
    end

    it "should cancel existing reservations if cancel_existing = true and the appointment is in the future" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :max_appointments_per_participant => 1,
        :new_appointments => [[1.hour.from_now, 2.hours.from_now], [3.hours.from_now, 4.hours.from_now]]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      r1 = appointment.reserve_for(@student1, @student1)
      expect { appointment2.reserve_for(@student1, @student1, :cancel_existing => true) }.not_to raise_error
      expect(r1.reload).to be_deleted
    end

    it "should refuse to cancel existing reservations if cancel_existing = true and the appointment is in the past" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :max_appointments_per_participant => 1,
        :new_appointments => [[2.hours.ago, 1.hour.ago], [1.hour.from_now, 2.hours.from_now]]
      )
      ag.publish!
      appointment = ag.appointments.first
      appointment2 = ag.appointments.last

      r1 = appointment.reserve_for(@student1, @student1)
      expect { appointment2.reserve_for(@student1, @student1, :cancel_existing => true) }.to raise_error(CalendarEvent::ReservationError)
      expect(r1.reload).not_to be_deleted
    end

    it "should save comments with appointment" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course],
                                   :max_appointments_per_participant => 1,
                                   :new_appointments => [['2012-01-01 12:00:00',
                                                          '2012-01-01 13:00:00'],
                                                         ['2012-01-01 13:00:00',
                                                          '2012-01-01 14:00:00']
                                                        ]
                                  )
      ag.publish!
      appointment = ag.appointments.first
      r1 = appointment.reserve_for(@student1, @student1, :comments => "my appointment notes")
      r1.reload
      expect(r1.comments).to eq("my appointment notes")
    end

    it "should enforce the section" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course.course_sections.create],
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      ag.publish!
      appointment = ag.appointments.first

      expect { appointment.reserve_for(@student1, @student1) }.to raise_error(CalendarEvent::ReservationError)
    end

    it "should enforce the group category" do
      teacher = user_factory(active_all: true)
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

      expect { appointment.reserve_for(g2, teacher) }.to raise_error(CalendarEvent::ReservationError)
      expect { appointment.reserve_for(g1, teacher) }.not_to raise_error
    end

    it "should only accept users with StudentEnrollments as valid user participants" do
      expect(@ag.eligible_participant?(@student1)).to be_truthy
      expect { @appointment.reserve_for(@student1, @student1) }.not_to raise_error

      # both a student and a teacher
      student_in_course(:course => @course, :active_all => true)
      @user.teacher_enrollments.create!(:course => @course)
      expect(@ag.eligible_participant?(@user)).to be_truthy
      expect { @appointment.reserve_for(@user, @user) }.not_to raise_error

      # just a teacher
      user_factory(active_all: true)
      @course.enroll_teacher(@user).accept!
      expect(@ag.eligible_participant?(@user)).to be_falsey
      expect { @appointment.reserve_for(@user, @user) }.to raise_error(CalendarEvent::ReservationError)
    end

    it "should lock the appointment once it is reserved" do
      expect(@appointment).to be_active
      expect(@appointment.reserve_for(@student1, @student1)).not_to be_nil
      expect(@appointment).to be_locked
    end

    it "should unlock the appointment when the last reservation is canceled" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 2,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      appointment = ag.appointments.first
      student_in_course(:course => @course, :active_all => true)
      @other_student = @user

      expect(appointment).to be_active
      r1 = appointment.reserve_for(@student1, @student1).reload
      expect(appointment).to be_locked
      r2 = appointment.reserve_for(@other_student, @other_student).reload
      r2.destroy
      expect(appointment.reload).to be_locked
      r1.destroy
      expect(appointment.reload).to be_active
    end

    it "should copy the group attributes to the initial appointments" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :description => "hello\nworld",
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      e = ag.appointments.first
      expect(e.title).to eql 'test'
      expect(e.description).to eql "hello<br/>\r\nworld"
    end

    it "should copy changed group attributes to existing appointments" do
      @ag.update_attributes(:title => 'changed!', :description => "test\n123")
      e = @ag.appointments.first.reload
      expect(e.title).to eql 'changed!'
      expect(e.description).to eql "test<br/>\r\n123"
    end

    it "should not copy group description if appointment is overridden" do
      @appointment.description = "pizza party"
      @appointment.save!

      @ag.description = "boring meeting"
      @ag.save!

      expect(@appointment.description).to eq "pizza party"
      expect(@ag.description).to eq "boring meeting"
    end

    it "should copy the group attributes to subsequent appointments" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course])
      ag.update_attributes(
        :title => 'haha',
        :new_appointments => [['2012-01-01 12:00:00', '2012-01-01 13:00:00']]
      )
      e = ag.appointments.first
      expect(e.title).to eql 'haha'
    end

    it "should ignore changes to locked attributes on the appointment" do
      @appointment.update_attributes(:start_at => '2012-01-01 12:30:00', :title => 'you wish')
      expect(@appointment.title).to eql 'test'
      expect(@appointment.start_at).to eql Time.parse('2012-01-01 12:30:00Z')
    end

    it "should allow a user to re-reserve a slot after canceling" do
      ag = AppointmentGroup.create(:title => "test", :contexts => [@course], :participants_per_appointment => 1,
        :new_appointments => [['2012-01-01 13:00:00', '2012-01-01 14:00:00']]
      )
      appointment = ag.appointments.first

      r1 = appointment.reserve_for(@student1, @student1).reload
      expect(ag.reload.available_slots).to eql 0
      r1.destroy
      expect(ag.reload.available_slots).to eql 1
      expect { appointment.reserve_for(@student1, @student1) }.not_to raise_error
      expect(ag.reload.available_slots).to eql 0
    end

    it "should always allow editing the description on an appointment" do
      @appointment.update_attribute :workflow_state, "locked"
      @appointment.description = "bacon"
      @appointment.save!
      expect(@appointment.description).to eq "bacon"
    end
  end

  context "child_events" do
    it "should delete child events when deleting the parent" do
      calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
      child = @event.child_events.build
      child.context = user_factory
      child.save!

      @event.destroy

      expect(@event.reload).to be_deleted
      expect(child.reload).to be_deleted
    end

    context "bulk updating" do
      before :once do
        course_with_teacher
      end

      it "should validate child events" do
        expect {
          @course.calendar_events.create! :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string}
            ]
        }.to raise_error(/Can't update child events unless an updating_user is set/)

        expect {
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => "invalid_1"}
            ]
          event.updating_user = @user
          event.save!
        }.to raise_error(/Invalid child event context/)

        expect {
          other_section = Course.create!.default_section
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => other_section.asset_string}
            ]
          event.updating_user = @user
          event.save!
        }.to raise_error(/Invalid child event context/)

        expect {
          event = @course.calendar_events.build :title => "ohai",
            :child_event_data => [
              {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string},
              {:start_at => "2012-01-01 13:00:00", :end_at => "2012-01-01 14:00:00", :context_code => @course.default_section.asset_string}
            ]
          event.updating_user = @user
          event.save!
        }.to raise_error(/Duplicate child event contexts/)
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
        expect(events.map(&:context_code)).to eql [@course.default_section.asset_string, s2.asset_string]
        expect(events.map(&:effective_context_code).uniq).to eql [@course.asset_string]
        expect(e1.start_at).to eql events.first.start_at
        expect(e1.end_at).to eql events.last.end_at
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
        expect(events2.size).to eql 2

        expect(events1.first.reload).to eql events2.first
        expect(events1.last.reload).to be_deleted
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
        expect { e1.save! }.not_to raise_error
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
        expect(e1.child_events.reload).to be_empty
      end
    end

    context "cascading" do
      it "should copy cascaded attributes when creating a child event" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.save!
        expect(child.start_at).to be_nil
        expect(child.title).to eql @event.title
      end

      it "should update cascaded attributes on the child events whenever the parent is updated" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.save!
        child.reload
        orig_start_at = child.start_at

        @event.title = 'asdf'
        @event.start_at = Time.now.utc
        @event.save!
        expect(child.reload.title).to eql 'asdf'
        expect(child.start_at).to eql orig_start_at
      end

      it "should disregard attempted changes to cascaded attributes" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.save!
        child.reload
        orig_start_at = child.start_at

        child.title = 'asdf'
        child.start_at = Time.now.utc
        child.save!
        expect(child.title).to eql 'some event'
        expect(child.start_at).not_to eql orig_start_at
      end
    end

    context "locking" do
      it "should copy all attributes when creating a locked child event" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.workflow_state = :locked
        child.save!
        expect(child.start_at).to eql @event.start_at
        expect(child.title).to eql @event.title
      end

      it "should update locked child events whenever the parent is updated" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.workflow_state = :locked
        child.save!

        @event.title = 'asdf'
        @event.save!
        expect(child.reload.title).to eql 'asdf'
      end

      it "should disregard attempted changes to locked attributes" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        child = @event.child_events.build
        child.context = user_factory
        child.workflow_state = :locked
        child.save!

        child.title = 'asdf'
        child.save!
        expect(child.title).to eql 'some event'
      end

      it "should unlock events when the last child is deleted" do
        calendar_event_model(:start_at => "Sep 3 2008", :title => "some event")
        @event.workflow_state = :locked
        @event.save!
        child = @event.child_events.build
        child.context = user_factory
        child.workflow_state = :locked
        child.save!

        child.destroy
        expect(@event.reload).to be_active
        expect(child.reload).to be_deleted
      end
    end
  end
end
