#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe CalendarEventsApiController, type: :request do
  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
    @me = @user
  end

  context 'events' do
    expected_fields = [
      'all_day', 'all_day_date', 'child_events', 'child_events_count',
      'context_code', 'created_at', 'description', 'end_at', 'hidden', 'html_url',
      'id', 'location_address', 'location_name', 'parent_event_id', 'start_at',
      'title', 'updated_at', 'url', 'workflow_state'
    ]
    expected_slot_fields = (expected_fields + ['appointment_group_id', 'appointment_group_url', 'available_slots', 'participants_per_appointment', 'reserve_url', 'effective_context_code']).sort
    expected_reservation_event_fields = (expected_fields + ['appointment_group_id', 'appointment_group_url', 'effective_context_code']).sort
    expected_reservation_fields = expected_reservation_event_fields - ['child_events']

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

    it 'orders result set by start_at' do
      e2 = @course.calendar_events.create(:title => 'second', :start_at => '2012-01-08 12:00:00')
      e1 = @course.calendar_events.create(:title => 'first', :start_at => '2012-01-07 12:00:00')
      e3 = @course.calendar_events.create(:title => 'third', :start_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'})
      json.size.should eql 3
      json.first.keys.sort.should eql expected_fields
      json.map { |event| event['title'] }.should == %w[first second third]
    end

    it "should default to today's events for the current user if no parameters are specified" do
      Timecop.freeze('2012-01-29 12:00:00 UTC') do
        e1 = @user.calendar_events.create!(:title => "yesterday", :start_at => 1.day.ago) { |c| c.context = @user }
        e2 = @user.calendar_events.create!(:title => "today", :start_at => 0.days.ago) { |c| c.context = @user }
        e3 = @user.calendar_events.create!(:title => "tomorrow", :start_at => 1.days.from_now) { |c| c.context = @user }

        json = api_call(:get, "/api/v1/calendar_events", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json'
        })

        json.size.should eql 1
        json.first.keys.sort.should eql expected_fields
        json.first.slice('id', 'title').should eql({'id' => e2.id, 'title' => 'today'})
      end
    end

    context "timezones" do
      before :once do
        @akst = ActiveSupport::TimeZone.new('Alaska')

        @e1 = @user.calendar_events.create!(:title => "yesterday in AKST", :start_at => @akst.parse('2012-01-28 21:00:00')) { |c| c.context = @user }
        @e2 = @user.calendar_events.create!(:title => "today in AKST", :start_at => @akst.parse('2012-01-29 21:00:00')) { |c| c.context = @user }
        @e3 = @user.calendar_events.create!(:title => "tomorrow in AKST", :start_at => @akst.parse('2012-01-30 21:00:00')) { |c| c.context = @user }

        @user.update_attributes! :time_zone => "Alaska"
      end

      it "shows today's events in user's timezone, even if UTC has crossed into tomorrow" do
        Timecop.freeze(@akst.parse('2012-01-29 22:00:00')) do
          json = api_call(:get, "/api/v1/calendar_events", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json'
          })

          json.size.should eql 1
          json.first.keys.sort.should eql expected_fields
          json.first.slice('id', 'title').should eql({'id' => @e2.id, 'title' => 'today in AKST'})
        end
      end

      it "interprets user-specified date range in the user's time zone" do
        Timecop.freeze(@akst.parse('2012-01-29 22:00:00')) do
          json = api_call(:get, "/api/v1/calendar_events", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json'
          })

          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-28&end_date=2012-01-29&context_codes[]=user_#{@user.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => ["user_#{@user.id}"], :start_date => '2012-01-28', :end_date => '2012-01-29'})
          json.size.should eql 2
          json[0].keys.sort.should eql expected_fields
          json[0].slice('id', 'title').should eql({'id' => @e1.id, 'title' => 'yesterday in AKST'})
          json[1].slice('id', 'title').should eql({'id' => @e2.id, 'title' => 'today in AKST'})
        end
      end
    end

    it 'should paginate events' do
      ids = 5.times.map { |i| @course.calendar_events.create(:title => "#{i}", :start_at => '2012-01-08 12:00:00').id }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=2", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '2'})
      json.size.should eql 2
      response.headers['Link'].should match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=2&page=3", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '2', :page => '3'})
      json.size.should eql 1
      response.headers['Link'].should match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
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
      course_ids = create_courses(15, enroll_user: @me)
      create_records(CalendarEvent, course_ids.map{ |id| {context_id: id, context_type: 'Course', context_code: "course_#{id}", title: "#{id}", start_at: '2012-01-08 12:00:00', workflow_state: 'active'}})
      contexts.concat course_ids.map{ |id| "course_#{id}" }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      json.size.should eql 9 # first context has no events
    end

    it 'should fail with unauthorized if provided a context the user cannot access' do
      contexts = [@course.asset_string]

      # second context the user cannot access
      course()
      @course.calendar_events.create(:title => "unauthorized_course", :start_at => '2012-01-08 12:00:00')
      contexts.push(@course.asset_string)

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'},
                      {}, {}, {:expected_status => 401})
    end

    it "should allow specifying an unenrolled but accessible context" do
      unrelated_course = Course.create!(:account => Account.default, :name => "unrelated course")
      Account.default.account_users.create!(user: @user)
      CalendarEvent.create!(:title => "from unrelated one", :start_at => Time.now, :end_at => 5.hours.from_now) { |c| c.context = unrelated_course }

      json = api_call(:get, "/api/v1/calendar_events",
                      {:controller => "calendar_events_api", :action => "index", :format => "json", },
                      {:start_date => 2.days.ago.strftime("%Y-%m-%d"), :end_date => 2.days.from_now.strftime("%Y-%m-%d"), :context_codes => ["course_#{unrelated_course.id}"]})
      json.size.should == 1
      json.first['title'].should == "from unrelated one"
    end

    def public_course_query(options = {})
      yield @course if block_given?
      @course.save!
      @user = nil

      # both calls are made on a public syllabus access
      # events
      @course.calendar_events.create! :title => 'some event', :start_at => 1.month.from_now
      api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=course_#{@course.id}&type=event&all_events=1", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'event', :all_events => '1',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31'},
               options[:body_params] || {}, options[:headers] || {}, options[:opts] || {})

      # assignments
      @course.assignments.create! :title => 'teh assignment', :due_at => 1.month.from_now
      api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=course_#{@course.id}&type=assignment&all_events=1", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment', :all_events => '1',
          :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31'},
               options[:body_params] || {}, options[:headers] || {}, options[:opts] || {})
    end

    it "should not allow anonymous users to access a non-public context" do
      course(:active_all => true)
      public_course_query(:opts => {:expected_status => 401})
    end

    it "should allow anonymous users to access public context" do
      @user = nil
      public_course_query() do |c|
        c.is_public = true
      end
    end

    it "should allow anonymous users to access a public syllabus" do
      @user = nil
      public_course_query() do |c|
        c.public_syllabus = true
      end
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

    context 'all events' do
      before :once do
        @course.calendar_events.create(:title => 'undated')
        @course.calendar_events.create(:title => 'dated', :start_at => '2012-01-08 12:00:00')
      end

      it 'should return all events' do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1'})
        json.size.should eql 2
      end

      it 'should return all events, ignoring the undated flag' do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :undated => '1'})
        json.size.should eql 2
      end

      it 'should return all events, ignoring the start_date and end_date' do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :start_date => '2012-02-01', :end_date => '2012-02-01'})
        json.size.should eql 2
      end
    end

    context 'appointments' do
      it 'should include appointments for teachers (with participant info)' do
        ag1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
        event1 = ag1.appointments.first
        student_ids = []
        3.times {
          event1.reserve_for(student_in_course(:course => @course, :active_all => true).user, @me)
          student_ids << @user.id
        }

        cat = @course.group_categories.create(name: "foo")
        ag2 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :sub_context_codes => [cat.asset_string], :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
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
        json.sort_by! { |e| e['id'] }

        e1json = json.first
        e1json.keys.sort.should eql(expected_slot_fields)
        e1json['reserve_url'].should match %r{calendar_events/#{event1.id}/reservations/%7B%7B%20id%20%7D%7D}
        e1json['child_events'].size.should eql 3
        e1json['child_events'].each do |e|
          e.keys.sort.should eql((expected_reservation_fields + ['user']).sort)
          student_ids.should include e['user']['id']
        end

        e2json = json.last
        e2json.keys.sort.should eql(expected_slot_fields)
        e2json['reserve_url'].should match %r{calendar_events/#{event2.id}/reservations/%7B%7B%20id%20%7D%7D}
        e2json['child_events'].size.should eql 3
        e2json['child_events'].each do |e|
          e.keys.sort.should eql((expected_reservation_fields + ['group'] - ['effective_context_code']).sort)
          group_ids.should include e['group']['id']
          group_student_ids.should include e['group']['users'].first['id']
        end
      end

      context "basic scenarios" do
        before :once do
          course(:active_all => true)
          @teacher = @course.admins.first
          student_in_course :course => @course, :user => @me, :active_all => true
        end

        it 'should return events from reservable appointment_groups, if specified as a context' do
          group1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
          group1.publish!
          event1 = group1.appointments.first
          3.times { event1.reserve_for(student_in_course(:course => @course, :active_all => true).user, @teacher) }

          cat = @course.group_categories.create(name: "foo")
          group2 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :sub_context_codes => [cat.asset_string], :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
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
          json.sort_by! { |e| e['id'] }

          ejson = json.first
          ejson.keys.sort.should eql((expected_slot_fields + ['reserved']).sort)
          ejson['child_events'].should == [] # not reserved, so no child events can be seen
          ejson['reserve_url'].should match %r{calendar_events/#{event1.id}/reservations/#{@me.id}}
          ejson['reserved'].should be_false
          ejson['available_slots'].should eql 1

          ejson = json.last
          ejson.keys.sort.should eql((expected_slot_fields + ['reserved']).sort)
          ejson['reserve_url'].should match %r{calendar_events/#{event2.id}/reservations/#{g.id}}
          ejson['reserved'].should be_true
          ejson['available_slots'].should eql 3
        end

        it 'should not return child_events for other students, if the appointment group doesn\'t allows it' do
          group = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :participant_visibility => 'private', :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
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
          ejson['child_events_count'].should eql 3
          ejson['child_events'].size.should eql 1
          ejson['child_events'].first['own_reservation'].should be_true
        end

        it 'should return child_events for students, if the appointment group allows it' do
          group = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :participant_visibility => 'protected', :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
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
          ejson['child_events'].select { |e| e['url'] }.size.should eql 1
          own_reservation = ejson['child_events'].select { |e| e['own_reservation'] }
          own_reservation.size.should eql 1
          own_reservation.first.keys.sort.should eql((expected_reservation_fields + ['own_reservation', 'user']).sort)
        end

        it 'should return own appointment_participant events in their effective contexts' do
          otherguy = student_in_course(:course => @course, :active_all => true).user

          course1 = @course
          course_with_teacher(:user => @teacher, :active_all => true)
          course2, @course = @course, course1

          ag1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [course2])
          ag1.publish!
          ag1.contexts = [course1, course2]
          ag1.save!
          event1 = ag1.appointments.first
          my_personal_appointment = event1.reserve_for(@me, @me)
          event1.reserve_for(otherguy, otherguy)

          cat = @course.group_categories.create(name: "foo")
          mygroup = cat.groups.create(:context => @course)
          mygroup.users << @me
          othergroup = cat.groups.create(:context => @course)
          othergroup.users << otherguy
          @me.reload

          ag2 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :sub_context_codes => [cat.asset_string], :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [course1])
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
          json.first.keys.sort.should eql(expected_reservation_event_fields)
          json.first['id'].should eql my_personal_appointment.id

          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{mygroup.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [mygroup.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          json.size.should eql 1
          json.first.keys.sort.should eql(expected_reservation_event_fields - ['effective_context_code'])
          json.first['id'].should eql my_group_appointment.id

          # if we go look at those appointment slots, they now show as reserved
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{ag1.asset_string}&context_codes[]=#{ag2.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [ag1.asset_string, ag2.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          json.size.should eql 2
          json.sort_by! { |e| e['id'] }
          json.each do |e|
            e.keys.sort.should eql((expected_slot_fields + ['reserved']).sort)
            e['reserved'].should be_true
            e['child_events_count'].should eql 2
            e['child_events'].size.should eql 1 # can't see otherguy's stuff
            e['available_slots'].should eql 2
          end
          json.first['child_events'].first.keys.sort.should eql((expected_reservation_fields + ['own_reservation', 'user']).sort)
          json.last['child_events'].first.keys.sort.should eql((expected_reservation_fields + ['own_reservation', 'group'] - ['effective_context_code']).sort)

        end
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

          @ag1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00", "2012-01-01 13:00:00", "2012-01-01 14:00:00"]], :contexts => [@course])
          @ag1.publish!
          @event1 = @ag1.appointments.first
          @event2 = @ag1.appointments.last

          cat = @course.group_categories.create(name: "foo")
          @group = cat.groups.create(:context => @course)
          @group.users << @me
          @group.users << @other_guy
          @other_group = cat.groups.create(:context => @course)
          @me.reload
          @ag2 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :sub_context_codes => [cat.asset_string], :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
          @ag2.publish!
          @event3 = @ag2.appointments.first

          @user = @me
        end

        context "as a student" do
          before(:once) { prepare(true) }

          it "should reserve the appointment for @current_user" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            json.keys.sort.should eql(expected_reservation_event_fields)
            json['appointment_group_id'].should eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event3.id.to_s})
            json.keys.sort.should eql(expected_reservation_event_fields - ['effective_context_code']) # group one is on the group, no effective context
            json['appointment_group_id'].should eql(@ag2.id)
          end

          it "should not allow students to reserve non-appointment calendar_events" do
            e = @course.calendar_events.create
            raw_api_call(:post, "/api/v1/calendar_events/#{e.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => e.id.to_s})
            JSON.parse(response.body)['status'].should == 'unauthorized'
          end

          it "should not allow students to reserve an appointment twice" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            response.should be_success
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            errors = JSON.parse(response.body)
            errors.size.should eql 1
            error = errors.first
            error.slice("attribute", "type", "message").should eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "participant has already reserved this appointment"})
            error['reservations'].size.should eql 1
          end

          it "should cancel existing reservations if cancel_existing = true" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            json.keys.sort.should eql(expected_reservation_event_fields)
            json['appointment_group_id'].should eql(@ag1.id)
            @ag1.reservations_for(@me).map(&:parent_calendar_event_id).should eql [@event1.id]

            json = api_call(:post, "/api/v1/calendar_events/#{@event2.id}/reservations?cancel_existing=1", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event2.id.to_s, :cancel_existing => '1'})
            json.keys.sort.should eql(expected_reservation_event_fields)
            json['appointment_group_id'].should eql(@ag1.id)
            @ag1.reservations_for(@me).map(&:parent_calendar_event_id).should eql [@event2.id]
          end

          it "should not allow students to specify the participant" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
            errors = JSON.parse(response.body)
            errors.size.should eql 1
            error = errors.first
            error.slice("attribute", "type", "message").should eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant"})
            error['reservations'].size.should eql 0
          end

          it "should notify the teacher when appointment is canceled" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api',
              :action => 'reserve',
              :format => 'json',
              :id => @event1.id.to_s})

            reservation = CalendarEvent.find(json["id"])

            raw_api_call(:delete, "/api/v1/calendar_events/#{reservation.id}", {
              :controller => 'calendar_events_api',
              :action => 'destroy',
              :format => 'json',
              :id => reservation.id.to_s
            },
                         :cancel_reason => "Too busy")

            message = Message.last
            message.notification_name.should == 'Appointment Canceled By User'
            message.to.should == "test_channel_email_#{@teacher.id}"
            message.body.should =~ /Too busy/
          end
        end

        context "as an admin" do
          before(:once) { prepare }

          it "should allow admins to specify the participant" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
            json.keys.sort.should eql(expected_reservation_event_fields)
            json['appointment_group_id'].should eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations/#{@group.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event3.id.to_s, :participant_id => @group.id.to_s})
            json.keys.sort.should eql(expected_reservation_event_fields - ['effective_context_code'])
            json['appointment_group_id'].should eql(@ag2.id)
          end

          it "should reject invalid participants" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@me.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @me.id.to_s})
            errors = JSON.parse(response.body)
            errors.size.should eql 1
            error = errors.first
            error.slice("attribute", "type", "message").should eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant"})
            error['reservations'].size.should eql 0
          end
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
                      {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
                      {:calendar_event => {:context_code => @course.asset_string, :title => "ohai"}})
      assert_status(201)
      json.keys.sort.should eql expected_fields
      json['title'].should eql 'ohai'
    end

    it 'should process html content in description on create' do
      should_process_incoming_user_content(@course) do |content|
        json = api_call(:post, "/api/v1/calendar_events",
                        {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
                        {:calendar_event => {:context_code => @course.asset_string, :title => "ohai", :description => content}})

        event = CalendarEvent.find(json['id'])
        event.description
      end
    end

    it 'should update an event' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')

      json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                      {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                      {:calendar_event => {:start_at => '2012-01-09 12:00:00', :title => "ohai"}})
      json.keys.sort.should eql expected_fields
      json['title'].should eql 'ohai'
      json['start_at'].should eql '2012-01-09T12:00:00Z'
    end

    it 'should process html content in description on update' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')

      should_process_incoming_user_content(@course) do |content|
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                        {:calendar_event => {:start_at => '2012-01-09 12:00:00', :description => content}})

        event.reload
        event.description
      end
    end

    it 'should delete an event' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')
      json = api_call(:delete, "/api/v1/calendar_events/#{event.id}",
                      {:controller => 'calendar_events_api', :action => 'destroy', :id => event.id.to_s, :format => 'json'})
      json.keys.sort.should eql expected_fields
      event.reload.should be_deleted
    end

    it 'should api translate event descriptions' do
      should_translate_user_content(@course) do |content|
        event = @course.calendar_events.create!(:title => 'event', :start_at => '2012-01-08 12:00:00', :description => content)
        json = api_call(:get, "/api/v1/calendar_events/#{event.id}",
                        :controller => 'calendar_events_api', :action => 'show', :format => 'json',
                        :id => event.id.to_s)
        json['description']
      end
    end

    it 'should api translate event descriptions in ics' do
      HostUrl.stubs(:default_host).returns('www.example.com')
      should_translate_user_content(@course) do |content|
        @course.calendar_events.create!(:description => content, :start_at => Time.now + 1.hours, :end_at => Time.now + 2.hours)
        json = api_call(:get, "/api/v1/courses/#{@course.id}",
                        :controller => 'courses', :action => 'show', :format => 'json', :id => @course.id.to_s)
        get json['calendar']['ics']
        response.should be_success
        cal = Icalendar.parse(response.body.dup)[0]
        cal.events[0].x_alt_desc
      end
    end

    it "should omit assignment description in ics" do
      HostUrl.stubs(:default_host).returns('www.example.com')
      assignment_model(description: "secret stuff here")
      get "/feeds/calendars/#{@course.feed_code}.ics"
      response.should be_success
      cal = Icalendar.parse(response.body.dup)[0]
      cal.events[0].description.should == nil
      cal.events[0].x_alt_desc.should == nil
    end

    context "child_events" do
      let_once :event do
        event = @course.calendar_events.build(:title => 'event', :child_event_data => {"0" => {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string}})
        event.updating_user = @user
        event.save!
        event
      end

      it "should create an event with child events" do
        json = api_call(:post, "/api/v1/calendar_events",
                        {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
                        {:calendar_event => {:context_code => @course.asset_string, :title => "ohai", :child_event_data => {"0" => {:start_at => "2012-01-01 12:00:00", :end_at => "2012-01-01 13:00:00", :context_code => @course.default_section.asset_string}}}})
        assert_status(201)
        json.keys.sort.should eql expected_fields
        json['title'].should eql 'ohai'
        json['child_events'].size.should eql 1
        json['start_at'].should eql '2012-01-01T12:00:00Z' # inferred from child event
        json['end_at'].should eql '2012-01-01T13:00:00Z'
        json['hidden'].should be_true
      end

      it "should update an event with child events" do
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                        {:calendar_event => {:title => "ohai", :child_event_data => {"0" => {:start_at => "2012-01-01 13:00:00", :end_at => "2012-01-01 14:00:00", :context_code => @course.default_section.asset_string}}}})
        json.keys.sort.should eql expected_fields
        json['title'].should eql 'ohai'
        json['child_events'].size.should eql 1
        json['start_at'].should eql '2012-01-01T13:00:00Z'
        json['end_at'].should eql '2012-01-01T14:00:00Z'
        json['hidden'].should be_true
      end

      it "should remove all child events" do
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                        {:calendar_event => {:title => "ohai", :remove_child_events => '1'}})
        json.keys.sort.should eql expected_fields
        json['title'].should eql 'ohai'
        json['child_events'].should be_empty
        json['start_at'].should == '2012-01-01T12:00:00Z'
        json['end_at'].should == '2012-01-01T13:00:00Z'
        json['hidden'].should be_false
      end

      it "should add the section name to a child event's title" do
        child_event_id = event.child_event_ids.first
        json = api_call(:get, "/api/v1/calendar_events/#{child_event_id}",
                        {:controller => 'calendar_events_api', :action => 'show', :id => child_event_id.to_s, :format => 'json'})
        json.keys.sort.should eql((expected_fields + ['effective_context_code']).sort)
        json['title'].should eql "event (#{@course.default_section.name})"
        json['hidden'].should be_false
      end
    end
  end

  context 'assignments' do
    expected_fields = [
      'all_day', 'all_day_date', 'assignment', 'context_code', 'created_at',
      'description', 'end_at', 'html_url', 'id', 'start_at', 'title', 'updated_at',
      'url', 'workflow_state'
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

    it 'orders result set by base due_at' do
      e2 = @course.assignments.create(:title => '2', :due_at => '2012-01-08 12:00:00')
      e1 = @course.assignments.create(:title => '1', :due_at => '2012-01-07 12:00:00')
      e3 = @course.assignments.create(:title => '3', :due_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'})
      json.size.should eql 3
      json.first.keys.sort.should eql expected_fields
      json.map { |event| event['title'] }.should == %w[1 2 3]
    end

    it 'should paginate assignments' do
      ids = create_assignments(@course.id, 25, due_at: '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10'})
      json.size.should eql 10
      response.headers['Link'].should match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08', :per_page => '10', :page => '3'})
      json.size.should eql 5
      response.headers['Link'].should match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
    end

    it 'should ignore invalid end_dates' do
      @course.assignments.create(:title => 'a', :due_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-07'})
      json.size.should eql 1
    end

    it 'should 400 for bad dates' do
      raw_api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=201-201-208&end_date=201-201-209&context_codes[]=course_#{@course.id}", {
        controller: 'calendar_events_api', action: 'index', format: 'json', type: 'assignment',
        context_codes: ["course_#{@course.id}"], start_date: '201-201-208', end_date: '201-201-209'})
      response.code.should eql '400'
      json = JSON.parse response.body
      json['errors']['start_date'].should == 'Invalid date or invalid datetime for start_date'
      json['errors']['end_date'].should == 'Invalid date or invalid datetime for end_date'
    end

    it 'should return assignments from up to 10 contexts' do
      contexts = [@course.asset_string]
      course_ids = create_courses(15, enroll_user: @me)
      create_assignments(course_ids, 1, due_at: '2012-01-08 12:00:00')
      contexts.concat course_ids.map{ |id| "course_#{id}" }
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

    context 'unpublished assignments' do
      before :once do
        @course1 = @course
        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @teacher)
        @course2 = @course

        @pub1 = @course1.assignments.create(:title => 'published assignment 1')
        @pub2 = @course2.assignments.create(:title => 'published assignment 2')
        [@pub1, @pub2].each { |a| a.workflow_state = 'published'; a.save! }

        @unpub1 = @course1.assignments.create(:title => 'unpublished assignment 1')
        @unpub2 = @course2.assignments.create(:title => 'unpublished assignment 2')
        [@unpub1, @unpub2].each { |a| a.workflow_state = 'unpublished'; a.save! }
      end

      context 'for teachers' do
        it 'should return all assignments' do
          json = api_call_as_user(@teacher,
            :get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :type => 'assignment', :all_events => '1', :context_codes => ["course_#{@course1.id}", "course_#{@course2.id}"]
          )

          json.map{ |a| a['title'] }.sort.should eql [
            'published assignment 1',
            'published assignment 2',
            'unpublished assignment 1',
            'unpublished assignment 2'
          ]
        end
      end

      context 'for teachers and students' do
        before do
          @teacher_student = user(:active_all => true)
          teacher_enrollment = @course1.enroll_teacher(@teacher_student)
          teacher_enrollment.workflow_state = 'active'
          teacher_enrollment.save!
          @course2.enroll_student(@teacher_student, :enrollment_state => 'active')
        end

        it 'should return published assignments and all assignments for teacher contexts' do
          json = api_call_as_user(@teacher_student,
            :get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :type => 'assignment', :all_events => '1', :context_codes => ["course_#{@course1.id}", "course_#{@course2.id}"]
          )

          json.map{ |a| a['title'] }.sort.should eql [
            'published assignment 1',
            'published assignment 2',
            'unpublished assignment 1',
          ]
        end
      end

      context 'for students' do
        before do
          @teacher_student = user(:active_all => true)
          @course1.enroll_student(@teacher_student, :enrollment_state => 'active')
          @course2.enroll_student(@teacher_student, :enrollment_state => 'active')
        end

        it 'should return only published assignments' do
          json = api_call_as_user(@teacher_student,
            :get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :type => 'assignment', :all_events => '1', :context_codes => ["course_#{@course1.id}", "course_#{@course2.id}"]
          )

          json.map{ |a| a['title'] }.sort.should eql [
            'published assignment 1',
            'published assignment 2',
          ]
        end
      end
    end

    context 'differentiated assignments on' do
      before :once do
        course_with_teacher(:active_course => true, :active_enrollment => true, :user => @teacher)
        @course.enable_feature!(:differentiated_assignments)

        @student_in_overriden_section = User.create
        @student_in_general_section = User.create

        @course.enroll_student(@student_in_general_section, :enrollment_state => 'active')
        @section = @course.course_sections.create!(name: "test section")
        student_in_section(@section, user: @student_in_overriden_section)


        @only_vis_to_o, @not_only_vis_to_o = (1..2).map{@course.assignments.create(:title => 'test assig', :workflow_state => 'published',:due_at => '2012-01-07 12:00:00')}
        @only_vis_to_o.only_visible_to_overrides = true
        @only_vis_to_o.save!
        [@only_vis_to_o, @not_only_vis_to_o].each { |a| a.workflow_state = 'published'; a.save! }

        create_section_override_for_assignment(@only_vis_to_o, {course_section: @section})
      end


      context 'as a student' do
        it "only shows events for visible assignments" do
          json = api_call_as_user(@student_in_overriden_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
          json.size.should eql 2


          json = api_call_as_user(@student_in_general_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
          json.size.should eql 1
        end
      end

      context 'as an observer' do
        before do
          @observer = User.create
          @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section2, :enrollment_state => 'active', :allow_multiple_enrollments => true)
        end
        context 'following a student with visibility' do
          before{ @observer_enrollment.update_attribute(:associated_user_id, @student_in_overriden_section.id) }
          it "only shows events for assignments visible to that student" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
            json.size.should eql 2
          end
        end

        context 'following two students with visibility' do
          before do
            @observer_enrollment.update_attribute(:associated_user_id, @student_in_overriden_section.id)
            student_in_section(@section, user: @student_in_general_section)
            @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student_in_general_section.id})
          end
          it "doesnt show duplicate events" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
            json.size.should eql 2
          end
        end

        context 'following a student without visibility' do
          before{ @observer_enrollment.update_attribute(:associated_user_id, @student_in_general_section.id) }
          it "only shows events for assignments visible to that student" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
            json.size.should eql 1
          end
        end
        context 'in a section only' do
          it "shows events for all active assignment" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
            json.size.should eql 2
          end
        end
      end

      context 'as a teacher' do
        it "shows events for all active assignment" do
            json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2015-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2015-01-08'})
            json.size.should eql 2
        end
      end
    end

    context 'all assignments' do
      before :once do
        @course.assignments.create(:title => 'undated')
        @course.assignments.create(:title => 'dated', :due_at => '2012-01-08 12:00:00')
      end

      it 'should return all assignments' do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1'})
        json.size.should eql 2
      end

      it 'should return all assignments, ignoring the undated flag' do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :undated => '1'})
        json.size.should eql 2
      end

      it 'should return all assignments, ignoring the start_date and end_date' do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :start_date => '2012-02-01', :end_date => '2012-02-01'})
        json.size.should eql 2
      end
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
                      {:controller => 'calendar_events_api', :action => 'update', :id => "assignment_#{assignment.id}", :format => 'json'},
                      {:calendar_event => {:start_at => '2012-01-09 12:00:00'}})
      json.keys.sort.should eql expected_fields
      json['start_at'].should eql '2012-01-09T12:00:00Z'
    end

    it 'should not delete assignments' do
      assignment = @course.assignments.create(:title => 'undated')
      raw_api_call(:delete, "/api/v1/calendar_events/assignment_#{assignment.id}", {
        :controller => 'calendar_events_api', :action => 'destroy', :id => "assignment_#{assignment.id}", :format => 'json'})
      assert_status(404)
    end

    context 'date overrides' do
      before :once do
        @default_assignment = @course.assignments.create(:title => 'overridden', :due_at => '2012-01-12 12:00:00') # out of range
        @default_assignment.workflow_state = 'published'
        @default_assignment.save!
      end

      context 'as student' do
        before :once do
          @student = user :active_all => true, :active_state => 'active'
        end

        context 'when no sections' do
          before :once do
            @course.enroll_student(@student, :enrollment_state => 'active')
          end

          it 'should return an all-day override' do
            # make the assignment non-all day
            @default_assignment.due_at = DateTime.parse('2012-01-12 04:42:00')
            @default_assignment.save!
            @default_assignment.all_day.should be_false
            @default_assignment.all_day_date.should == DateTime.parse('2012-01-12 04:42:00').to_date

            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-21 23:59:00'))
            @override.all_day.should be_true
            @override.all_day_date.should == DateTime.parse('2012-01-21 23:59:00').to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31', :per_page => '25'})
            json.size.should == 1
            json.first['id'].should == "assignment_#{@default_assignment.id}"

            json.first['all_day'].should be_true
            json.first['all_day_date'].should == '2012-01-21'
          end

          it 'should return a non-all-day override' do
            @default_assignment.due_at = DateTime.parse('2012-01-12 23:59:00')
            @default_assignment.save!
            @default_assignment.all_day.should be_true
            @default_assignment.all_day_date.should == DateTime.parse('2012-01-12 23:59:00').to_date

            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-21 04:42:00'))
            @override.all_day.should be_false
            @override.all_day_date.should == DateTime.parse('2012-01-21 04:42:00').to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31', :per_page => '25'})
            json.size.should == 1
            json.first['id'].should == "assignment_#{@default_assignment.id}"

            json.first['all_day'].should be_false
            json.first['all_day_date'].should == '2012-01-21'
          end

          it 'should return a non-overridden assignment' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first.keys.should_not include('assignment_override')
          end

          it 'should return an override when present' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first['end_at'].should == '2012-01-14T12:00:00Z'
            json.first.keys.should_not include('assignment_override')
          end

          it 'should return assignment when override is in range but assignment is not' do
            @default_assignment.due_at = DateTime.parse('2012-01-01 12:00:00') # out of range
            @default_assignment.save!
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-08 12:00:00')) # in range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['end_at'].should == '2012-01-08T12:00:00Z'
          end

          it 'should not return an assignment when assignment due_at in range but override is out' do
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-17 12:00:00')) # out of range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 0 # nothing returned
          end

          it 'should return user specific override' do
            override = assignment_override_model(:assignment => @default_assignment,
                                                 :due_at => DateTime.parse('2012-01-12 12:00:00'))
            override.assignment_override_students.create!(:user => @user)
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
          end
        end

        context 'with sections' do
          before :once do
            @section1 = @course.course_sections.create!(:name => 'Section A')
            @section2 = @course.course_sections.create!(:name => 'Section B')
            @course.enroll_user(@student, 'StudentEnrollment', :section => @section2, :enrollment_state => 'active')
          end

          it 'should return a non-overridden assignment' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first.keys.should_not include('assignment_override')
          end

          it 'should return an override when present' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            override = assignment_override_model(:assignment => @default_assignment, :due_at => DateTime.parse('2012-01-14 12:00:00'))
            override.set = @section2
            override.save!
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first['end_at'].should == '2012-01-14T12:00:00Z'
          end

          it 'should return 1 assignment for latest date' do
            # Setup assignment
            assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                      :due_at => DateTime.parse('2012-01-12 12:00:00')) # later than assignment
            assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                      :due_at => DateTime.parse('2012-01-14 12:00:00')) # latest
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1
            json.first['end_at'].should == '2012-01-14T12:00:00Z'
          end

          it 'should return later override with user and section overrides' do
            override = assignment_override_model(:assignment => @default_assignment,
                                                 :due_at => DateTime.parse('2012-01-12 12:00:00'))
            override.assignment_override_students.create!(:user => @user)
            assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                      :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1
            json.first['end_at'].should == '2012-01-14T12:00:00Z'
          end
        end
      end

      context 'as teacher' do
        it 'should return 1 assignment when no overrides' do
          json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
          json.size.should == 1 # 1 assignment
          json.first['id'].should == "assignment_#{@default_assignment.id}"
          json.first['end_at'].should == '2012-01-12T12:00:00Z'
          json.first.keys.should_not include('assignment_override')
        end

        it 'should get explicit assignment with override info' do
          pending 'not sure what the desired behavior here is'
          override = assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                               :due_at => DateTime.parse('2012-01-14 12:00:00'))
          json = api_call(:get, "/api/v1/calendar_events/assignment_#{@default_assignment.id}", {
            :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{@default_assignment.id}", :format => 'json'})
          #json.size.should == 2
          json.slice('id', 'override_id', 'end_at').should eql({'id' => "assignment_#{@default_assignment.id}",
                                                                'override_id' => override.id,
                                                                'end_at' => '2012-01-14T12:00:00Z'})
          json.keys.sort.should == expected_fields
        end

        context 'with sections' do
          before :once do
            @section1 = @course.course_sections.create!(:name => 'Section A')
            @section2 = @course.course_sections.create!(:name => 'Section B')
            student_in_section(@section1)
            student_in_section(@section2)
            @user = @teacher
          end

          it 'should return 1 entry for each instance' do
            # Setup assignment
            override1 = assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                                  :due_at => DateTime.parse('2012-01-14 12:00:00'))
            override2 = assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                                  :due_at => DateTime.parse('2012-01-18 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-19&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19', :per_page => '25'})
            json.size.should == 3
            # sort results locally by end_at
            json.sort_by! { |a| a['end_at'] }
            json[0].keys.should_not include('assignment_override')
            json[1]['assignment_overrides'][0]['id'].should == override1.id
            json[2]['assignment_overrides'][0]['id'].should == override2.id
            json[0]['end_at'].should == '2012-01-12T12:00:00Z'
            json[1]['end_at'].should == '2012-01-14T12:00:00Z'
            json[2]['end_at'].should == '2012-01-18T12:00:00Z'
          end

          it 'should return 1 assignment (override) when others are outside the range' do
            # Alter assignment
            @default_assignment.due_at = DateTime.parse('2012-01-01 12:00:00') # outside range
            @default_assignment.save!
                                                                               # Setup overrides
            override1 = assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                                  :due_at => DateTime.parse('2012-01-12 12:00:00')) # in range
            assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                      :due_at => DateTime.parse('2012-01-18 12:00:00')) # outside range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1
            json.first['assignment_overrides'][0]['id'].should == override1.id
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
          end
        end
      end

      context 'as TA' do
        before :once do
          @ta = user :active_all => true, :active_state => 'active'
        end

        context 'when no sections' do
          before :once do
            @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active')
          end

          it 'should return a non-overridden assignment' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first.keys.should_not include('assignment_override')
          end

          it 'should return override when present' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            override = assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                                 :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # should only return the overridden assignment if all sections have an override
            json[0].keys.should include('assignment_overrides')
            json[0]['end_at'].should == '2012-01-14T12:00:00Z'
          end
        end

        context 'when TA of one section' do
          before :once do
            @section1 = @course.course_sections.create!(:name => 'Section A')
            @section2 = @course.course_sections.create!(:name => 'Section B')
            @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active', :section => @section1) # only in 1 section
            student_in_section(@section1)
            student_in_section(@section2)
            @user = @ta
          end

          it 'should receive all assignments including other sections' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            override1 = assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                                  :due_at => DateTime.parse('2012-01-12 12:00:00'))
            override2 = assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                                  :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 3 # all versions
            json.sort_by! { |a| a['end_at'] }
            json[0].keys.should_not include('assignment_override')
            json[0]['end_at'].should == '2012-01-08T12:00:00Z'
            json[1]['assignment_overrides'][0]['id'].should == override1.id
            json[1]['end_at'].should == '2012-01-12T12:00:00Z'
            json[2]['assignment_overrides'][0]['id'].should == override2.id
            json[2]['end_at'].should == '2012-01-14T12:00:00Z'
          end
        end
      end

      context 'as observer' do
        before :once do
          @student = user(:active_all => true, :active_state => 'active')
          @observer = user(:active_all => true, :active_state => 'active')
        end

        context 'when not observing any students' do
          before :once do
            @course.enroll_user(@observer,
                                'ObserverEnrollment',
                                :enrollment_state => 'active',
                                :section => @course.default_section)
          end

          it 'should return assignment for enrollment' do
            override2 = assignment_override_model(:assignment => @default_assignment,
                                                  :set => @course.course_sections.create!(:name => 'Section 2'),
                                                  :due_at => DateTime.parse('2012-01-14 12:00:00'))

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
          end
        end

        context 'when no sections' do
          it 'should return assignments with no override' do
            @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 1 # 1 assignment
            json.first['id'].should == "assignment_#{@default_assignment.id}"
            json.first['end_at'].should == '2012-01-12T12:00:00Z'
          end

          context 'observing single student' do
            before :once do
              @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @course.default_section)
              @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => @course.default_section)
              @observer_enrollment.update_attribute(:associated_user_id, @student.id)
            end

            it 'should return student specific overrides' do
              assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                        :due_at => DateTime.parse('2012-01-13 12:00:00'))
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              json.size.should == 1 # only 1
              json.first['end_at'].should == '2012-01-13T12:00:00Z'
            end

            it 'should return standard assignment' do
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              json.size.should == 1 # only 1
              json.first['end_at'].should == '2012-01-12T12:00:00Z'
            end
          end
        end

        context 'with sections' do
          before :once do
            @section1 = @course.course_sections.create!(:name => 'Section A')
            @section2 = @course.course_sections.create!(:name => 'Section B')
            @student_enrollment = @course.enroll_user(@student, 'StudentEnrollment', :enrollment_state => 'active', :section => @section1)
            @observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active', :section => @section1)
            @observer_enrollment.update_attribute(:associated_user_id, @student.id)
          end

          context 'observing single student' do
            it 'should return linked student specific override' do
              assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                        :due_at => DateTime.parse('2012-01-13 12:00:00'))
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              json.size.should == 1
              json.first['end_at'].should == '2012-01-13T12:00:00Z'
            end

            it 'should return only override for student section' do
              assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                        :due_at => DateTime.parse('2012-01-13 12:00:00'))
              assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                        :due_at => DateTime.parse('2012-01-14 12:00:00'))

              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              json.size.should == 1
              json.first['end_at'].should == '2012-01-13T12:00:00Z'
            end
          end

          context 'observing multiple students' do
            before :once do
              @student2 = user(:active_all => true, :active_state => 'active')
            end

            context 'when in same course section' do
              before :each do
                @student_enrollment2 = @course.enroll_user(@student2, 'StudentEnrollment', enrollment_state: 'active', section: @section1)
                @observer_enrollment2 = ObserverEnrollment.new(user: @observer,
                                                               course: @course,
                                                               course_section: @section1,
                                                               workflow_state: 'active')

                @observer_enrollment2.associated_user_id = @student2.id
                @observer_enrollment2.save!
              end

              it 'should return a single assignment event' do
                @user = @observer
                assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                          :due_at => DateTime.parse('2012-01-14 12:00:00'))
                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-30&per_page=25&context_codes[]=course_#{@course.id}", {
                  :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                  :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-30', :per_page => '25'})
                json.size.should == 1
                json.first['end_at'].should == '2012-01-14T12:00:00Z'
              end
            end

            context 'when in same course different sections' do
              before :each do
                @student_enrollment2 = @course.enroll_user(@student2, 'StudentEnrollment', :enrollment_state => 'active', :section => @section2)
                @observer_enrollment2 = ObserverEnrollment.create!(:user => @observer,
                                                                   :course => @course,
                                                                   :course_section => @section2,
                                                                   :workflow_state => 'active')

                @observer_enrollment2.update_attribute(:associated_user_id, @student2.id)
              end

              it 'should return two assignments one for each section' do
                @user = @observer
                assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                          :due_at => DateTime.parse('2012-01-14 12:00:00'))
                assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                          :due_at => DateTime.parse('2012-01-15 12:00:00'))
                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                  :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                  :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
                json.size.should == 2
                json.sort_by! { |a| a['end_at'] }
                json[0]['end_at'].should == '2012-01-14T12:00:00Z'
                json[1]['end_at'].should == '2012-01-15T12:00:00Z'
              end
            end

            context 'when in different courses' do
              before(:each) do
                @course1 = @course
                @course2 = course(:active_all => true)

                @assignment1 = @default_assignment
                @assignment2 = @course2.assignments.create!(:title => 'Override2', :due_at => '2012-01-13 12:00:00Z')
                [@assignment1, @assignment2].each { |a| a.save! }

                @student1_enrollment = StudentEnrollment.create!(:user => @student, :workflow_state => 'active', :course_section => @course1.default_section, :course => @course1)
                @student2_enrollment = StudentEnrollment.create!(:user => @student2, :workflow_state => 'active', :course_section => @course2.default_section, :course => @course2)
                @observer1_enrollment = ObserverEnrollment.create!(:user => @observer, :workflow_state => 'active', :course_section => @course1.default_section, :course => @course1)
                @observer2_enrollment = ObserverEnrollment.create!(:user => @observer, :workflow_state => 'active', :course_section => @course2.default_section, :course => @course2)

                @observer1_enrollment.update_attribute(:associated_user_id, @student.id)
                @observer2_enrollment.update_attribute(:associated_user_id, @student2.id)
                @user = @observer
              end

              it 'should return two assignments' do
                assignment_override_model(:assignment => @assignment1, :set => @course1.default_section, :due_at => DateTime.parse('2012-01-14 12:00:00'))
                assignment_override_model(:assignment => @assignment2, :set => @course2.default_section, :due_at => DateTime.parse('2012-01-15 12:00:00'))

                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}", {
                  :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                  :context_codes => ["course_#{@course1.id}", "course_#{@course2.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})

                json.size.should == 2
                json.sort_by! { |a| a['end_at'] }
                json[0]['end_at'].should == '2012-01-14T12:00:00Z'
                json[1]['end_at'].should == '2012-01-15T12:00:00Z'
              end
            end
          end
        end
      end

      # Admins who are not enrolled in the course
      context 'as admin' do
        before :once do
          @admin = account_admin_user
          @section1 = @course.default_section
          @section2 = @course.course_sections.create!(:name => 'Section B')
          student_in_section(@section2)
          @user = @admin
        end

        context 'when viewing own calendar' do
          it 'should return 0 course assignments' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 0 # 0 assignments returned
          end
        end

        context 'when viewing course calendar' do
          it 'should display assignments and overrides' do # behave like teacher
            override = assignment_override_model(:assignment => @default_assignment,
                                                 :due_at => DateTime.parse('2012-01-15 12:00:00'),
                                                 :set => @section2)
            json = api_call(:get, "/api/v1/calendar_events?&type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            json.size.should == 2
            # Should include the default and override in return
            json.sort_by! { |a| a['end_at'] }
            json[0]['end_at'].should == '2012-01-12T12:00:00Z'
            json[0]['override_id'].should be_nil
            json[0].keys.should_not include('assignment_override')
            json[1]['end_at'].should == '2012-01-15T12:00:00Z'
            json[1]['assignment_overrides'][0]['id'].should == override.id
          end
        end
      end
    end
  end

  context "calendar feed" do
    before :once do
      now = Time.now
      @student = user(:active_all => true, :active_state => 'active')
      @course.enroll_student(@student, :enrollment_state => 'active')
      @student2 = user(:active_all => true, :active_state => 'active')
      @course.enroll_student(@student2, :enrollment_state => 'active')


      @event = @course.calendar_events.create(:title => 'course event', :start_at => now + 1.day)
      @assignment = @course.assignments.create(:title => 'original assignment', :due_at => now + 2.days)
      @override = assignment_override_model(
        :assignment => @assignment, :due_at => @assignment.due_at + 3.days, :set => @course.default_section)

      @appointment_group = AppointmentGroup.create!(
        :title => "appointment group", :participants_per_appointment => 4,
        :new_appointments => [
          [now + 3.days, now + 3.days + 1.hour],
          [now + 3.days + 1.hour, now + 3.days + 2.hours],
          [now + 3.days + 2.hours, now + 3.days + 3.hours]],
        :contexts => [@course])

      @appointment_event = @appointment_group.appointments[0]
      @appointment = @appointment_event.reserve_for(@student, @student)

      @appointment_event2 = @appointment_group.appointments[1]
      @appointment2 = @appointment_event2.reserve_for(@student2, @student2)
    end

    it "should have events for the teacher" do
      raw_api_call(:get, "/feeds/calendars/#{@teacher.feed_code}.ics", {
        :controller => 'calendar_events_api', :action => 'public_feed', :format => 'ics', :feed_code => @teacher.feed_code})
      response.should be_success

      response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip).sort.should eql [
                                                                                         "assignment-override-#{@override.id}", "calendar-event-#{@event.id}",
                                                                                         "calendar-event-#{@appointment_event.id}", "calendar-event-#{@appointment_event2.id}"].sort
    end

    it "should have events for the student" do
      raw_api_call(:get, "/feeds/calendars/#{@student.feed_code}.ics", {
        :controller => 'calendar_events_api', :action => 'public_feed', :format => 'ics', :feed_code => @student.feed_code})
      response.should be_success

      response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip).sort.should eql [
                                                                                         "assignment-override-#{@override.id}", "calendar-event-#{@event.id}", "calendar-event-#{@appointment.id}"].sort

      # make sure the assignment actually has the override date
      expected_override_date_output = @override.due_at.utc.iso8601.gsub(/[-:]/, '').gsub(/\d\dZ$/, '00Z')
      response.body.match(/DTSTART:\s*#{expected_override_date_output}/).should_not be_nil
    end

    it "should render unauthorized feed for bad code" do
      get "/feeds/calendars/user_garbage.ics"
      response.should render_template('shared/unauthorized_feed')
    end
  end

end
