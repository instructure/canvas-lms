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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe CalendarEventsApiController, :type => :integration do
  before do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
    @me = @user
  end

  context 'events' do
    expected_fields = [
      'all_day', 'all_day_date', 'child_events_count', 'context_code',
      'created_at', 'description', 'end_at', 'id', 'location_address',
      'location_name', 'start_at', 'title', 'updated_at', 'url',
      'workflow_state'
    ]

    it 'should return events within the given date range' do
      e1 = @course.calendar_events.create(:title => '1', :start_at => '2012-01-07 12:00:00')
      e2 = @course.calendar_events.create(:title => '2', :start_at => '2012-01-08 12:00:00')
      e3 = @course.calendar_events.create(:title => '3', :start_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08'})
      json.size.should eql 1
      json.first.keys.sort.should eql expected_fields
      json.first.slice('title', 'start_at', 'id').should eql({'id' => e2.id, 'title' => '2', 'start_at' => '2012-01-08T12:00:00Z'})
    end

    it 'should paginate events' do
      ids = 25.times.map { |i| @course.calendar_events.create(:title => "#{i}", :start_at => '2012-01-08 12:00:00').id }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10'})
      json.size.should eql 10
      response.headers['Link'].should match(%r{</api/v1/calendar_events\?.*page=2.*>; rel="next",</api/v1/calendar_events\?.*page=1.*>; rel="first",</api/v1/calendar_events\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10', :page => '3'})
      json.size.should eql 5
      response.headers['Link'].should match(%r{</api/v1/calendar_events\?.*page=2.*>; rel="prev",</api/v1/calendar_events\?.*page=1.*>; rel="first",</api/v1/calendar_events\?.*page=3.*>; rel="last"})
    end

    it 'should ignore invalid end_dates' do
      @course.calendar_events.create(:title => 'e', :start_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-07'})
      json.size.should eql 1
    end

    it 'should return events from up to 10 contexts' do
      contexts = [@course.asset_string]
      contexts.concat 15.times.map { |i|
        course_with_teacher(:active_all => true, :user => @me)
        @course.calendar_events.create(:title => "#{i}", :start_at => '2012-01-08 12:00:00')
        @course.asset_string
      }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      json.size.should eql 9 # first context has no events
    end

    it 'should ignore contexts the user cannot access' do
      contexts = [@course.asset_string]
      contexts.concat 5.times.map { |i|
        course()
        @course.calendar_events.create(:title => "#{i}", :start_at => '2012-01-08 12:00:00')
        @course.asset_string
      }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      json.size.should eql 0 # first context has no events
    end

    it 'should return undated events' do
      @course.calendar_events.create(:title => 'undated')
      @course.calendar_events.create(:title => "dated", :start_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?undated=1&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                        :context_codes => ["course_#{@course.id}"], :undated => '1'})
      json.size.should eql 1
      json.first['start_at'].should be_nil
    end

    context 'appointments' do
      it 'should include appointments for teachers (with participant info)' do
        ag1 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        event1 = ag1.appointments.first
        student_ids = []
        3.times {
          event1.reserve_for(student_in_course(:course => @course, :active_all => true).user, @me)
          student_ids << @user.id
        }

        cat = @course.group_categories.create
        ag2 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :sub_context_code => cat.asset_string, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        event2 = ag2.appointments.first
        group_ids = []
        group_student_ids = []
        3.times {
          g = cat.groups.create(:context => @course)
          g.users << user
          event2.reserve_for(g, @me)
          group_ids << g.id
          group_student_ids << @user.id
        }

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [@course.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        json.size.should eql 2

        e1json = json.first
        e1json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'available_slots', 'child_events', 'reserve_url']).sort)
        e1json['reserve_url'].should match %r{calendar_events/#{event1.id}/reservations/%7B%7B%20id%20%7D%7D}
        e1json['child_events'].size.should eql 3
        e1json['child_events'].each do |e|
          e.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'user']).sort)
          student_ids.should include e['user']['id']
        end

        e2json = json.last
        e2json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'available_slots', 'child_events', 'reserve_url']).sort)
        e2json['reserve_url'].should match %r{calendar_events/#{event2.id}/reservations/%7B%7B%20id%20%7D%7D}
        e2json['child_events'].size.should eql 3
        e2json['child_events'].each do |e|
          e.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'group']).sort)
          group_ids.should include e['group']['id']
          group_student_ids.should include e['group']['users'].first['id']
        end
      end

      it 'should return events from reservable appointment_groups, if specified as a context' do
        course(:active_all => true)
        @teacher = @course.admins.first

        student_in_course :course => @course, :user => @me, :active_all => true
        group1 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        group1.publish!
        event1 = group1.appointments.first
        3.times { event1.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher) }

        cat = @course.group_categories.create
        group2 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :sub_context_code => cat.asset_string, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        group2.publish!
        event2 = group2.appointments.first
        g = cat.groups.create(:context => @course)
        g.users << @me
        event2.reserve_for(g, @teacher)

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{group1.asset_string}&context_codes[]=#{group2.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [group1.asset_string, group2.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        json.size.should eql 2
        ejson = json.first
        ejson.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'reserved', 'reserve_url', 'available_slots']).sort)
        ejson['reserve_url'].should match %r{calendar_events/#{event1.id}/reservations/#{@me.id}}
        ejson['reserved'].should be_false
        ejson['available_slots'].should eql 1

        ejson = json.last
        ejson.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'reserved', 'reserve_url', 'available_slots', 'child_events']).sort)
        ejson['reserve_url'].should match %r{calendar_events/#{event2.id}/reservations/#{g.id}}
        ejson['reserved'].should be_true
        ejson['available_slots'].should eql 3
      end

      it 'should return child_events for students, if the appointment group allows it' do
        course(:active_all => true)
        @teacher = @course.admins.first

        student_in_course :course => @course, :user => @me, :active_all => true
        group = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :participant_visibility => 'protected', :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        group.publish!
        event = group.appointments.first
        event.reserve_for(@me, @teacher)
        2.times { event.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher) }

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{group.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [group.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        json.size.should eql 1
        ejson = json.first
        ejson.keys.should include 'child_events'
        ejson['child_events'].size.should eql ejson['child_events_count']
        ejson['child_events'].size.should eql 3
        ejson['child_events'].select{ |e| e['url'] }.size.should eql 1
        own_reservation = ejson['child_events'].select{ |e| e['own_reservation'] }
        own_reservation.size.should eql 1
        own_reservation.first.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'own_reservation', 'user']).sort)
      end

      it 'should return own appointment_participant events in their effective contexts' do
        course(:active_all => true)
        @teacher = @course.admins.first
        student_in_course :course => @course, :user => @me, :active_all => true
        otherguy = student_in_course(:course => @course, :active_all => true).user
        ag1 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        ag1.publish!
        event1 = ag1.appointments.first
        my_personal_appointment = event1.reserve_for(@me, @me)
        event1.reserve_for(otherguy, otherguy)

        cat = @course.group_categories.create
        mygroup = cat.groups.create(:context => @course)
        mygroup.users << @me
        othergroup = cat.groups.create(:context => @course)
        othergroup.users << otherguy
        @me.reload
        ag2 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :sub_context_code => cat.asset_string, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
        ag2.publish!
        event2 = ag2.appointments.first
        my_group_appointment = event2.reserve_for(mygroup, @me)
        event2.reserve_for(othergroup, otherguy)

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [@course.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        # the group appointment won't show on the course calendar
        json.size.should eql 1
        json.first.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
        json.first['id'].should eql my_personal_appointment.id

        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{mygroup.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [mygroup.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        json.size.should eql 1
        json.first.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
        json.first['id'].should eql my_group_appointment.id

        # if we go look at those appointment slots, they now show as reserved
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{ag1.asset_string}&context_codes[]=#{ag2.asset_string}", {
                          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
                          :context_codes => [ag1.asset_string, ag2.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        json.size.should eql 2
        json.each do |e|
          e.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'reserved', 'reserve_url', 'available_slots', 'child_events']).sort)
          e['reserved'].should be_true
          e['child_events_count'].should eql 2
          e['child_events'].size.should eql 1 # can't see otherguy's stuff
          e['available_slots'].should eql 2
        end
        json.first['child_events'].first.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'own_reservation', 'user']).sort)
        json.last['child_events'].first.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url', 'own_reservation', 'group']).sort)
      end

      context "reservations" do
        def prepare(as_student = false)
          Notification.create! :name => 'Appointment Canceled By User', :category => "TestImmediately"

          if as_student
            course(:active_all => true)
            @teacher = @course.admins.first
            student_in_course :course => @course, :user => @me, :active_all => true

            channel = @teacher.communication_channels.create! :path => "test_channel_email_#{@teacher.id}", :path_type => "email"
            channel.confirm
          end

          student_in_course(:course => @course, :user => (@other_guy = user), :active_all => true)

          @ag1 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
          @ag1.publish!
          @event1 = @ag1.appointments.first

          cat = @course.group_categories.create
          @group = cat.groups.create(:context => @course)
          @group.users << @me
          @group.users << @other_guy
          @other_group = cat.groups.create(:context => @course)
          @me.reload
          @ag2 = @course.appointment_groups.create(:title => "something", :participants_per_appointment => 4, :sub_context_code => cat.asset_string, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]])
          @ag2.publish!
          @event2 = @ag2.appointments.first

          @user = @me
        end

        it "should reserve the appointment for @current_user" do
          prepare(true)
          json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
          json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
          json['appointment_group_id'].should eql(@ag1.id)

          json = api_call(:post, "/api/v1/calendar_events/#{@event2.id}/reservations", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event2.id.to_s})
          json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
          json['appointment_group_id'].should eql(@ag2.id)
        end

        it "should not allow students to reserve non-appointment calendar_events" do
          prepare(true)
          e = @course.calendar_events.create
          raw_api_call(:post, "/api/v1/calendar_events/#{e.id}/reservations", {
                        :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => e.id.to_s})
          JSON.parse(response.body)['status'].should == 'unauthorized'
        end

        it "should not allow students to reserve an appointment twice" do
          prepare(true)
          json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
          response.should be_success
          raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                        :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
          JSON.parse(response.body).should eql [["reservation", "participant has already reserved this appointment"]]
        end

        it "should not allow students to specify the participant" do
          prepare(true)
          raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
                        :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
          JSON.parse(response.body).should eql [["reservation", "invalid participant"]]
        end

        it "should allow admins to specify the participant" do
          prepare
          json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
          json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
          json['appointment_group_id'].should eql(@ag1.id)

          json = api_call(:post, "/api/v1/calendar_events/#{@event2.id}/reservations/#{@group.id}", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event2.id.to_s, :participant_id => @group.id.to_s})
          json.keys.sort.should eql((expected_fields + ['appointment_group_id', 'appointment_group_url']).sort)
          json['appointment_group_id'].should eql(@ag2.id)
        end

        it "should reject invalid participants" do
          prepare
          raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@me.id}", {
                        :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @me.id.to_s})
          JSON.parse(response.body).should eql [["reservation", "invalid participant"]]
        end

        it "should notify the teacher when appointment is cancelled" do
          prepare(true)
          json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                            :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})

          reservation = CalendarEvent.find(json["id"])

          raw_api_call(:delete, "/api/v1/calendar_events/#{reservation.id}", {
                       :controller => 'calendar_events_api', :action => 'destroy', :format => 'json', :id => reservation.id.to_s})

          message = Message.last
          message.notification_name.should == 'Appointment Canceled By User'
          message.to.should == "test_channel_email_#{@teacher.id}"
        end
      end
    end

    it 'should get a single event' do
      event = @course.calendar_events.create(:title => 'event')
      json = api_call(:get, "/api/v1/calendar_events/#{event.id}", {
                        :controller => 'calendar_events_api', :action => 'show', :id => event.id.to_s, :format => 'json'})
      json.keys.sort.should eql expected_fields
      json.slice('title', 'id').should eql({'id' => event.id, 'title' => 'event'})
    end

    it 'should enforce permissions' do
      event = course.calendar_events.create(:title => 'event')
      raw_api_call(:get, "/api/v1/calendar_events/#{event.id}", {
                     :controller => 'calendar_events_api', :action => 'show', :id => event.id.to_s, :format => 'json'})
      JSON.parse(response.body)['status'].should == 'unauthorized'
    end

    it 'should create a new event' do
      json = api_call(:post, "/api/v1/calendar_events",
                      { :controller => 'calendar_events_api', :action => 'create', :format => 'json' },
                      { :calendar_event => {:context_code => @course.asset_string, :title => "ohai"} })
      response.status.should =~ /201/
      json.keys.sort.should eql expected_fields
      json['title'].should eql 'ohai'
    end

    it 'should update an event' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')

      json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                      { :controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json' },
                      { :calendar_event => {:start_at => '2012-01-09 12:00:00', :title => "ohai"} })
      json.keys.sort.should eql expected_fields
      json['title'].should eql 'ohai'
      json['start_at'].should eql '2012-01-09T12:00:00Z'
    end

    it 'should delete an event' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')
      json = api_call(:delete, "/api/v1/calendar_events/#{event.id}",
                      { :controller => 'calendar_events_api', :action => 'destroy', :id => event.id.to_s, :format => 'json' })
      json.keys.sort.should eql expected_fields
      event.reload.should be_deleted
    end
  end

  context 'assignments' do
    expected_fields = [
      'all_day', 'all_day_date', 'assignment', 'context_code', 'created_at',
      'description', 'end_at', 'id', 'start_at', 'title', 'updated_at', 'url',
      'workflow_state'
    ]

    it 'should return assignments within the given date range' do
      e1 = @course.assignments.create(:title => '1', :due_at => '2012-01-07 12:00:00')
      e2 = @course.assignments.create(:title => '2', :due_at => '2012-01-08 12:00:00')
      e3 = @course.assignments.create(:title => '3', :due_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08'})
      json.size.should eql 1
      json.first.keys.sort.should eql expected_fields
      json.first.slice('title', 'start_at', 'id').should eql({'id' => "assignment_#{e2.id}", 'title' => '2', 'start_at' => '2012-01-08T12:00:00Z'})
    end

    it 'should paginate assignments' do
      ids = 25.times.map { |i| @course.assignments.create(:title => "#{i}", :due_at => '2012-01-08 12:00:00').id }
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10'})
      json.size.should eql 10
      response.headers['Link'].should match(%r{</api/v1/calendar_events\?type=assignment&.*page=2.*>; rel="next",</api/v1/calendar_events\?type=assignment&.*page=1.*>; rel="first",</api/v1/calendar_events\?type=assignment&.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10', :page => '3'})
      json.size.should eql 5
      response.headers['Link'].should match(%r{</api/v1/calendar_events\?type=assignment&.*page=2.*>; rel="prev",</api/v1/calendar_events\?type=assignment&.*page=1.*>; rel="first",</api/v1/calendar_events\?type=assignment&.*page=3.*>; rel="last"})
    end

    it 'should ignore invalid end_dates' do
      @course.assignments.create(:title => 'a', :due_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-07'})
      json.size.should eql 1
    end

    it 'should return assignments from up to 10 contexts' do
      contexts = [@course.asset_string]
      contexts.concat 15.times.map { |i|
        course_with_teacher(:active_all => true, :user => @me)
        @course.assignments.create(:title => "#{i}", :due_at => '2012-01-08 12:00:00')
        @course.asset_string
      }
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      json.size.should eql 9 # first context has no events
    end

    it 'should return undated assignments' do
      @course.assignments.create(:title => 'undated')
      @course.assignments.create(:title => "dated", :due_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&undated=1&context_codes[]=course_#{@course.id}", {
                        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                        :context_codes => ["course_#{@course.id}"], :undated => '1'})
      json.size.should eql 1
      json.first['due_at'].should be_nil
    end

    it 'should get a single assignment' do
      assignment = @course.assignments.create(:title => 'event')
      json = api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                        :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{assignment.id}", :format => 'json'})
      json.keys.sort.should eql expected_fields
      json.slice('title', 'id').should eql({'id' => "assignment_#{assignment.id}", 'title' => 'event'})
    end

    it 'should enforce permissions' do
      assignment = course.assignments.create(:title => 'event')
      raw_api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                     :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{assignment.id}", :format => 'json'})
      JSON.parse(response.body)['status'].should == 'unauthorized'
    end

    it 'should update assignment due dates' do
      assignment = @course.assignments.create(:title => 'undated')

      json = api_call(:put, "/api/v1/calendar_events/assignment_#{assignment.id}",
                      { :controller => 'calendar_events_api', :action => 'update', :id => "assignment_#{assignment.id}", :format => 'json' },
                      { :calendar_event => {:start_at => '2012-01-09 12:00:00'} })
      json.keys.sort.should eql expected_fields
      json['start_at'].should eql '2012-01-09T12:00:00Z'
    end

    it 'should not delete assignments' do
      assignment = @course.assignments.create(:title => 'undated')
      raw_api_call(:delete, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                     :controller => 'calendar_events_api', :action => 'destroy', :id => "assignment_#{assignment.id}", :format => 'json'})
      response.status.should == "404 Not Found"
    end
  end
end
