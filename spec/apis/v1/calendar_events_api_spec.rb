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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require_relative '../../sharding_spec_helper'

describe CalendarEventsApiController, type: :request do
  before :once do
    course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
    @me = @user
  end

  context 'events' do
    expected_fields = [
      'all_context_codes', 'all_day', 'all_day_date', 'child_events', 'child_events_count', 'comments',
      'context_code', 'created_at', 'description', 'duplicates', 'end_at', 'hidden', 'html_url',
      'id', 'location_address', 'location_name', 'parent_event_id', 'start_at',
      'title', 'type', 'updated_at', 'url', 'workflow_state'
    ]
    expected_slot_fields = (expected_fields + ['appointment_group_id', 'appointment_group_url', 'can_manage_appointment_group', 'available_slots', 'participants_per_appointment', 'reserve_url', 'participant_type', 'effective_context_code'])
    expected_reservation_event_fields = (expected_fields + ['appointment_group_id', 'appointment_group_url', 'can_manage_appointment_group', 'effective_context_code', 'participant_type'])
    expected_reserved_fields = (expected_slot_fields + ['reserved', 'reserve_comments'])
    expected_reservation_fields = expected_reservation_event_fields - ['child_events']

    it 'should return events within the given date range' do
      e1 = @course.calendar_events.create(:title => '1', :start_at => '2012-01-07 12:00:00')
      e2 = @course.calendar_events.create(:title => '2', :start_at => '2012-01-08 12:00:00')
      e3 = @course.calendar_events.create(:title => '3', :start_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08'})
      expect(json.size).to eql 1
      expect(json.first.keys).to match_array expected_fields
      expect(json.first.slice('title', 'start_at', 'id')).to eql({'id' => e2.id, 'title' => '2', 'start_at' => '2012-01-08T12:00:00Z'})
    end

    it 'orders result set by start_at' do
      e2 = @course.calendar_events.create(:title => 'second', :start_at => '2012-01-08 12:00:00')
      e1 = @course.calendar_events.create(:title => 'first', :start_at => '2012-01-07 12:00:00')
      e3 = @course.calendar_events.create(:title => 'third', :start_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'})
      expect(json.size).to eql 3
      expect(json.first.keys).to match_array expected_fields
      expect(json.map { |event| event['title'] }).to eq %w[first second third]
    end

    it "should default to today's events for the current user if no parameters are specified" do
      Timecop.freeze('2012-01-29 12:00:00 UTC') do
        e1 = @user.calendar_events.create!(:title => "yesterday", :start_at => 1.day.ago) { |c| c.context = @user }
        e2 = @user.calendar_events.create!(:title => "today", :start_at => 0.days.ago) { |c| c.context = @user }
        e3 = @user.calendar_events.create!(:title => "tomorrow", :start_at => 1.days.from_now) { |c| c.context = @user }

        json = api_call(:get, "/api/v1/calendar_events", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json'
        })

        expect(json.size).to eql 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice('id', 'title')).to eql({'id' => e2.id, 'title' => 'today'})
      end
    end

    it "should not allow user to create calendar events" do
      testCourse = course_with_teacher(:active_all => true, :user => user_with_pseudonym(:active_user => true))
      testCourse.context.destroy!
      json = api_call(:post, "/api/v1/calendar_events.json", {
          :controller => 'calendar_events_api', :action => 'create', :format => 'json'
        }, {
        :calendar_event => {
          :context_code => "course_#{testCourse.course_id}",
          :title => "API Test",
          :start_at => "2018-09-19T21:00:00Z",
          :end_at => "2018-09-19T22:00:00Z"
        }}
      );
      expect(json.first[1]).to eql "cannot create event for deleted course"
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

          expect(json.size).to eql 1
          expect(json.first.keys).to match_array expected_fields
          expect(json.first.slice('id', 'title')).to eql({'id' => @e2.id, 'title' => 'today in AKST'})
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
          expect(json.size).to eql 2
          expect(json[0].keys).to match_array expected_fields
          expect(json[0].slice('id', 'title')).to eql({'id' => @e1.id, 'title' => 'yesterday in AKST'})
          expect(json[1].slice('id', 'title')).to eql({'id' => @e2.id, 'title' => 'today in AKST'})
        end
      end
    end

    it 'should sort and paginate events' do
      undated = (1..7).map {|i| @course.calendar_events.create(title: "undated:#{i}", start_at: nil, end_at: nil).id }
      dated = (1..18).map {|i| @course.calendar_events.create(title: "dated:#{i}", start_at: Time.parse('2012-01-20 12:00:00').advance(days: -i)).id }
      ids = dated.reverse + undated

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[0...10]

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=2", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10', :page => '2'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="next",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[10...20]

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10', :page => '3'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[20...25]
    end

    it 'should ignore invalid end_dates' do
      @course.calendar_events.create(:title => 'e', :start_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-07'})
      expect(json.size).to eql 1
    end

    it 'should return events from up to 10 contexts by default' do
      contexts = [@course.asset_string]
      course_ids = create_courses(15, enroll_user: @me)
      create_records(CalendarEvent, course_ids.map{ |id| {context_id: id, context_type: 'Course', context_code: "course_#{id}", title: "#{id}", start_at: '2012-01-08 12:00:00', workflow_state: 'active'}})
      contexts.concat course_ids.map{ |id| "course_#{id}" }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      expect(json.size).to eql 9 # first context has no events
    end

    it 'should return events from contexts up to the account limit setting' do
      contexts = [@course.asset_string]
      Account.default.settings[:calendar_contexts_limit] = 15
      Account.default.save!
      course_ids = create_courses(20, enroll_user: @me)
      create_records(CalendarEvent, course_ids.map{ |id| {context_id: id, context_type: 'Course', context_code: "course_#{id}", title: "#{id}", start_at: '2012-01-08 12:00:00', workflow_state: 'active'}})
      contexts.concat course_ids.map{ |id| "course_#{id}" }
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      expect(json.size).to eql 14 # first context has no events
    end

    it 'does not count appointment groups against the context limit' do
      Account.default.settings[:calendar_contexts_limit] = 1
      Account.default.save!
      group1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
      group1.publish!
      contexts = [@course, group1].map(&:asset_string)
      student_in_course :active_all => true
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-02&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => contexts, :start_date => '2012-01-01', :end_date => '2012-01-02', :per_page => '25'})
      slot = json.detect { |thing| thing['appointment_group_id'] == group1.id }
      expect(slot).not_to be_nil
    end

    it 'accepts a more compact comma-separated list of appointment group ids' do
      ags = (0..2).map do |x|
        ag = AppointmentGroup.create!(:title => "ag #{x}", :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
        ag.publish!
        ag
      end
      ag_id_list = ags.map(&:id).join(',')
      student_in_course :active_all => true
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-02&per_page=25&appointment_group_ids=" + ag_id_list, {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :appointment_group_ids => ag_id_list, :start_date => '2012-01-01', :end_date => '2012-01-02', :per_page => '25'})
      expect(json.map{|e| e['appointment_group_id']}).to match_array(ags.map(&:id))
      expect(response.headers['Link']).to include 'appointment_group_ids='
    end

    it 'should fail with unauthorized if provided a context the user cannot access' do
      contexts = [@course.asset_string]

      # second context the user cannot access
      course_factory()
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
      expect(json.size).to eq 1
      expect(json.first['title']).to eq "from unrelated one"
    end

    it "should allow account admins to view section-specific events" do
      event = @course.calendar_events.build(:title => 'event', :child_event_data =>
        {"0" => {:start_at => "2012-01-09 12:00:00", :end_at => "2012-01-09 13:00:00", :context_code => @course.default_section.asset_string}})
      event.updating_user = @teacher
      event.save!
      account_admin_user(:active_all => true)

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'})

      expect(json.detect{|e| e['id'] == event.child_events.first.id}).to be_present
    end

    it "doesn't allow account admins to view events for courses they don't have access to" do
      sub_account1 = Account.default.sub_accounts.create!
      course_with_teacher(:active_all => true, :account => sub_account1)
      event = @course.calendar_events.build(:title => 'event', :child_event_data =>
        {"0" => {:start_at => "2012-01-09 12:00:00", :end_at => "2012-01-09 13:00:00", :context_code => @course.default_section.asset_string}})
      event.updating_user = @teacher
      event.save!

      sub_account2 = Account.default.sub_accounts.create!
      account_admin_user(:active_all => true, :account => sub_account2)

      api_call(:get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'}, {}, {}, {:expected_status => 401})
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
      course_factory(active_all: true)
      public_course_query(:opts => {:expected_status => 401})
    end

    it "should allow anonymous users to access public context" do
      @user = nil
      public_course_query(:opts => {:expected_status => 200}) do |c|
        c.is_public = true
      end
    end

    it "should allow anonymous users to access a public syllabus" do
      @user = nil
      public_course_query(:opts => {:expected_status => 200}) do |c|
        c.public_syllabus = true
      end
    end

    it "should not allow anonymous users to access a public for authenticated syllabus" do
      @user = nil
      public_course_query(:opts => {:expected_status => 401}) do |c|
        c.public_syllabus = false
        c.public_syllabus_to_auth = true
      end
    end

    it 'should return undated events' do
      @course.calendar_events.create(:title => 'undated')
      @course.calendar_events.create(:title => "dated", :start_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?undated=1&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json',
        :context_codes => ["course_#{@course.id}"], :undated => '1'})
      expect(json.size).to eql 1
      expect(json.first['start_at']).to be_nil
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
        expect(json.size).to eql 2
      end

      it 'should return all events, ignoring the undated flag' do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :undated => '1'})
        expect(json.size).to eql 2
      end

      it 'should return all events, ignoring the start_date and end_date' do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :start_date => '2012-02-01', :end_date => '2012-02-01'})
        expect(json.size).to eql 2
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
          g.users << user_factory
          event2.reserve_for(g, @me)
          group_ids << g.id
          group_student_ids << @user.id
        }

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course.asset_string}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => [@course.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
        expect(json.size).to eql 2
        json.sort_by! { |e| e['id'] }

        e1json = json.first
        expect(e1json.keys).to match_array(expected_slot_fields)
        expect(e1json['reserve_url']).to match %r{calendar_events/#{event1.id}/reservations/%7B%7B%20id%20%7D%7D}
        expect(e1json['participant_type']).to eq 'User'
        expect(e1json['can_manage_appointment_group']).to eq true
        expect(e1json['child_events'].size).to eql 3
        e1json['child_events'].each do |e|
          expect(e.keys).to match_array((expected_reservation_fields + ['user']))
          expect(student_ids).to include e['user']['id']
        end

        e2json = json.last
        expect(e2json.keys).to match_array(expected_slot_fields)
        expect(e2json['reserve_url']).to match %r{calendar_events/#{event2.id}/reservations/%7B%7B%20id%20%7D%7D}
        expect(e2json['participant_type']).to eq 'Group'
        expect(e1json['can_manage_appointment_group']).to eq true
        expect(e2json['child_events'].size).to eql 3
        e2json['child_events'].each do |e|
          expect(e.keys).to match_array((expected_reservation_fields + ['group'] - ['effective_context_code']))
          expect(group_ids).to include e['group']['id']
          expect(group_student_ids).to include e['group']['users'].first['id']
        end
      end

      context "basic scenarios" do
        before :once do
          course_factory(active_all: true)
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
          expect(json.size).to eql 2
          json.sort_by! { |e| e['id'] }

          ejson = json.first
          expect(ejson.keys).to match_array(expected_reserved_fields)
          expect(ejson['child_events']).to eq [] # not reserved, so no child events can be seen
          expect(ejson['reserve_url']).to match %r{calendar_events/#{event1.id}/reservations/#{@me.id}}
          expect(ejson['reserved']).to be_falsey
          expect(ejson['available_slots']).to eql 1

          ejson = json.last
          expect(ejson.keys).to match_array(expected_reserved_fields)
          expect(ejson['reserve_url']).to match %r{calendar_events/#{event2.id}/reservations/#{g.id}}
          expect(ejson['reserved']).to be_truthy
          expect(ejson['available_slots']).to eql 3
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
          expect(json.size).to eql 1
          ejson = json.first
          expect(ejson.keys).to include 'child_events'
          expect(ejson['child_events_count']).to eql 3
          expect(ejson['child_events'].size).to eql 1
          expect(ejson['child_events'].first['own_reservation']).to be_truthy
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
          expect(json.size).to eql 1
          ejson = json.first
          expect(ejson.keys).to include 'child_events'
          expect(ejson['child_events'].size).to eql ejson['child_events_count']
          expect(ejson['child_events'].size).to eql 3
          expect(ejson['child_events'].select { |e| e['url'] }.size).to eql 1
          own_reservation = ejson['child_events'].select { |e| e['own_reservation'] }
          expect(own_reservation.size).to eql 1
          expect(own_reservation.first.keys).to match_array((expected_reservation_fields + ['own_reservation', 'user']))
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
          expect(json.size).to eql 1
          expect(json.first.keys).to match_array(expected_reservation_event_fields)
          expect(json.first['can_manage_appointment_group']).to eq false
          expect(json.first['id']).to eql my_personal_appointment.id

          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{mygroup.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [mygroup.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          expect(json.size).to eql 1
          expect(json.first.keys).to match_array(expected_reservation_event_fields - ['effective_context_code'])
          expect(json.first['id']).to eql my_group_appointment.id

          # if we go look at those appointment slots, they now show as reserved
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{ag1.asset_string}&context_codes[]=#{ag2.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [ag1.asset_string, ag2.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          expect(json.size).to eql 2
          json.sort_by! { |e| e['id'] }
          json.each do |e|
            expect(e.keys).to match_array(expected_reserved_fields)
            expect(e['reserved']).to be_truthy
            expect(e['child_events_count']).to eql 2
            expect(e['child_events'].size).to eql 1 # can't see otherguy's stuff
            expect(e['available_slots']).to eql 2
          end
          expect(json.first['child_events'].first.keys).to match_array((expected_reservation_fields + ['own_reservation', 'user']))
          expect(json.last['child_events'].first.keys).to match_array((expected_reservation_fields + ['own_reservation', 'group'] - ['effective_context_code']))

        end
      end

      context "multi-context appointment group with shared teacher" do
        before :once do
          @course1 = course_with_teacher(:active_all => true).course
          @course2 = course_with_teacher(:user => @teacher, :active_all => true).course
          @student1 = student_in_course(:course => @course1, :active_all => true).user
          @student2 = student_in_course(:course => @course2, :active_all => true).user
          @ag = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 1,
                                        :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
                                                              ["2012-01-01 13:00:00", "2012-01-01 14:00:00"]],
                                        :contexts => [@course1, @course2])
          @ag.publish
          @ag.appointments.first.reserve_for(@student1, @teacher)
          @ag.appointments.last.reserve_for(@student2, @teacher)
        end

        it "returns signups in multi-context appointment groups in the student's context" do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course1.asset_string}&context_codes[]=#{@course2.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [@course1.asset_string, @course2.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          expect(json.map { |event| [event['context_code'], event['child_events'][0]['user']['id']] }).to match_array(
            [[@course1.asset_string, @student1.id], [@course2.asset_string, @student2.id]]
          )
        end

        it "counts other contexts' signups when calculating available_slots for students" do
          json = api_call_as_user(@student1, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@ag.asset_string}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :context_codes => [@ag.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})
          expect(json.map { |event| event['available_slots'] }).to eq([0, 0])
        end
      end

      it "excludes signups in courses the teacher isn't enrolled in" do
        te1 = course_with_teacher(:active_all => true)
        te2 = course_with_teacher(:active_all => true)
        student1 = student_in_course(:course => te1.course, :active_all => true).user
        student2 = student_in_course(:course => te2.course, :active_all => true).user
        ag = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 1,
                                      :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
                                                            ["2012-01-01 13:00:00", "2012-01-01 14:00:00"]],
                                      :contexts => [te1.course, te2.course])
        ag.appointments.first.reserve_for(student1, te1.user)
        ag.appointments.last.reserve_for(student2, te2.user)
        json = api_call_as_user(te1.user, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{te1.course.asset_string}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json',
          :context_codes => [te1.course.asset_string], :start_date => '2012-01-01', :end_date => '2012-01-31'})

        a1 = json.detect { |h| h['id'] == ag.appointments.first.id }
        expect(a1['child_events_count']).to eq 1
        expect(a1['child_events'][0]['user']['id']).to eq student1.id

        a2 = json.detect { |h| h['id'] == ag.appointments.last.id }
        expect(a2['child_events_count']).to eq 0
        expect(a2['child_events']).to be_empty
      end

      context "reservations" do
        def prepare(as_student = false)
          Notification.create! :name => 'Appointment Canceled By User', :category => "TestImmediately"

          if as_student
            course_factory(active_all: true)
            @teacher = @course.admins.first
            student_in_course :course => @course, :user => @me, :active_all => true

            cc = @teacher.communication_channels.create!(path: "test_#{@teacher.id}@example.com", path_type: "email")
            cc.confirm
          end

          student_in_course(:course => @course, :user => (@other_guy = user_factory), :active_all => true)

          year = Time.now.year + 1
          @ag1 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["#{year}-01-01 12:00:00", "#{year}-01-01 13:00:00", "#{year}-01-01 13:00:00", "#{year}-01-01 14:00:00"]], :contexts => [@course])
          @ag1.publish!
          @event1 = @ag1.appointments.first
          @event2 = @ag1.appointments.last

          cat = @course.group_categories.create(name: "foo")
          @group = cat.groups.create(:context => @course)
          @group.users << @me
          @group.users << @other_guy
          @other_group = cat.groups.create(:context => @course)
          @me.reload
          @ag2 = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :sub_context_codes => [cat.asset_string], :new_appointments => [["#{year}-01-01 12:00:00", "#{year}-01-01 13:00:00"]], :contexts => [@course])
          @ag2.publish!
          @event3 = @ag2.appointments.first

          @user = @me
        end

        context "as a student" do
          before(:once) { prepare(true) }

          it "should reserve the appointment for @current_user" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json['can_manage_appointment_group']).to eq false
            expect(json['appointment_group_id']).to eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event3.id.to_s})
            expect(json.keys).to match_array(expected_reservation_event_fields - ['effective_context_code']) # group one is on the group, no effective context
            expect(json['appointment_group_id']).to eql(@ag2.id)
          end

          it "should not allow students to reserve non-appointment calendar_events" do
            e = @course.calendar_events.create
            raw_api_call(:post, "/api/v1/calendar_events/#{e.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => e.id.to_s})
            expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
          end

          it "should not allow students to reserve an appointment twice" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            expect(response).to be_successful
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            errors = JSON.parse(response.body)
            expect(errors.size).to eql 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "participant has already reserved this appointment"})
            expect(error['reservations'].size).to eql 1
          end

          it "should cancel existing reservations if cancel_existing = true" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s})
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json['appointment_group_id']).to eql(@ag1.id)
            expect(@ag1.reservations_for(@me).map(&:parent_calendar_event_id)).to eql [@event1.id]

            json = api_call(:post, "/api/v1/calendar_events/#{@event2.id}/reservations?cancel_existing=1", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event2.id.to_s, :cancel_existing => '1'})
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json['appointment_group_id']).to eql(@ag1.id)
            expect(@ag1.reservations_for(@me).map(&:parent_calendar_event_id)).to eql [@event2.id]
          end

          it "should should allow comments on the reservation" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations?comments=these%20are%20my%20comments", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :comments => 'these are my comments'})
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json['appointment_group_id']).to eql(@ag1.id)
            expect(json['comments']).to eql "these are my comments"
          end

          it "should not allow students to specify the participant" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
            errors = JSON.parse(response.body)
            expect(errors.size).to eql 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant"})
            expect(error['reservations'].size).to eql 0
          end

          context "sharding" do
            specs_require_sharding

            it "should allow students to specify themselves as the participant" do
              short_form_id = "#{Shard.current.id}~#{@user.id}"
              api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{short_form_id}", {
                :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => short_form_id})
              expect(response).to be_successful
            end
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
            expect(message.notification_name).to eq 'Appointment Canceled By User'
            expect(message.to).to eq "test_#{@teacher.id}@example.com"
            expect(message.body).to match(/Too busy/)
          end

          describe "past appointments" do
            before do
              @past_ag = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
              @past_ag.publish!
              @past_slot = @past_ag.appointments.first
            end

            it "does not allow a student to reserve a time slot in the past" do
              json = api_call(:post, "/api/v1/calendar_events/#{@past_slot.id}/reservations", {
                :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @past_slot.id.to_s },
                   {}, {}, { :expected_status => 403 })
              expect(json['message']).to eq("Cannot create or change reservation for past appointment")
            end

            it "does not allow a student to delete a past reservation" do
              reservation = @past_slot.reserve_for(@user, @teacher)
              json = api_call(:delete, "/api/v1/calendar_events/#{reservation.id}", {
                :controller => 'calendar_events_api', :action => 'destroy', :format => 'json', :id => reservation.id.to_s },
                   {}, {}, { :expected_status => 403 })
              expect(json['message']).to eq("Cannot create or change reservation for past appointment")
              expect(reservation.reload).not_to be_deleted
            end

            it "allows a teacher to delete a student's past reservation" do
              reservation = @past_slot.reserve_for(@user, @teacher)
              json = api_call_as_user(@teacher, :delete, "/api/v1/calendar_events/#{reservation.id}", {
                :controller => 'calendar_events_api', :action => 'destroy', :format => 'json', :id => reservation.id.to_s },
                   {}, {}, { :expected_status => 200 })
              expect(reservation.reload).to be_deleted
            end
          end
        end

        context "as an admin" do
          before(:once) { prepare }

          it "should allow admins to specify the participant" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @other_guy.id.to_s})
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json['appointment_group_id']).to eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations/#{@group.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event3.id.to_s, :participant_id => @group.id.to_s})
            expect(json.keys).to match_array(expected_reservation_event_fields - ['effective_context_code'])
            expect(json['appointment_group_id']).to eql(@ag2.id)
          end

          it "should reject invalid participants" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@me.id}", {
              :controller => 'calendar_events_api', :action => 'reserve', :format => 'json', :id => @event1.id.to_s, :participant_id => @me.id.to_s})
            errors = JSON.parse(response.body)
            expect(errors.size).to eql 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({"attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant"})
            expect(error['reservations'].size).to eql 0
          end
        end
      end

      context 'participants' do
        before :each do
          course_with_teacher(:active_all => true)
          @ag = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, contexts: [@course],
            participant_visibility: "protected", new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
                                                                    ["2012-01-01 13:00:00", "2012-01-01 14:00:00"]])
          @ag.publish!
          @event = @ag.appointments.first
          course_with_student(course: @course, active_all: true)
          @student1 = @student
          @event.reserve_for(@student1, @student1)
          course_with_student(course: @course, active_all: true)
          @student2 = @student
          @event.reserve_for(@student2, @student2)
        end

        it 'should return participants in the same appointment group slot for a student' do
          json = api_call_as_user(@student1, :get, "/api/v1/calendar_events/#{@event.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json'})
          expect(json).to eq [
            {
              "id" => @student1.id,
              "display_name" => @student1.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/about/#{@student1.id}"
            },
            {
              "id" => @student2.id,
              "display_name" => @student2.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/users/#{@student2.id}"
            }
          ]
        end

        it 'should return participants in the same appointment group slot for a teacher' do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events/#{@event.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json'})
          expect(json).to eq [
            {
              "id" => @student1.id,
              "display_name" => @student1.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/users/#{@student1.id}"
            },
            {
              "id" => @student2.id,
              "display_name" => @student2.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/users/#{@student2.id}"
            }
          ]
        end

        it 'should paginate participants' do
          @ag.participants_per_appointment = 15
          @ag.save!
          students = create_users_in_course(@course, 10, active_all: true)
          students.each do |student_id|
            student = User.find(student_id)
            @event.reserve_for(student, student)
          end
          json = api_call(:get, "/api/v1/calendar_events/#{@event.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json'})
          expect(json.length).to eq 10
          json = api_call(:get, "/api/v1/calendar_events/#{@event.id}/participants?page=2",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json', page: 2})
          expect(json.length).to eq 2
        end

        it 'should not list users participating in other appointment group slots' do
          course_with_student(course: @course, active_all: true)
          event2 = @ag.appointments.last
          event2.reserve_for(@student, @student)
          json = api_call_as_user(@student1, :get, "/api/v1/calendar_events/#{@event.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json'})
          expect(json).to eq [
            {
              "id" => @student1.id,
              "display_name" => @student1.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/about/#{@student1.id}"
            },
            {
              "id" => @student2.id,
              "display_name" => @student2.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/users/#{@student2.id}"
            }
          ]
          json = api_call(:get, "/api/v1/calendar_events/#{event2.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: event2.id.to_s, format: 'json'})
          expect(json).to eq [
            {
              "id" => @student.id,
              "display_name" => @student.short_name,
              "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
              "html_url" => "http://www.example.com/about/#{@student.id}"
            }
          ]
        end

        it 'should return 401 if not allowed to view participants' do
          @ag.participant_visibility = "private"
          @ag.save!
          api_call_as_user(@student1, :get, "/api/v1/calendar_events/#{@event.id}/participants",
            {controller: 'calendar_events_api', action: 'participants', id: @event.id.to_s, format: 'json'})
          expect(response.code).to eq '401'
        end
      end
    end

    it 'should get a single event' do
      event = @course.calendar_events.create(:title => 'event')
      json = api_call(:get, "/api/v1/calendar_events/#{event.id}", {
        :controller => 'calendar_events_api', :action => 'show', :id => event.id.to_s, :format => 'json'})
      expect(json.keys).to match_array expected_fields
      expect(json.slice('title', 'id')).to eql({'id' => event.id, 'title' => 'event'})
    end

    it 'should enforce permissions' do
      event = course_factory.calendar_events.create(:title => 'event')
      raw_api_call(:get, "/api/v1/calendar_events/#{event.id}", {
        :controller => 'calendar_events_api', :action => 'show', :id => event.id.to_s, :format => 'json'})
      expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
    end

    it 'should create a new event' do
      json = api_call(:post, "/api/v1/calendar_events",
                      {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
                      {:calendar_event => {:context_code => @course.asset_string, :title => "ohai"}})
      assert_status(201)
      expect(json.keys).to match_array expected_fields
      expect(json['title']).to eql 'ohai'
    end

    it 'should create recurring events if options have been specified' do
      start_at = Time.zone.now.utc.change(hour: 0, min: 1) # For pre-Normandy bug with all_day method in calendar_event.rb
      end_at = Time.zone.now.utc.change(hour: 23)
      json = api_call(:post, "/api/v1/calendar_events",
                      {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
                      {:calendar_event => {
                          :context_code => @course.asset_string,
                          :title => "ohai",
                          :start_at => start_at.iso8601,
                          :end_at => end_at.iso8601,
                          :duplicate => {
                              :count => "3",
                              :interval => "1",
                              :frequency => "weekly"
                          }
                       }
                      })
      assert_status(201)
      expect(json.keys).to match_array expected_fields
      expect(json['title']).to eq 'ohai'

      duplicates = json['duplicates']
      expect(duplicates.count).to eq 3

      duplicates.to_a.each_with_index do |duplicate, i|
        start_result = Time.iso8601(duplicate['calendar_event']['start_at'])
        end_result = Time.iso8601(duplicate['calendar_event']['end_at'])
        expect(duplicate['calendar_event']['title']).to eql 'ohai'
        expect(start_result).to eq(start_at + (i + 1).weeks)
        expect(end_result).to eq(end_at + (i + 1).weeks)
      end

    end

    it 'should respect recurring event limit' do
      start_at = Time.zone.now.utc.change(hour: 0, min: 1)
      end_at = Time.zone.now.utc.change(hour: 23)
      api_call(:post, "/api/v1/calendar_events",
        {:controller => 'calendar_events_api', :action => 'create', :format => 'json'},
         {:calendar_event => {
           :context_code => @course.asset_string,
           :title => "ohai",
           :start_at => start_at.iso8601,
           :end_at => end_at.iso8601,
           :duplicate => {
             :count => "201",
             :interval => "1",
             :frequency => "weekly"
           }
         }})
      assert_status(400)
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
      expect(json.keys).to match_array expected_fields
      expect(json['title']).to eql 'ohai'
      expect(json['start_at']).to eql '2012-01-09T12:00:00Z'
    end

    it 'should not update event if all_day, start_at, and end_at are provided in a request' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')

      json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                      {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                      {:calendar_event => {:start_at => '2012-01-08 12:00:00',:end_at => '2012-01-09 12:00:00', :all_day => true, :title => "ohai"}})
      expect(json['all_day']).to eql true
      expect(json['end_at']).to eql '2012-01-09T00:00:00Z'
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

    describe 'moving events between calendars' do
      it 'moves an event from a user to a course' do
        event = @user.calendar_events.create!(:title => 'event', :start_at => '2012-01-08 12:00:00')
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.to_param, :format => 'json'},
                        {:calendar_event => {:context_code => @course.asset_string}})
        expect(json['context_code']).to eq @course.asset_string
        expect(event.reload.context).to eq @course
      end

      it 'moves an event from a course to a user' do
        event = @course.calendar_events.create!(:title => 'event', :start_at => '2012-01-08 12:00:00')
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.to_param, :format => 'json'},
                        {:calendar_event => {:context_code => @user.asset_string}})
        expect(json['context_code']).to eq @user.asset_string
        expect(event.reload.context).to eq @user
      end

      context 'section-specific times' do
        before :once do
          @event = @course.calendar_events.build(:title => "test", :child_event_data => [{:start_at => "2012-01-01", :end_at => "2012-01-02", :context_code => @course.default_section.asset_string}])
          @event.updating_user = @user
          @event.save!
        end

        it 'refuses to move a parent event' do
          json = api_call(:put, "/api/v1/calendar_events/#{@event.id}",
                          {:controller => 'calendar_events_api', :action => 'update', :id => @event.to_param, :format => 'json'},
                          {:calendar_event => {:context_code => @user.asset_string}}, {}, { :expected_status => 400 })
          expect(json['message']).to include 'Cannot move events with section-specific times'
        end

        it 'refuses to move a child event' do
          child_event = @event.child_events.first
          expect(child_event).to be_present
          json = api_call(:put, "/api/v1/calendar_events/#{child_event.id}",
                          {:controller => 'calendar_events_api', :action => 'update', :id => child_event.to_param, :format => 'json'},
                          {:calendar_event => {:context_code => @user.asset_string}}, {}, { :expected_status => 400 })
          expect(json['message']).to include 'Cannot move events with section-specific times'
        end

        it "doesn't complain if you 'move' the event into the calendar it's already in" do
          api_call(:put, "/api/v1/calendar_events/#{@event.id}",
                          {:controller => 'calendar_events_api', :action => 'update', :id => @event.to_param, :format => 'json'},
                          {:calendar_event => {:context_code => @course.asset_string}})
          expect(response).to be_successful
        end
      end

      it 'refuses to move a Scheduler appointment' do
        ag = AppointmentGroup.create!(:title => "something", :participants_per_appointment => 4, :new_appointments => [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], :contexts => [@course])
        ag.publish!
        appointment = ag.appointments.first
        json = api_call(:put, "/api/v1/calendar_events/#{appointment.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => appointment.to_param, :format => 'json'},
                        {:calendar_event => {:context_code => @user.asset_string}}, {}, { :expected_status => 400 })
        expect(json['message']).to include 'Cannot move Scheduler appointments'
      end

      it 'verifies the caller has permission to create the event in the destination context' do
        other_course = Course.create!
        event = @course.calendar_events.create!(:title => 'event', :start_at => '2012-01-08 12:00:00')
        api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.to_param, :format => 'json'},
                        {:calendar_event => {:context_code => other_course.asset_string}}, {}, { :expected_status => 401 })
      end
    end

    it 'should delete an event' do
      event = @course.calendar_events.create(:title => 'event', :start_at => '2012-01-08 12:00:00')
      json = api_call(:delete, "/api/v1/calendar_events/#{event.id}",
                      {:controller => 'calendar_events_api', :action => 'destroy', :id => event.id.to_s, :format => 'json'})
      expect(json.keys).to match_array expected_fields
      expect(event.reload).to be_deleted
    end

    it 'should delete the appointment group if it has no appointments' do
      @course.root_account.enable_feature!(:better_scheduler)
      time = Time.utc(Time.now.year, Time.now.month, Time.now.day, 4, 20)
      @appointment_group = AppointmentGroup.create!(
        :title => "appointment group", :participants_per_appointment => 4,
        :new_appointments => [
          [time + 3.days, time + 3.days + 1.hour]
        ],
        :contexts => [@course]
      )

      api_call(:delete, "/api/v1/calendar_events/#{@appointment_group.appointments.first.id}",
                      {:controller => 'calendar_events_api', :action => 'destroy', :id => @appointment_group.appointments.first.id.to_s, :format => 'json'})
      expect(@appointment_group.reload).to be_deleted
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
      allow(HostUrl).to receive(:default_host).and_return('www.example.com')
      should_translate_user_content(@course, false) do |content|
        @course.calendar_events.create!(:description => content, :start_at => Time.now + 1.hours, :end_at => Time.now + 2.hours)
        json = api_call(:get, "/api/v1/courses/#{@course.id}",
                        :controller => 'courses', :action => 'show', :format => 'json', :id => @course.id.to_s)
        get json['calendar']['ics']
        expect(response).to be_successful
        cal = Icalendar.parse(response.body.dup)[0]
        cal.events[0].x_alt_desc
      end
    end

    it "should omit assignment description in ics feed for a course" do
      allow(HostUrl).to receive(:default_host).and_return('www.example.com')
      assignment_model(description: "secret stuff here")
      get "/feeds/calendars/#{@course.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar.parse(response.body.dup)[0]
      expect(cal.events[0].description).to eq nil
      expect(cal.events[0].x_alt_desc).to eq nil
    end

    it 'works when event descriptions contain paths to user attachments' do
      attachment_with_context(@user)
      @user.calendar_events.create!(description: "/users/#{@user.id}/files/#{@attachment.id}", start_at: Time.now)
      json = api_call(:get, "/api/v1/calendar_events", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json'
      })
      expect(response).to be_successful
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
        expect(json.keys).to match_array expected_fields
        expect(json['title']).to eql 'ohai'
        expect(json['child_events'].size).to eql 1
        expect(json['start_at']).to eql '2012-01-01T12:00:00Z' # inferred from child event
        expect(json['end_at']).to eql '2012-01-01T13:00:00Z'
        expect(json['hidden']).to be_truthy
      end

      it "should update an event with child events" do
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                        {:calendar_event => {:title => "ohai", :child_event_data => {"0" => {:start_at => "2012-01-01 13:00:00", :end_at => "2012-01-01 14:00:00", :context_code => @course.default_section.asset_string}}}})
        expect(json.keys).to match_array expected_fields
        expect(json['title']).to eql 'ohai'
        expect(json['child_events'].size).to eql 1
        expect(json['start_at']).to eql '2012-01-01T13:00:00Z'
        expect(json['end_at']).to eql '2012-01-01T14:00:00Z'
        expect(json['hidden']).to be_truthy
      end

      it "should remove all child events" do
        json = api_call(:put, "/api/v1/calendar_events/#{event.id}",
                        {:controller => 'calendar_events_api', :action => 'update', :id => event.id.to_s, :format => 'json'},
                        {:calendar_event => {:title => "ohai", :remove_child_events => '1'}})
        expect(json.keys).to match_array expected_fields
        expect(json['title']).to eql 'ohai'
        expect(json['child_events']).to be_empty
        expect(json['start_at']).to eq '2012-01-01T12:00:00Z'
        expect(json['end_at']).to eq '2012-01-01T13:00:00Z'
        expect(json['hidden']).to be_falsey
      end

      it "should add the section name to a child event's title" do
        child_event_id = event.child_event_ids.first
        json = api_call(:get, "/api/v1/calendar_events/#{child_event_id}",
                        {:controller => 'calendar_events_api', :action => 'show', :id => child_event_id.to_s, :format => 'json'})
        expect(json.keys).to match_array((expected_fields + ['effective_context_code']))
        expect(json['title']).to eql "event (#{@course.default_section.name})"
        expect(json['hidden']).to be_falsey
      end

      describe "visibility" do
        before(:once) do
          student_in_course(:course => @course, :active_all => true)
        end

        it "should include children of hidden events for teachers" do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events/#{event.id}",
                    {:controller => 'calendar_events_api', :action => 'show', :id => event.to_param, :format => 'json'})
          expect(json['child_events'].map { |e| e['id'] }).to match_array(event.child_events.map(&:id))
        end

        it "should omit children of hidden events for students" do
          json = api_call_as_user(@student, :get, "/api/v1/calendar_events/#{event.id}",
                    {:controller => 'calendar_events_api', :action => 'show', :id => event.to_param, :format => 'json'})
          expect(json['child_events']).to be_empty
        end
      end

      it "allows media comments in the event description" do
        event.description = '<a href="/media_objects/abcde" class="instructure_inline_media_comment audio_comment" id="media_comment_abcde"><img></a>'
        event.save!
        child_event_id = event.child_event_ids.first
        json = api_call(:get, "/api/v1/calendar_events/#{child_event_id}",
                        {:controller => 'calendar_events_api', :action => 'show', :id => child_event_id.to_s, :format => 'json'})
        expect(response).to be_successful
      end
    end
  end

  context 'assignments' do
    expected_fields = [
      'all_day', 'all_day_date', 'assignment', 'context_code', 'created_at',
      'description', 'end_at', 'html_url', 'id', 'start_at', 'title', 'type', 'updated_at',
      'url', 'workflow_state'
    ]

    it 'should return assignments within the given date range' do
      e1 = @course.assignments.create(:title => '1', :due_at => '2012-01-07 12:00:00')
      e2 = @course.assignments.create(:title => '2', :due_at => '2012-01-08 12:00:00')
      e3 = @course.assignments.create(:title => '3', :due_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-08'})
      expect(json.size).to eql 1
      expect(json.first.keys).to match_array expected_fields
      expect(json.first.slice('title', 'start_at', 'id')).to eql({'id' => "assignment_#{e2.id}", 'title' => '2', 'start_at' => '2012-01-08T12:00:00Z'})
    end

    it 'orders result set by base due_at' do
      e2 = @course.assignments.create(:title => '2', :due_at => '2012-01-08 12:00:00')
      e1 = @course.assignments.create(:title => '1', :due_at => '2012-01-07 12:00:00')
      e3 = @course.assignments.create(:title => '3', :due_at => '2012-01-19 12:00:00')

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-19'})
      expect(json.size).to eql 3
      expect(json.first.keys).to match_array expected_fields
      expect(json.map { |event| event['title'] }).to eq %w[1 2 3]
    end

    it 'should sort and paginate assignments' do
      undated = (1..7).map {|i| create_assignments(@course.id, 1, title: "#{@course.id}:#{i}", due_at: nil).first }
      dated = (1..18).map {|i| create_assignments(@course.id, 1, title: "#{@course.id}:#{i}", due_at: Time.parse('2012-01-20 12:00:00').advance(days: -i)).first }
      ids = dated.reverse + undated

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[0...10].map{|id| "assignment_#{id}"}

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=2", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10', :page => '2'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="next",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="prev",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[10...20].map{|id| "assignment_#{id}"}

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :all_events => 1, :per_page => '10', :page => '3'})
      expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.map{|a| a['id']}).to eql ids[20...25].map{|id| "assignment_#{id}"}
    end

    it 'should ignore invalid end_dates' do
      @course.assignments.create(:title => 'a', :due_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-08', :end_date => '2012-01-07'})
      expect(json.size).to eql 1
    end

    it 'should 400 for bad dates' do
      raw_api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=201-201-208&end_date=201-201-209&context_codes[]=course_#{@course.id}", {
        controller: 'calendar_events_api', action: 'index', format: 'json', type: 'assignment',
        context_codes: ["course_#{@course.id}"], start_date: '201-201-208', end_date: '201-201-209'})
      expect(response.code).to eql '400'
      json = JSON.parse response.body
      expect(json['errors']['start_date']).to eq 'Invalid date or invalid datetime for start_date'
      expect(json['errors']['end_date']).to eq 'Invalid date or invalid datetime for end_date'
    end

    it 'should return assignments from up to 10 contexts' do
      contexts = [@course.asset_string]
      course_ids = create_courses(15, enroll_user: @me)
      create_assignments(course_ids, 1, due_at: '2012-01-08 12:00:00')
      contexts.concat course_ids.map{ |id| "course_#{id}" }
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => contexts, :start_date => '2012-01-08', :end_date => '2012-01-07', :per_page => '25'})
      expect(json.size).to eql 9 # first context has no events
    end

    it 'should return undated assignments' do
      @course.assignments.create(:title => 'undated')
      @course.assignments.create(:title => "dated", :due_at => '2012-01-08 12:00:00')
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&undated=1&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :undated => '1'})
      expect(json.size).to eql 1
      expect(json.first['due_at']).to be_nil
    end

    it 'should mark assignments with user_submitted' do
      e1 = @course.assignments.create(:title => '1', :due_at => '2012-01-07 12:00:00')
      e2 = @course.assignments.create(:title => '2', :due_at => '2012-01-08 12:00:00')

      sub = e1.find_or_create_submission(@user)
      sub.submission_type = 'online_quiz'
      sub.workflow_state = 'submitted'
      sub.save!

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-06&end_date=2012-01-09&context_codes[]=course_#{@course.id}", {
        :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
        :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-06', :end_date => '2012-01-09'})

      expect(json.size).to eql 2
      expect(json[0]['assignment']['user_submitted']).to be_truthy
      expect(json[1]['assignment']['user_submitted']).to be_falsy
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

          expect(json.map{ |a| a['title'] }).to match_array [
            'published assignment 1',
            'published assignment 2',
            'unpublished assignment 1',
            'unpublished assignment 2'
          ]
        end
      end

      context 'for teachers and students' do
        before do
          @teacher_student = user_factory(active_all: true)
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

          expect(json.map{ |a| a['title'] }).to match_array [
            'published assignment 1',
            'published assignment 2',
            'unpublished assignment 1',
          ]
        end
      end

      context 'for students' do
        before do
          @teacher_student = user_factory(active_all: true)
          @course1.enroll_student(@teacher_student, :enrollment_state => 'active')
          @course2.enroll_student(@teacher_student, :enrollment_state => 'active')
        end

        it 'should return only published assignments' do
          json = api_call_as_user(@teacher_student,
            :get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
            :controller => 'calendar_events_api', :action => 'index', :format => 'json',
            :type => 'assignment', :all_events => '1', :context_codes => ["course_#{@course1.id}", "course_#{@course2.id}"]
          )

          expect(json.map{ |a| a['title'] }).to match_array [
            'published assignment 1',
            'published assignment 2',
          ]
        end
      end
    end

    context 'differentiated assignments' do
      before :once do
        Timecop.travel(Time.utc(2015)) do
          course_with_teacher(:active_course => true, :active_enrollment => true, :user => @teacher)

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
      end

      context 'as a student' do
        it "only shows events for visible assignments" do
          json = api_call_as_user(@student_in_overriden_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
          expect(json.size).to eql 2

          json = api_call_as_user(@student_in_general_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
          expect(json.size).to eql 1
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
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
            expect(json.size).to eql 2
          end
        end

        context 'following two students with visibility' do
          before do
            @observer_enrollment.update_attribute(:associated_user_id, @student_in_overriden_section.id)
            student_in_section(@section, user: @student_in_general_section)
            @course.enroll_user(@observer, "ObserverEnrollment", {:allow_multiple_enrollments => true, :associated_user_id => @student_in_general_section.id})
          end
          it "doesnt show duplicate events" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
            expect(json.size).to eql 2
          end
        end

        context 'following a student without visibility' do
          before{ @observer_enrollment.update_attribute(:associated_user_id, @student_in_general_section.id) }
          it "only shows events for assignments visible to that student" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
            expect(json.size).to eql 1
          end
        end
        context 'in a section only' do
          it "shows events for all active assignment" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
            expect(json.size).to eql 2
          end
        end
      end

      context 'as a teacher' do
        it "shows events for all active assignment" do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2011-01-08', :end_date => '2099-01-08'})
          expect(json.size).to eql 2
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
        expect(json.size).to eql 2
      end

      it 'should return all assignments, ignoring the undated flag' do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :undated => '1'})
        expect(json.size).to eql 2
      end

      it 'should return all assignments, ignoring the start_date and end_date' do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
          :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
          :context_codes => ["course_#{@course.id}"],
          :all_events => '1', :start_date => '2012-02-01', :end_date => '2012-02-01'})
        expect(json.size).to eql 2
      end
    end

    it 'should get a single assignment' do
      assignment = @course.assignments.create(:title => 'event')
      json = api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
        :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{assignment.id}", :format => 'json'})
      expect(json.keys).to match_array expected_fields
      expect(json.slice('title', 'id')).to eql({'id' => "assignment_#{assignment.id}", 'title' => 'event'})
    end

    it 'should enforce permissions' do
      assignment = course_factory.assignments.create(:title => 'event')
      raw_api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
        :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{assignment.id}", :format => 'json'})
      expect(JSON.parse(response.body)['status']).to eq 'unauthorized'
    end

    it 'should update assignment due dates' do
      assignment = @course.assignments.create(:title => 'undated')

      json = api_call(:put, "/api/v1/calendar_events/assignment_#{assignment.id}",
                      {:controller => 'calendar_events_api', :action => 'update', :id => "assignment_#{assignment.id}", :format => 'json'},
                      {:calendar_event => {:start_at => '2012-01-09 12:00:00'}})
      expect(json.keys).to match_array expected_fields
      expect(json['start_at']).to eql '2012-01-09T12:00:00Z'
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
          @student = user_factory :active_all => true, :active_state => 'active'
        end

        context 'when no sections' do
          before :once do
            @course.enroll_student(@student, :enrollment_state => 'active')
          end

          it 'should return an all-day override' do
            # make the assignment non-all day
            @default_assignment.due_at = DateTime.parse('2012-01-12 04:42:00')
            @default_assignment.save!
            expect(@default_assignment.all_day).to be_falsey
            expect(@default_assignment.all_day_date).to eq DateTime.parse('2012-01-12 04:42:00').to_date

            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-21 23:59:00'))
            expect(@override.all_day).to be_truthy
            expect(@override.all_day_date).to eq DateTime.parse('2012-01-21 23:59:00').to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31', :per_page => '25'})
            expect(json.size).to eq 1
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"

            expect(json.first['all_day']).to be_truthy
            expect(json.first['all_day_date']).to eq '2012-01-21'
          end

          it 'should return a non-all-day override' do
            @default_assignment.due_at = DateTime.parse('2012-01-12 23:59:00')
            @default_assignment.save!
            expect(@default_assignment.all_day).to be_truthy
            expect(@default_assignment.all_day_date).to eq DateTime.parse('2012-01-12 23:59:00').to_date

            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-21 04:42:00'))
            expect(@override.all_day).to be_falsey
            expect(@override.all_day_date).to eq DateTime.parse('2012-01-21 04:42:00').to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-01', :end_date => '2012-01-31', :per_page => '25'})
            expect(json.size).to eq 1
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"

            expect(json.first['all_day']).to be_falsey
            expect(json.first['all_day_date']).to eq '2012-01-21'
          end

          it 'should return a non-overridden assignment' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include('assignment_override')
          end

          it 'should return an override when present' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first['end_at']).to eq '2012-01-14T12:00:00Z'
            expect(json.first.keys).not_to include('assignment_override')
          end

          it 'should return assignment when override is in range but assignment is not' do
            @default_assignment.due_at = DateTime.parse('2012-01-01 12:00:00') # out of range
            @default_assignment.save!
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-08 12:00:00')) # in range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['end_at']).to eq '2012-01-08T12:00:00Z'
          end

          it 'should not return an assignment when assignment due_at in range but override is out' do
            assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                      :due_at => DateTime.parse('2012-01-17 12:00:00')) # out of range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 0 # nothing returned
          end

          it 'should return user specific override' do
            override = assignment_override_model(:assignment => @default_assignment,
                                                 :due_at => DateTime.parse('2012-01-12 12:00:00'))
            override.assignment_override_students.create!(:user => @user)
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
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
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include('assignment_override')
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
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first['end_at']).to eq '2012-01-14T12:00:00Z'
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
            expect(json.size).to eq 1
            expect(json.first['end_at']).to eq '2012-01-14T12:00:00Z'
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
            expect(json.size).to eq 1
            expect(json.first['end_at']).to eq '2012-01-14T12:00:00Z'
          end
        end
      end

      context 'as teacher' do
        it 'should return 1 assignment when no overrides' do
          json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
            :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
            :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
          expect(json.size).to eq 1 # 1 assignment
          expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
          expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
          expect(json.first.keys).not_to include('assignment_override')
        end

        it 'should get explicit assignment with override info' do
          skip 'not sure what the desired behavior here is'
          override = assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                               :due_at => DateTime.parse('2012-01-14 12:00:00'))
          json = api_call(:get, "/api/v1/calendar_events/assignment_#{@default_assignment.id}", {
            :controller => 'calendar_events_api', :action => 'show', :id => "assignment_#{@default_assignment.id}", :format => 'json'})
          #json.size.should == 2
          expect(json.slice('id', 'override_id', 'end_at')).to eql({'id' => "assignment_#{@default_assignment.id}",
                                                                'override_id' => override.id,
                                                                'end_at' => '2012-01-14T12:00:00Z'})
          expect(json.keys).to match_array expected_fields
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
            expect(json.size).to eq 3
            # sort results locally by end_at
            json.sort_by! { |a| a['end_at'] }
            expect(json[0].keys).not_to include('assignment_override')
            expect(json[1]['assignment_overrides'][0]['id']).to eq override1.id
            expect(json[2]['assignment_overrides'][0]['id']).to eq override2.id
            expect(json[0]['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json[1]['end_at']).to eq '2012-01-14T12:00:00Z'
            expect(json[2]['end_at']).to eq '2012-01-18T12:00:00Z'
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
            expect(json.size).to eq 1
            expect(json.first['assignment_overrides'][0]['id']).to eq override1.id
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
          end
        end
      end

      context 'as TA' do
        before :once do
          @ta = user_factory :active_all => true, :active_state => 'active'
        end

        context 'when no sections' do
          before :once do
            @course.enroll_user(@ta, 'TaEnrollment', :enrollment_state => 'active')
          end

          it 'should return a non-overridden assignment' do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include('assignment_override')
          end

          it 'should return override when present' do
            @default_assignment.due_at = DateTime.parse('2012-01-08 12:00:00')
            @default_assignment.save!
            override = assignment_override_model(:assignment => @default_assignment, :set => @course.default_section,
                                                 :due_at => DateTime.parse('2012-01-14 12:00:00'))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # should only return the overridden assignment if all sections have an override
            expect(json[0].keys).to include('assignment_overrides')
            expect(json[0]['end_at']).to eq '2012-01-14T12:00:00Z'
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
            expect(json.size).to eq 3 # all versions
            json.sort_by! { |a| a['end_at'] }
            expect(json[0].keys).not_to include('assignment_override')
            expect(json[0]['end_at']).to eq '2012-01-08T12:00:00Z'
            expect(json[1]['assignment_overrides'][0]['id']).to eq override1.id
            expect(json[1]['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json[2]['assignment_overrides'][0]['id']).to eq override2.id
            expect(json[2]['end_at']).to eq '2012-01-14T12:00:00Z'
          end
        end
      end

      context 'as observer' do
        before :once do
          @student = user_factory(active_all: true, :active_state => 'active')
          @observer = user_factory(active_all: true, :active_state => 'active')
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
            expect(json.size).to eq 1
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
          end
        end

        context 'when no sections' do
          it 'should return assignments with no override' do
            @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
              :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
              :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first['id']).to eq "assignment_#{@default_assignment.id}"
            expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
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
              expect(json.size).to eq 1 # only 1
              expect(json.first['end_at']).to eq '2012-01-13T12:00:00Z'
            end

            it 'should return standard assignment' do
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              expect(json.size).to eq 1 # only 1
              expect(json.first['end_at']).to eq '2012-01-12T12:00:00Z'
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
              expect(json.size).to eq 1
              expect(json.first['end_at']).to eq '2012-01-13T12:00:00Z'
            end

            it 'should return only override for student section' do
              assignment_override_model(:assignment => @default_assignment, :set => @section1,
                                        :due_at => DateTime.parse('2012-01-13 12:00:00'))
              assignment_override_model(:assignment => @default_assignment, :set => @section2,
                                        :due_at => DateTime.parse('2012-01-14 12:00:00'))

              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                :controller => 'calendar_events_api', :action => 'index', :format => 'json', :type => 'assignment',
                :context_codes => ["course_#{@course.id}"], :start_date => '2012-01-07', :end_date => '2012-01-16', :per_page => '25'})
              expect(json.size).to eq 1
              expect(json.first['end_at']).to eq '2012-01-13T12:00:00Z'
            end
          end

          context 'observing multiple students' do
            before :once do
              @student2 = user_factory(active_all: true, :active_state => 'active')
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
                expect(json.size).to eq 1
                expect(json.first['end_at']).to eq '2012-01-14T12:00:00Z'
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
                expect(json.size).to eq 2
                json.sort_by! { |a| a['end_at'] }
                expect(json[0]['end_at']).to eq '2012-01-14T12:00:00Z'
                expect(json[1]['end_at']).to eq '2012-01-15T12:00:00Z'
              end
            end

            context 'when in different courses' do
              before(:each) do
                @course1 = @course
                @course2 = course_factory(active_all: true)

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

                expect(json.size).to eq 2
                json.sort_by! { |a| a['end_at'] }
                expect(json[0]['end_at']).to eq '2012-01-14T12:00:00Z'
                expect(json[1]['end_at']).to eq '2012-01-15T12:00:00Z'
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
            expect(json.size).to eq 0 # 0 assignments returned
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
            expect(json.size).to eq 2
            # Should include the default and override in return
            json.sort_by! { |a| a['end_at'] }
            expect(json[0]['end_at']).to eq '2012-01-12T12:00:00Z'
            expect(json[0]['override_id']).to be_nil
            expect(json[0].keys).not_to include('assignment_override')
            expect(json[1]['end_at']).to eq '2012-01-15T12:00:00Z'
            expect(json[1]['assignment_overrides'][0]['id']).to eq override.id
          end
        end
      end
    end
  end

  context "user index" do
    before :once do
      @student = user_factory(active_all: true, active_state: 'active')
      @course.enroll_student(@student, enrollment_state: 'active')
      @observer = user_factory(active_all: true, active_state: 'active')
      @course.enroll_user(
        @observer,
        'ObserverEnrollment',
        enrollment_state: 'active',
        associated_user_id: @student.id
      )
      @observer.as_observer_observation_links.create do |uo|
        uo.user_id = @student.id
      end
      @contexts = [@course.asset_string]
      @ctx_str = @contexts.join("&context_codes[]=")
      @me = @observer
    end

    context "as manually enrolled observer" do
      before :once do
        course_with_observer(course: @course, active_enrollment: true, associated_user_id: @student.id)
      end

      it "should return calendar events" do
        3.times do |idx|
          @course.calendar_events.create(title: "event #{idx}", workflow_state: 'active')
        end
        json = api_call(:get,
          "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=#{@ctx_str}", {
          controller: 'calendar_events_api', action: 'user_index', format: 'json',
          context_codes: @contexts, all_events: true, user_id: @student.id})
        expect(json.length).to eql 3
      end
    end

    it "should return observee's calendar events" do
      3.times do |idx|
        @course.calendar_events.create(title: "event #{idx}", workflow_state: 'active')
      end
      json = api_call(:get,
        "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=#{@ctx_str}", {
        controller: 'calendar_events_api', action: 'user_index', format: 'json',
        context_codes: @contexts, all_events: true, user_id: @student.id})
      expect(json.length).to eql 3
    end

    it "should return submissions with assignments" do
      assg = @course.assignments.create(workflow_state: 'published', due_at: 3.days.from_now, submission_types: "online_text_entry")
      assg.submit_homework @student, submission_type: "online_text_entry"
      json = api_call(:get,
        "/api/v1/users/#{@student.id}/calendar_events?all_events=true&type=assignment&include[]=submission&context_codes[]=#{@ctx_str}", {
        controller: 'calendar_events_api', action: 'user_index', format: 'json', type: 'assignment', include: ['submission'],
        context_codes: @contexts, all_events: true, user_id: @student.id})
      expect(json.first['assignment']['submission']).not_to be_nil
    end
  end

  context "calendar feed" do
    before :once do
      time = Time.utc(Time.now.year, Time.now.month, Time.now.day, 4, 20)
      @student = user_factory(active_all: true, :active_state => 'active')
      @course.enroll_student(@student, :enrollment_state => 'active')
      @student2 = user_factory(active_all: true, :active_state => 'active')
      @course.enroll_student(@student2, :enrollment_state => 'active')


      @event = @course.calendar_events.create(:title => 'course event', :start_at => time + 1.day)
      @assignment = @course.assignments.create(:title => 'original assignment', :due_at => time + 2.days)
      @override = assignment_override_model(
        :assignment => @assignment, :due_at => @assignment.due_at + 3.days, :set => @course.default_section)

      @appointment_group = AppointmentGroup.create!(
        :title => "appointment group", :participants_per_appointment => 4,
        :new_appointments => [
          [time + 3.days, time + 3.days + 1.hour],
          [time + 3.days + 1.hour, time + 3.days + 2.hours],
          [time + 3.days + 2.hours, time + 3.days + 3.hours]],
        :contexts => [@course])

      @appointment_event = @appointment_group.appointments[0]
      @appointment = @appointment_event.reserve_for(@student, @student)

      @appointment_event2 = @appointment_group.appointments[1]
      @appointment2 = @appointment_event2.reserve_for(@student2, @student2)
    end

    it "should have events for the teacher" do
      raw_api_call(:get, "/feeds/calendars/#{@teacher.feed_code}.ics", {
        :controller => 'calendar_events_api', :action => 'public_feed', :format => 'ics', :feed_code => @teacher.feed_code})
      expect(response).to be_successful

      expect(response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip)).to match_array [
                                                                                         "assignment-override-#{@override.id}", "calendar-event-#{@event.id}",
                                                                                         "calendar-event-#{@appointment_event.id}", "calendar-event-#{@appointment_event2.id}"]
    end

    it "should have events for the student" do
      raw_api_call(:get, "/feeds/calendars/#{@student.feed_code}.ics", {
        :controller => 'calendar_events_api', :action => 'public_feed', :format => 'ics', :feed_code => @student.feed_code})
      expect(response).to be_successful

      expect(response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip)).to match_array [
                                                                                         "assignment-override-#{@override.id}", "calendar-event-#{@event.id}", "calendar-event-#{@appointment.id}"]

      # make sure the assignment actually has the override date
      expected_override_date_output = @override.due_at.utc.iso8601.gsub(/[-:]/, '').gsub(/\d\dZ$/, '00Z')
      expect(response.body.match(/DTSTART:\s*#{expected_override_date_output}/)).not_to be_nil
    end

    it "should include the appointment details in the teachers export" do
      get "/feeds/calendars/#{@teacher.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar.parse(response.body.dup)[0]
      appointment_text = "Unnamed Course\n" + "\n" + "Participants: \n" + "User\n" + "\n"
      expect(cal.events[1].description).to eq appointment_text
      expect(cal.events[2].description).to eq appointment_text
    end

    it "should not expose details of other students appts to a student" do
      get "/feeds/calendars/#{@user.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar.parse(response.body.dup)[0]
      expect(cal.events[1].description).to eq nil
    end

    it "should render unauthorized feed for bad code" do
      get "/feeds/calendars/user_garbage.ics"
      expect(response).to render_template('shared/unauthorized_feed')
    end
  end

  context 'save_selected_contexts' do
    it 'persists contexts' do
      json = api_call(:post, "/api/v1/calendar_events/save_selected_contexts", {
          controller: 'calendar_events_api',
          action: 'save_selected_contexts',
          format: 'json',
          selected_contexts: ['course_1', 'course_2', 'course_3']
      })
      expect(@user.reload.preferences[:selected_calendar_contexts]).to eq(['course_1', 'course_2', 'course_3'])
    end
  end

  context 'visible_contexts' do
    it 'includes custom colors' do
      @user.custom_colors[@course.asset_string] = '#0099ff'
      @user.save!

      json = api_call(:get, '/api/v1/calendar_events/visible_contexts', {
        controller: 'calendar_events_api',
        action: 'visible_contexts',
        format: 'json'
      })

      context = json['contexts'].find do |c|
        c['asset_string'] == @course.asset_string
      end
      expect(context['color']).to eq('#0099ff')
    end

    it 'includes whether the context has been selected' do
      @user.preferences[:selected_calendar_contexts] = [@course.asset_string];
      @user.save!

      json = api_call(:get, '/api/v1/calendar_events/visible_contexts', {
        controller: 'calendar_events_api',
        action: 'visible_contexts',
        format: 'json'
      })

      context = json['contexts'].find do |c|
        c['asset_string'] == @course.asset_string
      end
      expect(context['selected']).to be(true)
    end

    it 'includes course sections' do
      @section = @course.course_sections.try(:first)

      json = api_call(:get, '/api/v1/calendar_events/visible_contexts', {
        controller: 'calendar_events_api',
        action: 'visible_contexts',
        format: 'json'
      })

      context = json['contexts'].find do |c|
        c['sections'] && c['sections'].find do |s|
          s['id'] == @section.id.to_s
        end
      end
      expect(context).not_to be_nil
    end
  end

  describe '#set_course_timetable' do
    before :once do
      @path = "/api/v1/courses/#{@course.id}/calendar_events/timetable"
      @course.start_at = DateTime.parse("2016-05-06 1:00pm -0600")
      @course.conclude_at = DateTime.parse("2016-05-19 9:00am -0600")
      @course.time_zone = 'America/Denver'
      @course.save!
    end

    it "should check for valid options" do
      timetables = {"all" => [{:weekdays => "moonday", :start_time => "not a real time", :end_time => "this either"}]}
      json = api_call(:post, @path, {
        :course_id => @course.id.to_param, :controller => 'calendar_events_api',
        :action => 'set_course_timetable', :format => 'json'
      }, {:timetables => timetables}, {}, {:expected_status => 400})

      expect(json['errors']).to match_array(["invalid start time(s)", "invalid end time(s)", "weekdays are not valid"])
    end

    it "should create course-level events" do
      location_name = 'best place evr'
      timetables = {"all" => [{:weekdays => "monday, thursday", :start_time => "2:00 pm",
        :end_time => "3:30 pm", :location_name => location_name}]}

      expect {
        json = api_call(:post, @path, {
          :course_id => @course.id.to_param, :controller => 'calendar_events_api',
          :action => 'set_course_timetable', :format => 'json'
        }, {:timetables => timetables})
      }.to change(Delayed::Job, :count).by(1)

      run_jobs

      expected_events = [
        { :start_at => DateTime.parse("2016-05-09 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-09 3:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-12 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-12 3:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-16 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-16 3:30 pm -0600")}
      ]
      events = @course.calendar_events.for_timetable.to_a
      expect(events.map{|e| {:start_at => e.start_at, :end_at => e.end_at}}).to match_array(expected_events)
      expect(events.map(&:location_name).uniq).to eq [location_name]
    end

    it "should create section-level events" do
      section1 = @course.course_sections.create!
      section2 = @course.course_sections.new
      section2.sis_source_id = "sisss" # can even find by sis id, yay!
      section2.end_at = DateTime.parse("2016-05-25 9:00am -0600") # and also extend dates on the section
      section2.save!

      timetables = {
        section1.id => [{:weekdays => "Mon", :start_time => "2:00 pm", :end_time => "3:30 pm"}],
        "sis_section_id:#{section2.sis_source_id}" => [{:weekdays => "Thu", :start_time => "3:30 pm", :end_time => "4:30 pm"}]
      }

      expect {
        json = api_call(:post, @path, {
          :course_id => @course.id.to_param, :controller => 'calendar_events_api',
          :action => 'set_course_timetable', :format => 'json'
        }, {:timetables => timetables})
      }.to change(Delayed::Job, :count).by(2)

      run_jobs

      expected_events1 = [
        { :start_at => DateTime.parse("2016-05-09 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-09 3:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-16 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-16 3:30 pm -0600")}
      ]
      events1 = section1.calendar_events.for_timetable.to_a
      expect(events1.map{|e| {:start_at => e.start_at, :end_at => e.end_at}}).to match_array(expected_events1)

      expected_events2 = [
        { :start_at => DateTime.parse("2016-05-12 3:30 pm -0600"), :end_at => DateTime.parse("2016-05-12 4:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-19 3:30 pm -0600"), :end_at => DateTime.parse("2016-05-19 4:30 pm -0600")}
      ]
      events2 = section2.calendar_events.for_timetable.to_a
      expect(events2.map{|e| {:start_at => e.start_at, :end_at => e.end_at}}).to match_array(expected_events2)
    end

    it "should be able to retrieve the timetable afterwards" do
      timetables = {"all" => [{:weekdays => "monday, thursday", :start_time => "2:00 pm", :end_time => "3:30 pm"}]}

      #set the timetables
      api_call(:post, @path, {
        :course_id => @course.id.to_param, :controller => 'calendar_events_api',
        :action => 'set_course_timetable', :format => 'json'
      }, {:timetables => timetables})

      json = api_call(:get, @path, {
        :course_id => @course.id.to_param, :controller => 'calendar_events_api',
        :action => 'get_course_timetable', :format => 'json'
      })

      expected = {"all" => [{'weekdays' => "Mon,Thu", 'start_time' => "2:00 pm", 'end_time' => "3:30 pm",
        'course_start_at' => @course.start_at.iso8601, 'course_end_at' => @course.end_at.iso8601}]}
      expect(json).to eq expected
    end
  end

  describe '#set_course_timetable_events' do
    before :once do
      @path = "/api/v1/courses/#{@course.id}/calendar_events/timetable_events"
      @events = [
        { :start_at => DateTime.parse("2016-05-09 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-09 3:30 pm -0600")},
        { :start_at => DateTime.parse("2016-05-12 2:00 pm -0600"), :end_at => DateTime.parse("2016-05-12 3:30 pm -0600")},
      ]
    end

    it "should be able to create a bunch of events directly from a list" do
      expect {
        api_call(:post, @path, {
          :course_id => @course.id.to_param, :controller => 'calendar_events_api',
          :action => 'set_course_timetable_events', :format => 'json'
        }, {:events => @events})
      }.to change(Delayed::Job, :count).by(1)

      run_jobs

      events = @course.calendar_events.for_timetable.to_a
      expect(events.map{|e| {:start_at => e.start_at, :end_at => e.end_at}}).to match_array(@events)
    end

    it "should be able to create events for a course section" do
      section = @course.course_sections.create!
      expect {
        api_call(:post, @path, {
          :course_id => @course.id.to_param, :controller => 'calendar_events_api',
          :action => 'set_course_timetable_events', :format => 'json'
        }, {:events => @events, :course_section_id => section.id.to_param})
      }.to change(Delayed::Job, :count).by(1)

      run_jobs

      events = section.calendar_events.for_timetable.to_a
      expect(events.map{|e| {:start_at => e.start_at, :end_at => e.end_at}}).to match_array(@events)
    end
  end
end
