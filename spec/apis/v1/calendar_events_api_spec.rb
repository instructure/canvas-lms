# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe CalendarEventsApiController, type: :request do
  before :once do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
    course_with_teacher(active_all: true, user: user_with_pseudonym(active_user: true))
    @me = @user
  end

  context "events" do
    expected_fields = %w[
      all_context_codes
      all_day
      all_day_date
      blackout_date
      child_events
      child_events_count
      comments
      context_code
      created_at
      description
      duplicates
      end_at
      hidden
      html_url
      id
      location_address
      location_name
      parent_event_id
      start_at
      title
      type
      updated_at
      url
      workflow_state
      context_name
      context_color
      important_dates
      series_uuid
      rrule
    ]
    expected_slot_fields = (expected_fields + %w[appointment_group_id appointment_group_url can_manage_appointment_group available_slots participants_per_appointment reserve_url participant_type effective_context_code])
    expected_reservation_event_fields = (expected_fields + %w[appointment_group_id appointment_group_url can_manage_appointment_group effective_context_code participant_type])
    expected_reserved_fields = (expected_slot_fields + ["reserved", "reserve_comments"])
    expected_reservation_fields = expected_reservation_event_fields - ["child_events"]
    expected_series_fields = expected_fields + ["series_head", "series_natural_language"]

    context "returns events" do
      it "when start after and end before the given range dates" do
        # Requested range |------------|
        # Event range        |------|
        e = @course.calendar_events.create(title: "my event", start_at: "2023-06-15 12:00:00", end_at: "2023-06-16 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice("id", "title", "start_at", "end_at")).to eql({ "id" => e.id, "title" => "my event", "start_at" => "2023-06-15T12:00:00Z", "end_at" => "2023-06-16T12:00:00Z" })
      end

      it "when start before and end after the given range dates" do
        # Requested range   |------------|
        # Event range     |----------------|
        e = @course.calendar_events.create(title: "my event", start_at: "2023-05-15 12:00:00", end_at: "2023-07-15 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice("id", "title", "start_at", "end_at")).to eql({ "id" => e.id, "title" => "my event", "start_at" => "2023-05-15T12:00:00Z", "end_at" => "2023-07-15T12:00:00Z" })
      end

      it "when start before given start date" do
        # Requested range     |------------|
        # Event range     |------|
        e = @course.calendar_events.create(title: "my event", start_at: "2023-05-26 12:00:00", end_at: "2023-06-04 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice("id", "title", "start_at", "end_at")).to eql({ "id" => e.id, "title" => "my event", "start_at" => "2023-05-26T12:00:00Z", "end_at" => "2023-06-04T12:00:00Z" })
      end

      it "when end after the given end date" do
        # Requested range |------------|
        # Event range               |------|
        e = @course.calendar_events.create(title: "my event", start_at: "2023-06-27 12:00:00", end_at: "2023-07-15 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice("id", "title", "start_at", "end_at")).to eql({ "id" => e.id, "title" => "my event", "start_at" => "2023-06-27T12:00:00Z", "end_at" => "2023-07-15T12:00:00Z" })
      end

      it "except end before given date range" do
        # Requested range           |------------|
        # Event range     |------|
        @course.calendar_events.create(title: "my event", start_at: "2023-05-26 12:00:00", end_at: "2023-05-27 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 0
      end

      it "except start after given date range" do
        # Requested range |------------|
        # Event range                     |------|
        @course.calendar_events.create(title: "my event", start_at: "2023-07-05 12:00:00", end_at: "2023-07-06 12:00:00")

        json = api_call(:get,
                        "/api/v1/calendar_events?start_date=2023-05-28&end_date=2023-07-02&context_codes[]=course_#{@course.id}",
                        {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2023-05-28",
                          end_date: "2023-07-02"
                        })
        expect(json.size).to be 0
      end
    end

    it "hides location attributes when user is not logged in a public course" do
      @me = nil
      @user = nil
      @course.update(is_public: true, indexed: true)
      @course.calendar_events.create(
        title: "2",
        start_at: "2012-01-08 12:00:00",
        location_address: "test_address2",
        location_name: "steven house"
      )

      json = api_call(:get,
                      "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}",
                      {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-08",
                        end_date: "2012-01-08"
                      })
      expect(json.first.slice("location_address", "location_name")).to eql({})
    end

    it "shows location attributes when user logged in a public course" do
      @course.update(is_public: true, indexed: true)
      evt = @course.calendar_events.create(
        title: "2",
        start_at: "2012-01-08 12:00:00",
        location_address: "test_address2",
        location_name: "steven house"
      )
      json = api_call(:get,
                      "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}",
                      {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-08",
                        end_date: "2012-01-08"
                      })
      expect(json.first.slice("location_address", "location_name")).to eql({ "location_address" => evt.location_address, "location_name" => evt.location_name })
    end

    it "orders result set by start_at" do
      @course.calendar_events.create(title: "second", start_at: "2012-01-08 12:00:00")
      @course.calendar_events.create(title: "first", start_at: "2012-01-07 12:00:00")
      @course.calendar_events.create(title: "third", start_at: "2012-01-19 12:00:00")

      json = api_call(:get,
                      "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}",
                      {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-07",
                        end_date: "2012-01-19"
                      })
      expect(json.size).to be 3
      expect(json.first.keys).to match_array expected_fields
      expect(json.pluck("title")).to eq %w[first second third]
    end

    it "defaults to today's events for the current user if no parameters are specified" do
      Timecop.freeze("2012-01-29 12:00:00 UTC") do
        @user.calendar_events.create!(title: "yesterday", start_at: 1.day.ago) { |c| c.context = @user }
        e2 = @user.calendar_events.create!(title: "today", start_at: 0.days.ago) { |c| c.context = @user }
        @user.calendar_events.create!(title: "tomorrow", start_at: 1.day.from_now) { |c| c.context = @user }

        json = api_call(:get, "/api/v1/calendar_events", {
                          controller: "calendar_events_api", action: "index", format: "json"
                        })

        expect(json.size).to be 1
        expect(json.first.keys).to match_array expected_fields
        expect(json.first.slice("id", "title")).to eql({ "id" => e2.id, "title" => "today" })
      end
    end

    it "does not allow user to create calendar events" do
      testCourse = course_with_teacher(active_all: true, user: user_with_pseudonym(active_user: true))
      testCourse.context.destroy!
      json = api_call(:post,
                      "/api/v1/calendar_events.json",
                      {
                        controller: "calendar_events_api", action: "create", format: "json"
                      },
                      {
                        calendar_event: {
                          context_code: "course_#{testCourse.course_id}",
                          title: "API Test",
                          start_at: "2018-09-19T21:00:00Z",
                          end_at: "2018-09-19T22:00:00Z"
                        }
                      })
      expect(json.first[1]).to eql "cannot create event for deleted course"
    end

    context "timezones" do
      before :once do
        @akst = ActiveSupport::TimeZone.new("Alaska")

        @e1 = @user.calendar_events.create!(title: "yesterday in AKST", start_at: @akst.parse("2012-01-28 21:00:00")) { |c| c.context = @user }
        @e2 = @user.calendar_events.create!(title: "today in AKST", start_at: @akst.parse("2012-01-29 21:00:00")) { |c| c.context = @user }
        @e3 = @user.calendar_events.create!(title: "tomorrow in AKST", start_at: @akst.parse("2012-01-30 21:00:00")) { |c| c.context = @user }

        @user.update! time_zone: "Alaska"
      end

      it "shows today's events in user's timezone, even if UTC has crossed into tomorrow" do
        Timecop.freeze(@akst.parse("2012-01-29 22:00:00")) do
          json = api_call(:get, "/api/v1/calendar_events", {
                            controller: "calendar_events_api", action: "index", format: "json"
                          })

          expect(json.size).to be 1
          expect(json.first.keys).to match_array expected_fields
          expect(json.first.slice("id", "title")).to eql({ "id" => @e2.id, "title" => "today in AKST" })
        end
      end

      it "interprets user-specified date range in the user's time zone" do
        Timecop.freeze(@akst.parse("2012-01-29 22:00:00")) do
          api_call(:get, "/api/v1/calendar_events", {
                     controller: "calendar_events_api", action: "index", format: "json"
                   })

          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-28&end_date=2012-01-29&context_codes[]=user_#{@user.id}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: ["user_#{@user.id}"],
                            start_date: "2012-01-28",
                            end_date: "2012-01-29"
                          })
          expect(json.size).to be 2
          expect(json[0].keys).to match_array expected_fields
          expect(json[0].slice("id", "title")).to eql({ "id" => @e1.id, "title" => "yesterday in AKST" })
          expect(json[1].slice("id", "title")).to eql({ "id" => @e2.id, "title" => "today in AKST" })
        end
      end
    end

    it "sorts and paginate events" do
      undated = (1..7).map { |i| @course.calendar_events.create(title: "undated:#{i}", start_at: nil, end_at: nil).id }
      dated = (1..18).map { |i| @course.calendar_events.create(title: "dated:#{i}", start_at: Time.parse("2012-01-20 12:00:00").advance(days: -i)).id }
      ids = dated.reverse + undated

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql ids[0...10]

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=2", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10",
                        page: "2"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="next",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql ids[10...20]

      json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10",
                        page: "3"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events\?.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events\?.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql ids[20...25]
    end

    it "ignores invalid end_dates" do
      @course.calendar_events.create(title: "e", start_at: "2012-01-08 12:00:00")
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-08",
                        end_date: "2012-01-07"
                      })
      expect(json.size).to be 1
    end

    it "returns events from up to 10 contexts by default" do
      contexts = [@course.asset_string]
      course_ids = create_courses(15, enroll_user: @me)
      now = Time.now.utc
      create_records(CalendarEvent, course_ids.map { |id| { context_id: id, context_type: "Course", context_code: "course_#{id}", title: id, start_at: "2012-01-08 12:00:00", end_at: "2012-01-08 12:00:00", workflow_state: "active", created_at: now, updated_at: now } })
      contexts.concat(course_ids.map { |id| "course_#{id}" })
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: contexts,
                        start_date: "2012-01-08",
                        end_date: "2012-01-07",
                        per_page: "25"
                      })
      expect(json.size).to be 9 # first context has no events
    end

    it "returns events from contexts up to the account limit setting" do
      contexts = [@course.asset_string]
      Account.default.settings[:calendar_contexts_limit] = 15
      Account.default.save!
      course_ids = create_courses(20, enroll_user: @me)
      now = Time.now.utc
      create_records(CalendarEvent, course_ids.map { |id| { context_id: id, context_type: "Course", context_code: "course_#{id}", title: id, start_at: "2012-01-08 12:00:00", end_at: "2012-01-08 12:00:00", workflow_state: "active", created_at: now, updated_at: now } })
      contexts.concat(course_ids.map { |id| "course_#{id}" })
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: contexts,
                        start_date: "2012-01-08",
                        end_date: "2012-01-07",
                        per_page: "25"
                      })
      expect(json.size).to be 14 # first context has no events
    end

    it "does not count appointment groups against the context limit" do
      Account.default.settings[:calendar_contexts_limit] = 1
      Account.default.save!
      group1 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
      group1.publish!
      contexts = [@course, group1].map(&:asset_string)
      student_in_course active_all: true
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-02&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: contexts,
                        start_date: "2012-01-01",
                        end_date: "2012-01-02",
                        per_page: "25"
                      })
      slot = json.detect { |thing| thing["appointment_group_id"] == group1.id }
      expect(slot).not_to be_nil
    end

    it "accepts a more compact comma-separated list of appointment group ids" do
      ags = (0..2).map do |x|
        ag = AppointmentGroup.create!(title: "ag #{x}", new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
        ag.publish!
        ag
      end
      ag_id_list = ags.map(&:id).join(",")
      student_in_course active_all: true
      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-02&per_page=25&appointment_group_ids=" + ag_id_list, {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        appointment_group_ids: ag_id_list,
                        start_date: "2012-01-01",
                        end_date: "2012-01-02",
                        per_page: "25"
                      })
      expect(json.pluck("appointment_group_id")).to match_array(ags.map(&:id))
      expect(response.headers["Link"]).to include "appointment_group_ids="
    end

    it "fails with unauthorized if provided a context the user cannot access" do
      contexts = [@course.asset_string]

      # second context the user cannot access
      course_factory
      @course.calendar_events.create(title: "unauthorized_course", start_at: "2012-01-08 12:00:00")
      contexts.push(@course.asset_string)

      api_call(:get,
               "/api/v1/calendar_events?start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=#{contexts.join("&context_codes[]=")}",
               {
                 controller: "calendar_events_api",
                 action: "index",
                 format: "json",
                 context_codes: contexts,
                 start_date: "2012-01-08",
                 end_date: "2012-01-07",
                 per_page: "25"
               },
               {},
               {},
               { expected_status: 401 })
    end

    it "allows specifying an unenrolled but accessible context" do
      unrelated_course = Course.create!(account: Account.default, name: "unrelated course")
      Account.default.account_users.create!(user: @user)
      CalendarEvent.create!(title: "from unrelated one", start_at: Time.now, end_at: 5.hours.from_now) { |c| c.context = unrelated_course }

      json = api_call(:get,
                      "/api/v1/calendar_events",
                      { controller: "calendar_events_api", action: "index", format: "json", },
                      { start_date: 2.days.ago.strftime("%Y-%m-%d"), end_date: 2.days.from_now.strftime("%Y-%m-%d"), context_codes: ["course_#{unrelated_course.id}"] })
      expect(json.size).to eq 1
      expect(json.first["title"]).to eq "from unrelated one"
    end

    it "allows account admins to view section-specific events" do
      event = @course.calendar_events.build(title: "event", child_event_data: { "0" => { start_at: "2012-01-09 12:00:00", end_at: "2012-01-09 13:00:00", context_code: @course.default_section.asset_string } })
      event.updating_user = @teacher
      event.save!
      account_admin_user(active_all: true)

      json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-07",
                        end_date: "2012-01-19"
                      })

      expect(json.detect { |e| e["id"] == event.child_events.first.id && e["hidden"] == false }).to be_present
    end

    it "allows users without read_roster permission to view section-specific events" do
      event = @course.calendar_events.build(title: "event", child_event_data: { "0" => { start_at: "2012-01-09 12:00:00", end_at: "2012-01-09 13:00:00", context_code: @course.default_section.asset_string } })
      event.updating_user = @teacher
      event.save!
      account_admin_user(active_all: true)

      student_role = Role.get_built_in_role("StudentEnrollment", root_account_id: @course.account.id)
      RoleOverride.create!(
        permission: "read_roster",
        enabled: false,
        role: student_role,
        account: @course.account
      )

      @student1 = user_factory(active_all: true, active_state: "active")
      @student1_enrollment = StudentEnrollment.create!(user: @student1, workflow_state: "active", course_section: @course.default_section, course: @course, limit_privileges_to_course_section: true)

      json = api_call_as_user(@student1, :get, "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                context_codes: ["course_#{@course.id}"],
                                start_date: "2012-01-07",
                                end_date: "2012-01-19"
                              })

      expect(@course.grants_right?(@student1, :read_roster)).to be_falsey
      expect(json.detect { |e| e["id"] == event.child_events.first.id && e["hidden"] == false }).to be_present
    end

    it "doesn't allow account admins to view events for courses they don't have access to" do
      sub_account1 = Account.default.sub_accounts.create!
      course_with_teacher(active_all: true, account: sub_account1)
      event = @course.calendar_events.build(title: "event", child_event_data: { "0" => { start_at: "2012-01-09 12:00:00", end_at: "2012-01-09 13:00:00", context_code: @course.default_section.asset_string } })
      event.updating_user = @teacher
      event.save!

      sub_account2 = Account.default.sub_accounts.create!
      account_admin_user(active_all: true, account: sub_account2)

      api_call(:get,
               "/api/v1/calendar_events?start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}",
               {
                 controller: "calendar_events_api",
                 action: "index",
                 format: "json",
                 context_codes: ["course_#{@course.id}"],
                 start_date: "2012-01-07",
                 end_date: "2012-01-19"
               },
               {},
               {},
               { expected_status: 401 })
    end

    def public_course_query(options = {})
      yield @course if block_given?
      @course.save!
      @user = nil

      # both calls are made on a public syllabus access
      # events
      @course.calendar_events.create! title: "some event", start_at: 1.month.from_now
      api_call(:get,
               "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=course_#{@course.id}&type=event&all_events=1",
               {
                 controller: "calendar_events_api",
                 action: "index",
                 format: "json",
                 type: "event",
                 all_events: "1",
                 context_codes: ["course_#{@course.id}"],
                 start_date: "2012-01-01",
                 end_date: "2012-01-31"
               },
               options[:body_params] || {},
               options[:headers] || {},
               options[:opts] || {})

      # assignments
      @course.assignments.create! title: "teh assignment", due_at: 1.month.from_now
      api_call(:get,
               "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=course_#{@course.id}&type=assignment&all_events=1",
               {
                 controller: "calendar_events_api",
                 action: "index",
                 format: "json",
                 type: "assignment",
                 all_events: "1",
                 context_codes: ["course_#{@course.id}"],
                 start_date: "2012-01-01",
                 end_date: "2012-01-31"
               },
               options[:body_params] || {},
               options[:headers] || {},
               options[:opts] || {})
    end

    it "does not allow anonymous users to access a non-public context" do
      course_factory(active_all: true)
      public_course_query(opts: { expected_status: 401 })
    end

    it "allows anonymous users to access public context" do
      @user = nil
      public_course_query(opts: { expected_status: 200 }) do |c|
        c.is_public = true
      end
    end

    it "allows anonymous users to access a public syllabus" do
      @user = nil
      public_course_query(opts: { expected_status: 200 }) do |c|
        c.public_syllabus = true
      end
    end

    it "does not allow anonymous users to access a public for authenticated syllabus" do
      @user = nil
      public_course_query(opts: { expected_status: 401 }) do |c|
        c.public_syllabus = false
        c.public_syllabus_to_auth = true
      end
    end

    it "returns undated events" do
      @course.calendar_events.create(title: "undated")
      @course.calendar_events.create(title: "dated", start_at: "2012-01-08 12:00:00")
      json = api_call(:get, "/api/v1/calendar_events?undated=1&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: ["course_#{@course.id}"],
                        undated: "1"
                      })
      expect(json.size).to be 1
      expect(json.first["start_at"]).to be_nil
    end

    context "all events" do
      before :once do
        @course.calendar_events.create(title: "undated")
        @course.calendar_events.create(title: "dated", start_at: "2012-01-08 12:00:00")
      end

      it "returns all events" do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1"
                        })
        expect(json.size).to be 2
      end

      it "returns all events, ignoring the undated flag" do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1",
                          undated: "1"
                        })
        expect(json.size).to be 2
      end

      it "returns all events, ignoring the start_date and end_date" do
        json = api_call(:get, "/api/v1/calendar_events?all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1",
                          start_date: "2012-02-01",
                          end_date: "2012-02-01"
                        })
        expect(json.size).to be 2
      end
    end

    context "appointments" do
      it "includes appointments for teachers (with participant info)" do
        ag1 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
        event1 = ag1.appointments.first
        student_ids = []
        3.times do
          event1.reserve_for(student_in_course(course: @course, active_all: true).user, @me)
          student_ids << @user.id
        end

        cat = @course.group_categories.create(name: "foo")
        ag2 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, sub_context_codes: [cat.asset_string], new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
        event2 = ag2.appointments.first
        group_ids = []
        group_student_ids = []
        3.times do
          g = cat.groups.create(context: @course)
          g.users << user_factory
          event2.reserve_for(g, @me)
          group_ids << g.id
          group_student_ids << @user.id
        end

        @user = @me
        json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course.asset_string}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: [@course.asset_string],
                          start_date: "2012-01-01",
                          end_date: "2012-01-31"
                        })
        expect(json.size).to be 2
        json.sort_by! { |e| e["id"] }

        e1json = json.first
        expect(e1json.keys).to match_array(expected_slot_fields)
        expect(e1json["reserve_url"]).to match %r{calendar_events/#{event1.id}/reservations/%7B%7B%20id%20%7D%7D}
        expect(e1json["participant_type"]).to eq "User"
        expect(e1json["can_manage_appointment_group"]).to be true
        expect(e1json["child_events"].size).to be 3
        e1json["child_events"].each do |e|
          expect(e.keys).to match_array((expected_reservation_fields + ["user"]))
          expect(student_ids).to include e["user"]["id"]
        end

        e2json = json.last
        expect(e2json.keys).to match_array(expected_slot_fields)
        expect(e2json["reserve_url"]).to match %r{calendar_events/#{event2.id}/reservations/%7B%7B%20id%20%7D%7D}
        expect(e2json["participant_type"]).to eq "Group"
        expect(e1json["can_manage_appointment_group"]).to be true
        expect(e2json["child_events"].size).to be 3
        e2json["child_events"].each do |e|
          expect(e.keys).to match_array((expected_reservation_fields + ["group"] - ["effective_context_code"]))
          expect(group_ids).to include e["group"]["id"]
          expect(group_student_ids).to include e["group"]["users"].first["id"]
        end
      end

      context "basic scenarios" do
        before :once do
          course_factory(active_all: true)
          @teacher = @course.admins.first
          student_in_course course: @course, user: @me, active_all: true
        end

        it "returns events from reservable appointment_groups, if specified as a context" do
          group1 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
          group1.publish!
          event1 = group1.appointments.first
          3.times { event1.reserve_for(student_in_course(course: @course, active_all: true).user, @teacher) }

          cat = @course.group_categories.create(name: "foo")
          group2 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, sub_context_codes: [cat.asset_string], new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
          group2.publish!
          event2 = group2.appointments.first
          g = cat.groups.create(context: @course)
          g.users << @me
          event2.reserve_for(g, @teacher)

          @user = @me
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{group1.asset_string}&context_codes[]=#{group2.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [group1.asset_string, group2.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          expect(json.size).to be 2
          json.sort_by! { |e| e["id"] }

          ejson = json.first
          expect(ejson.keys).to match_array(expected_reserved_fields)
          expect(ejson["child_events"]).to eq [] # not reserved, so no child events can be seen
          expect(ejson["reserve_url"]).to match %r{calendar_events/#{event1.id}/reservations/#{@me.id}}
          expect(ejson["reserved"]).to be_falsey
          expect(ejson["available_slots"]).to be 1

          ejson = json.last
          expect(ejson.keys).to match_array(expected_reserved_fields)
          expect(ejson["reserve_url"]).to match %r{calendar_events/#{event2.id}/reservations/#{g.id}}
          expect(ejson["reserved"]).to be_truthy
          expect(ejson["available_slots"]).to be 3
        end

        it "does not return child_events for other students, if the appointment group doesn't allows it" do
          group = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, participant_visibility: "private", new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
          group.publish!
          event = group.appointments.first
          event.reserve_for(@me, @teacher)
          2.times { event.reserve_for(student_in_course(course: @course, active_all: true).user, @teacher) }

          @user = @me
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{group.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [group.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          expect(json.size).to be 1
          ejson = json.first
          expect(ejson.keys).to include "child_events"
          expect(ejson["child_events_count"]).to be 3
          expect(ejson["child_events"].size).to be 1
          expect(ejson["child_events"].first["own_reservation"]).to be_truthy
        end

        it "returns child_events for students, if the appointment group allows it" do
          group = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, participant_visibility: "protected", new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
          group.publish!
          event = group.appointments.first
          event.reserve_for(@me, @teacher)
          2.times { event.reserve_for(student_in_course(course: @course, active_all: true).user, @teacher) }

          @user = @me
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{group.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [group.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          expect(json.size).to be 1
          ejson = json.first
          expect(ejson.keys).to include "child_events"
          expect(ejson["child_events"].size).to eql ejson["child_events_count"]
          expect(ejson["child_events"].size).to be 3
          expect(ejson["child_events"].count { |e| e["url"] }).to be 1
          own_reservation = ejson["child_events"].select { |e| e["own_reservation"] }
          expect(own_reservation.size).to be 1
          expect(own_reservation.first.keys).to match_array((expected_reservation_fields + ["own_reservation", "user"]))
        end

        it "returns own appointment_participant events in their effective contexts" do
          otherguy = student_in_course(course: @course, active_all: true).user

          course1 = @course
          course_with_teacher(user: @teacher, active_all: true)
          course2, @course = @course, course1

          ag1 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [course2])
          ag1.publish!
          ag1.contexts = [course1, course2]
          ag1.save!
          event1 = ag1.appointments.first
          my_personal_appointment = event1.reserve_for(@me, @me)
          event1.reserve_for(otherguy, otherguy)

          cat = @course.group_categories.create(name: "foo")
          mygroup = cat.groups.create(context: @course)
          mygroup.users << @me
          othergroup = cat.groups.create(context: @course)
          othergroup.users << otherguy
          @me.reload

          ag2 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, sub_context_codes: [cat.asset_string], new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [course1])
          ag2.publish!
          event2 = ag2.appointments.first
          my_group_appointment = event2.reserve_for(mygroup, @me)
          event2.reserve_for(othergroup, otherguy)

          @user = @me
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [@course.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          # the group appointment won't show on the course calendar
          expect(json.size).to be 1
          expect(json.first.keys).to match_array(expected_reservation_event_fields)
          expect(json.first["can_manage_appointment_group"]).to be false
          expect(json.first["id"]).to eql my_personal_appointment.id

          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{mygroup.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [mygroup.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          expect(json.size).to be 1
          expect(json.first.keys).to match_array(expected_reservation_event_fields - ["effective_context_code"])
          expect(json.first["id"]).to eql my_group_appointment.id

          # if we go look at those appointment slots, they now show as reserved
          json = api_call(:get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{ag1.asset_string}&context_codes[]=#{ag2.asset_string}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            context_codes: [ag1.asset_string, ag2.asset_string],
                            start_date: "2012-01-01",
                            end_date: "2012-01-31"
                          })
          expect(json.size).to be 2
          json.sort_by! { |e| e["id"] }
          json.each do |e|
            expect(e.keys).to match_array(expected_reserved_fields)
            expect(e["reserved"]).to be_truthy
            expect(e["child_events_count"]).to be 2
            expect(e["child_events"].size).to be 1 # can't see otherguy's stuff
            expect(e["available_slots"]).to be 2
          end
          expect(json.first["child_events"].first.keys).to match_array((expected_reservation_fields + ["own_reservation", "user"]))
          expect(json.last["child_events"].first.keys).to match_array((expected_reservation_fields + ["own_reservation", "group"] - ["effective_context_code"]))
        end
      end

      context "multi-context appointment group with shared teacher" do
        before :once do
          @course1 = course_with_teacher(active_all: true).course
          @course2 = course_with_teacher(user: @teacher, active_all: true).course
          @student1 = student_in_course(course: @course1, active_all: true).user
          @student2 = student_in_course(course: @course2, active_all: true).user
          @ag = AppointmentGroup.create!(title: "something",
                                         participants_per_appointment: 1,
                                         new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
                                                            ["2012-01-01 13:00:00", "2012-01-01 14:00:00"]],
                                         contexts: [@course1, @course2])
          @ag.publish
          @ag.appointments.first.reserve_for(@student1, @teacher)
          @ag.appointments.last.reserve_for(@student2, @teacher)
        end

        it "returns signups in multi-context appointment groups in the student's context" do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@course1.asset_string}&context_codes[]=#{@course2.asset_string}", {
                                    controller: "calendar_events_api",
                                    action: "index",
                                    format: "json",
                                    context_codes: [@course1.asset_string, @course2.asset_string],
                                    start_date: "2012-01-01",
                                    end_date: "2012-01-31"
                                  })
          expect(json.map { |event| [event["context_code"], event["child_events"][0]["user"]["id"]] }).to match_array(
            [[@course1.asset_string, @student1.id], [@course2.asset_string, @student2.id]]
          )
        end

        it "counts other contexts' signups when calculating available_slots for students" do
          json = api_call_as_user(@student1, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{@ag.asset_string}", {
                                    controller: "calendar_events_api",
                                    action: "index",
                                    format: "json",
                                    context_codes: [@ag.asset_string],
                                    start_date: "2012-01-01",
                                    end_date: "2012-01-31"
                                  })
          expect(json.pluck("available_slots")).to eq([0, 0])
        end
      end

      it "excludes signups in courses the teacher isn't enrolled in" do
        te1 = course_with_teacher(active_all: true)
        te2 = course_with_teacher(active_all: true)
        student1 = student_in_course(course: te1.course, active_all: true).user
        student2 = student_in_course(course: te2.course, active_all: true).user
        ag = AppointmentGroup.create!(title: "something",
                                      participants_per_appointment: 1,
                                      new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
                                                         ["2012-01-01 13:00:00", "2012-01-01 14:00:00"]],
                                      contexts: [te1.course, te2.course])
        ag.appointments.first.reserve_for(student1, te1.user)
        ag.appointments.last.reserve_for(student2, te2.user)
        json = api_call_as_user(te1.user, :get, "/api/v1/calendar_events?start_date=2012-01-01&end_date=2012-01-31&context_codes[]=#{te1.course.asset_string}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  context_codes: [te1.course.asset_string],
                                  start_date: "2012-01-01",
                                  end_date: "2012-01-31"
                                })

        a1 = json.detect { |h| h["id"] == ag.appointments.first.id }
        expect(a1["child_events_count"]).to eq 1
        expect(a1["child_events"][0]["user"]["id"]).to eq student1.id

        a2 = json.detect { |h| h["id"] == ag.appointments.last.id }
        expect(a2["child_events_count"]).to eq 0
        expect(a2["child_events"]).to be_empty
      end

      context "reservations" do
        def prepare(as_student = false)
          Notification.create! name: "Appointment Canceled By User", category: "TestImmediately"

          if as_student
            course_factory(active_all: true)
            @teacher = @course.admins.first
            student_in_course course: @course, user: @me, active_all: true

            cc = @teacher.communication_channels.create!(path: "test_#{@teacher.id}@example.com", path_type: "email")
            cc.confirm
          end

          student_in_course(course: @course, user: (@other_guy = user_factory), active_all: true)

          year = Time.now.year + 1
          @ag1 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["#{year}-01-01 12:00:00", "#{year}-01-01 13:00:00", "#{year}-01-01 13:00:00", "#{year}-01-01 14:00:00"]], contexts: [@course])
          @ag1.publish!
          @event1 = @ag1.appointments.first
          @event2 = @ag1.appointments.last

          cat = @course.group_categories.create(name: "foo")
          @group = cat.groups.create(context: @course)
          @group.users << @me
          @group.users << @other_guy
          @other_group = cat.groups.create(context: @course)
          @me.reload
          @ag2 = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, sub_context_codes: [cat.asset_string], new_appointments: [["#{year}-01-01 12:00:00", "#{year}-01-01 13:00:00"]], contexts: [@course])
          @ag2.publish!
          @event3 = @ag2.appointments.first

          @user = @me
        end

        context "as a student" do
          before(:once) { prepare(true) }

          it "reserves the appointment for @current_user" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json["can_manage_appointment_group"]).to be false
            expect(json["appointment_group_id"]).to eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event3.id.to_s
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields - ["effective_context_code"]) # group one is on the group, no effective context
            expect(json["appointment_group_id"]).to eql(@ag2.id)
          end

          it "does not allow students to reserve non-appointment calendar_events" do
            e = @course.calendar_events.create
            raw_api_call(:post, "/api/v1/calendar_events/#{e.id}/reservations", {
                           controller: "calendar_events_api", action: "reserve", format: "json", id: e.id.to_s
                         })
            expect(JSON.parse(response.body)["status"]).to eq "unauthorized"
          end

          it "does not allow students to reserve an appointment twice" do
            api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                       controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s
                     })
            expect(response).to be_successful
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                           controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s
                         })
            errors = JSON.parse(response.body)
            expect(errors.size).to be 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({ "attribute" => "reservation", "type" => "calendar_event", "message" => "participant has already reserved this appointment" })
            expect(error["reservations"].size).to be 1
          end

          it "cancels existing reservations if cancel_existing = true" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json["appointment_group_id"]).to eql(@ag1.id)
            expect(@ag1.reservations_for(@me).map(&:parent_calendar_event_id)).to eql [@event1.id]

            json = api_call(:post, "/api/v1/calendar_events/#{@event2.id}/reservations?cancel_existing=1", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event2.id.to_s, cancel_existing: "1"
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json["appointment_group_id"]).to eql(@ag1.id)
            expect(@ag1.reservations_for(@me).map(&:parent_calendar_event_id)).to eql [@event2.id]
          end

          it "shoulds allow comments on the reservation" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations?comments=these%20are%20my%20comments", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s, comments: "these are my comments"
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json["appointment_group_id"]).to eql(@ag1.id)
            expect(json["comments"]).to eql "these are my comments"
          end

          it "does not allow students to specify the participant" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
                           controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s, participant_id: @other_guy.id.to_s
                         })
            errors = JSON.parse(response.body)
            expect(errors.size).to be 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({ "attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant" })
            expect(error["reservations"].size).to be 0
          end

          context "sharding" do
            specs_require_sharding

            it "allows students to specify themselves as the participant" do
              short_form_id = "#{Shard.current.id}~#{@user.id}"
              api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{short_form_id}", {
                         controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s, participant_id: short_form_id
                       })
              expect(response).to be_successful
            end
          end

          it "notifies the teacher when appointment is canceled" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations", {
                              controller: "calendar_events_api",
                              action: "reserve",
                              format: "json",
                              id: @event1.id.to_s
                            })

            reservation = CalendarEvent.find(json["id"])

            raw_api_call(:delete,
                         "/api/v1/calendar_events/#{reservation.id}",
                         {
                           controller: "calendar_events_api",
                           action: "destroy",
                           format: "json",
                           id: reservation.id.to_s
                         },
                         cancel_reason: "Too busy")

            message = Message.last
            expect(message.notification_name).to eq "Appointment Canceled By User"
            expect(message.to).to eq "test_#{@teacher.id}@example.com"
            expect(message.body).to match(/Too busy/)
          end

          describe "past appointments" do
            before do
              @past_ag = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
              @past_ag.publish!
              @past_slot = @past_ag.appointments.first
            end

            it "does not allow a student to reserve a time slot in the past" do
              json = api_call(:post,
                              "/api/v1/calendar_events/#{@past_slot.id}/reservations",
                              {
                                controller: "calendar_events_api", action: "reserve", format: "json", id: @past_slot.id.to_s
                              },
                              {},
                              {},
                              { expected_status: 403 })
              expect(json["message"]).to eq("Cannot create or change reservation for past appointment")
            end

            it "does not allow a student to delete a past reservation" do
              reservation = @past_slot.reserve_for(@user, @teacher)
              json = api_call(:delete,
                              "/api/v1/calendar_events/#{reservation.id}",
                              {
                                controller: "calendar_events_api", action: "destroy", format: "json", id: reservation.id.to_s
                              },
                              {},
                              {},
                              { expected_status: 403 })
              expect(json["message"]).to eq("Cannot create or change reservation for past appointment")
              expect(reservation.reload).not_to be_deleted
            end

            it "allows a teacher to delete a student's past reservation" do
              reservation = @past_slot.reserve_for(@user, @teacher)
              api_call_as_user(@teacher,
                               :delete,
                               "/api/v1/calendar_events/#{reservation.id}",
                               {
                                 controller: "calendar_events_api", action: "destroy", format: "json", id: reservation.id.to_s
                               },
                               {},
                               {},
                               { expected_status: 200 })
              expect(reservation.reload).to be_deleted
            end
          end
        end

        context "as an admin" do
          before(:once) { prepare }

          it "allows admins to specify the participant" do
            json = api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@other_guy.id}", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s, participant_id: @other_guy.id.to_s
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields)
            expect(json["appointment_group_id"]).to eql(@ag1.id)

            json = api_call(:post, "/api/v1/calendar_events/#{@event3.id}/reservations/#{@group.id}", {
                              controller: "calendar_events_api", action: "reserve", format: "json", id: @event3.id.to_s, participant_id: @group.id.to_s
                            })
            expect(json.keys).to match_array(expected_reservation_event_fields - ["effective_context_code"])
            expect(json["appointment_group_id"]).to eql(@ag2.id)
          end

          it "rejects invalid participants" do
            raw_api_call(:post, "/api/v1/calendar_events/#{@event1.id}/reservations/#{@me.id}", {
                           controller: "calendar_events_api", action: "reserve", format: "json", id: @event1.id.to_s, participant_id: @me.id.to_s
                         })
            errors = JSON.parse(response.body)
            expect(errors.size).to be 1
            error = errors.first
            expect(error.slice("attribute", "type", "message")).to eql({ "attribute" => "reservation", "type" => "calendar_event", "message" => "invalid participant" })
            expect(error["reservations"].size).to be 0
          end
        end
      end

      context "participants" do
        describe "calendar events" do
          before do
            course_with_teacher(active_all: true)
            add_section("test section")
            @parent_event = CalendarEvent.create!(title: "parent event", context: @course, start_at: 1.day.from_now, end_at: 2.days.from_now)
            @child_event = CalendarEvent.create!(title: "child event", context: @course_section, start_at: 1.day.from_now, end_at: 2.days.from_now, parent_event: @parent_event)
            course_with_student(course: @course, active_all: true)
            @student1 = @student
            multiple_student_enrollment(@student1, @course_section)
            course_with_student(course: @course, active_all: true)
            @student2 = @student
            multiple_student_enrollment(@student2, @course_section)
          end

          it "returns a permission error for students accessing participants" do
            api_call_as_user(@student1,
                             :get,
                             "/api/v1/calendar_events/#{@parent_event.id}/participants",
                             { controller: "calendar_events_api", action: "participants", id: @parent_event.id.to_s, format: "json" })
            expect(response).to have_http_status :unauthorized
          end

          it "returns empty participants for a teacher" do
            json = api_call_as_user(@teacher,
                                    :get,
                                    "/api/v1/calendar_events/#{@parent_event.id}/participants",
                                    { controller: "calendar_events_api", action: "participants", id: @parent_event.id.to_s, format: "json" })
            expect(json).to eq []
          end
        end

        describe "appointment groups" do
          before do
            course_with_teacher(active_all: true)
            @ag = AppointmentGroup.create!(title: "something",
                                           participants_per_appointment: 4,
                                           contexts: [@course],
                                           participant_visibility: "protected",
                                           new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"],
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

          it "returns participants in the same appointment group slot for a student" do
            json = api_call_as_user(@student1,
                                    :get,
                                    "/api/v1/calendar_events/#{@event.id}/participants",
                                    { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json" })
            expect(json).to eq [
              {
                "id" => @student1.id,
                "anonymous_id" => @student1.id.to_s(36),
                "display_name" => @student1.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/about/#{@student1.id}",
                "pronouns" => nil
              },
              {
                "id" => @student2.id,
                "anonymous_id" => @student2.id.to_s(36),
                "display_name" => @student2.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/users/#{@student2.id}",
                "pronouns" => nil
              }
            ]
          end

          it "returns participants in the same appointment group slot for a teacher" do
            json = api_call_as_user(@teacher,
                                    :get,
                                    "/api/v1/calendar_events/#{@event.id}/participants",
                                    { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json" })
            expect(json).to eq [
              {
                "id" => @student1.id,
                "anonymous_id" => @student1.id.to_s(36),
                "display_name" => @student1.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/users/#{@student1.id}",
                "pronouns" => nil
              },
              {
                "id" => @student2.id,
                "anonymous_id" => @student2.id.to_s(36),
                "display_name" => @student2.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/users/#{@student2.id}",
                "pronouns" => nil
              }
            ]
          end

          it "paginates participants" do
            @ag.participants_per_appointment = 15
            @ag.save!
            students = create_users_in_course(@course, 10, active_all: true)
            students.each do |student_id|
              student = User.find(student_id)
              @event.reserve_for(student, student)
            end
            json = api_call(:get,
                            "/api/v1/calendar_events/#{@event.id}/participants",
                            { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json" })
            expect(json.length).to eq 10
            json = api_call(:get,
                            "/api/v1/calendar_events/#{@event.id}/participants?page=2",
                            { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json", page: 2 })
            expect(json.length).to eq 2
          end

          it "does not list users participating in other appointment group slots" do
            course_with_student(course: @course, active_all: true)
            event2 = @ag.appointments.last
            event2.reserve_for(@student, @student)
            json = api_call_as_user(@student1,
                                    :get,
                                    "/api/v1/calendar_events/#{@event.id}/participants",
                                    { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json" })
            expect(json).to eq [
              {
                "id" => @student1.id,
                "anonymous_id" => @student1.id.to_s(36),
                "display_name" => @student1.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/about/#{@student1.id}",
                "pronouns" => nil
              },
              {
                "id" => @student2.id,
                "anonymous_id" => @student2.id.to_s(36),
                "display_name" => @student2.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/users/#{@student2.id}",
                "pronouns" => nil
              }
            ]
            json = api_call(:get,
                            "/api/v1/calendar_events/#{event2.id}/participants",
                            { controller: "calendar_events_api", action: "participants", id: event2.id.to_s, format: "json" })
            expect(json).to eq [
              {
                "id" => @student.id,
                "anonymous_id" => @student.id.to_s(36),
                "display_name" => @student.short_name,
                "avatar_image_url" => "http://www.example.com/images/messages/avatar-50.png",
                "html_url" => "http://www.example.com/about/#{@student.id}",
                "pronouns" => nil
              }
            ]
          end

          it "returns 401 if not allowed to view participants" do
            @ag.participant_visibility = "private"
            @ag.save!
            api_call_as_user(@student1,
                             :get,
                             "/api/v1/calendar_events/#{@event.id}/participants",
                             { controller: "calendar_events_api", action: "participants", id: @event.id.to_s, format: "json" })
            expect(response).to have_http_status :unauthorized
          end
        end
      end
    end

    it "gets a single event" do
      event = @course.calendar_events.create(title: "event")
      json = api_call(:get, "/api/v1/calendar_events/#{event.id}", {
                        controller: "calendar_events_api", action: "show", id: event.id.to_s, format: "json"
                      })
      expect(json.keys).to match_array expected_fields
      expect(json.slice("title", "id")).to eql({ "id" => event.id, "title" => "event" })
    end

    it "enforces permissions" do
      event = course_factory.calendar_events.create(title: "event")
      raw_api_call(:get, "/api/v1/calendar_events/#{event.id}", {
                     controller: "calendar_events_api", action: "show", id: event.id.to_s, format: "json"
                   })
      expect(JSON.parse(response.body)["status"]).to eq "unauthorized"
    end

    it "creates a new event" do
      json = api_call(:post,
                      "/api/v1/calendar_events",
                      { controller: "calendar_events_api", action: "create", format: "json" },
                      { calendar_event: { context_code: @course.asset_string, title: "ohai" } })
      assert_status(201)
      expect(json.keys).to match_array expected_fields
      expect(json["title"]).to eql "ohai"
    end

    context "account calendars" do
      it "does not allow view-only users to create account calendar events" do
        @user = account_admin_user_with_role_changes(account: Account.default, role_changes: { manage_account_calendar_visibility: true, manage_account_calendar_events: false })
        api_call(:post,
                 "/api/v1/calendar_events",
                 { controller: "calendar_events_api", action: "create", format: "json" },
                 { calendar_event: { context_code: "account_#{Account.default.id}", title: "API Test" } },
                 {},
                 { expected_status: 401 })
      end
    end

    it "creates recurring events if options have been specified" do
      start_at = Time.zone.now.utc.change(hour: 0, min: 1) # For pre-Normandy bug with all_day method in calendar_event.rb
      end_at = Time.zone.now.utc.change(hour: 23)
      json = api_call(:post,
                      "/api/v1/calendar_events",
                      { controller: "calendar_events_api", action: "create", format: "json" },
                      { calendar_event: {
                        context_code: @course.asset_string,
                        title: "ohai",
                        start_at: start_at.iso8601,
                        end_at: end_at.iso8601,
                        duplicate: {
                          count: "3",
                          interval: "1",
                          frequency: "weekly"
                        }
                      } })
      assert_status(201)
      expect(json.keys).to match_array expected_fields
      expect(json["title"]).to eq "ohai"

      duplicates = json["duplicates"]
      expect(duplicates.count).to eq 3

      duplicates.to_a.each_with_index do |duplicate, i|
        start_result = Time.iso8601(duplicate["calendar_event"]["start_at"])
        end_result = Time.iso8601(duplicate["calendar_event"]["end_at"])
        expect(duplicate["calendar_event"]["title"]).to eql "ohai"
        expect(start_result).to eq(start_at + (i + 1).weeks)
        expect(end_result).to eq(end_at + (i + 1).weeks)
      end
    end

    it "respects recurring event limit" do
      start_at = Time.zone.now.utc.change(hour: 0, min: 1)
      end_at = Time.zone.now.utc.change(hour: 23)
      api_call(:post,
               "/api/v1/calendar_events",
               { controller: "calendar_events_api", action: "create", format: "json" },
               { calendar_event: {
                 context_code: @course.asset_string,
                 title: "ohai",
                 start_at: start_at.iso8601,
                 end_at: end_at.iso8601,
                 duplicate: {
                   count: "201",
                   interval: "1",
                   frequency: "weekly"
                 }
               } })
      assert_status(400)
    end

    it "doesn't die on unreasonable recurring event counts" do
      start_at = Time.zone.now.utc.change(hour: 0, min: 1)
      end_at = Time.zone.now.utc.change(hour: 23)
      api_call(
        :post,
        "/api/v1/calendar_events",
        { controller: "calendar_events_api", action: "create", format: "json" },
        {
          calendar_event: {
            context_code: @course.asset_string,
            title: "ohai",
            start_at: start_at.iso8601,
            end_at: end_at.iso8601,
            duplicate: {
              count: "1_000_000",
              interval: "1",
              frequency: "weekly"
            }
          }
        }
      )
      assert_status(400)
    end

    it "processes html content in description on create" do
      should_process_incoming_user_content(@course) do |content|
        json = api_call(:post,
                        "/api/v1/calendar_events",
                        { controller: "calendar_events_api", action: "create", format: "json" },
                        { calendar_event: { context_code: @course.asset_string, title: "ohai", description: content } })

        event = CalendarEvent.find(json["id"])
        event.description
      end
    end

    describe "statsd metrics" do
      it "emits calendar.calendar_event.create with single tag when creating a new event" do
        course_with_student(course: @course, user: @user, active_all: true)
        allow(InstStatsd::Statsd).to receive(:increment)
        api_call(:post,
                 "/api/v1/calendar_events",
                 { controller: "calendar_events_api", action: "create", format: "json" },
                 { calendar_event: { context_code: @course.asset_string, title: "single event" } })
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("calendar.calendar_event.create", tags: %w[enrollment_type:TeacherEnrollment enrollment_type:StudentEnrollment calendar_event_type:single])
      end

      it "emits calendar.calendar_event.create with recurring tag when creating a new recurring event" do
        start_at = Time.zone.now.utc.change(hour: 0, min: 1)
        end_at = Time.zone.now.utc.change(hour: 23)
        allow(InstStatsd::Statsd).to receive(:increment)
        api_call(:post,
                 "/api/v1/calendar_events",
                 { controller: "calendar_events_api", action: "create", format: "json" },
                 { calendar_event: { context_code: @course.asset_string,
                                     title: "recurring event",
                                     start_at: start_at.iso8601,
                                     end_at: end_at.iso8601,
                                     duplicate: {
                                       count: "3",
                                       interval: "1",
                                       frequency: "weekly"
                                     } } })
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("calendar.calendar_event.create", tags: %w[enrollment_type:TeacherEnrollment calendar_event_type:recurring])
      end

      it "emits calendar.calendar_event.create with series tag when creating a new event series" do
        start_at = Time.zone.now.utc.change(hour: 0, min: 1)
        end_at = Time.zone.now.utc.change(hour: 23)
        allow(InstStatsd::Statsd).to receive(:increment)
        api_call(:post,
                 "/api/v1/calendar_events",
                 { controller: "calendar_events_api", action: "create", format: "json" },
                 { calendar_event: { context_code: @course.asset_string,
                                     title: "series",
                                     start_at: start_at.iso8601,
                                     end_at: end_at.iso8601,
                                     rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=3" } })
        expect(InstStatsd::Statsd).to have_received(:increment).once.with("calendar.calendar_event.create", tags: %w[enrollment_type:TeacherEnrollment calendar_event_type:series])
      end
    end

    it "updates an event" do
      event = @course.calendar_events.create(title: "event", start_at: "2012-01-08 12:00:00")

      json = api_call(:put,
                      "/api/v1/calendar_events/#{event.id}",
                      { controller: "calendar_events_api", action: "update", id: event.id.to_s, format: "json" },
                      { calendar_event: { start_at: "2012-01-09 12:00:00", title: "ohai" } })
      expect(json.keys).to match_array expected_fields
      expect(json["title"]).to eql "ohai"
      expect(json["start_at"]).to eql "2012-01-09T12:00:00Z"
    end

    it "does not update event if all_day, start_at, and end_at are provided in a request" do
      event = @course.calendar_events.create(title: "event", start_at: "2012-01-08 12:00:00")

      json = api_call(:put,
                      "/api/v1/calendar_events/#{event.id}",
                      { controller: "calendar_events_api", action: "update", id: event.id.to_s, format: "json" },
                      { calendar_event: { start_at: "2012-01-08 12:00:00", end_at: "2012-01-09 12:00:00", all_day: true, title: "ohai" } })
      expect(json["all_day"]).to be true
      expect(json["end_at"]).to eql "2012-01-09T00:00:00Z"
    end

    it "processes html content in description on update" do
      event = @course.calendar_events.create(title: "event", start_at: "2012-01-08 12:00:00")

      should_process_incoming_user_content(@course) do |content|
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 { controller: "calendar_events_api", action: "update", id: event.id.to_s, format: "json" },
                 { calendar_event: { start_at: "2012-01-09 12:00:00", description: content } })

        event.reload
        event.description
      end
    end

    context "event series" do
      describe "create" do
        it "creates an event series if an rrule has been specified" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          json = api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "many me",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=3"
              }
            }
          )
          assert_status(201)
          expect(json.keys).to match_array expected_series_fields
          expect(json["title"]).to eq "many me"
          expect(json["series_uuid"]).not_to be_nil

          duplicates = json["duplicates"]
          expect(duplicates.count).to eq 2

          duplicates.to_a.each_with_index do |duplicate, i|
            start_result = Time.iso8601(duplicate["calendar_event"]["start_at"])
            end_result = Time.iso8601(duplicate["calendar_event"]["end_at"])
            expect(duplicate["calendar_event"]["title"]).to eql "many me"
            expect(start_result).to eq(start_at + (i + 1).weeks)
            expect(end_result).to eq(end_at + (i + 1).weeks)
          end
        end

        it "fails if RRULE's COUNT creates too many events" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "ohai",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=401"
              }
            }
          )
          assert_status(400)
        end

        it "fails if RRULE's UNTIL date creates too many events" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          series_end = start_at + 2.years
          api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "ohai",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=DAILY;INTERVAL=1;UNTIL=#{series_end.iso8601}"
              }
            }
          )
          assert_status(400)
        end

        it "doesn't die on unreasonable recurring event counts" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "ohai",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=1000000"
              }
            }
          )
          assert_status(400)
        end

        it "requires the series to have an end" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "ohai",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;" # <<< no COUNT or UNTIL
              }
            }
          )
          assert_status(400)
        end

        it "copes with a leading 'RRULE:' in the rrule" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "ohai",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "RRULE:FREQ=WEEKLY;INTERVAL=1;COUNT=2"
              }
            }
          )
          assert_status(201)
        end
      end

      describe "destroy" do
        before do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          @event_series = api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "many me",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=3"
              }
            }
          )
        end

        it "deletes one event of a series" do
          target_event_id = @event_series["id"]
          series_count = @event_series["duplicates"].length + 1
          series_uuid = @event_series["series_uuid"]

          json = api_call(:delete,
                          "/api/v1/calendar_events/#{target_event_id}?which=one",
                          { controller: "calendar_events_api", action: "destroy", id: target_event_id.to_s, which: "one", format: "json" })
          assert_status(200)
          expect(json.length).to eq 1
          expect(json[0].keys).to match_array expected_series_fields
          expect(json[0]["id"]).to be target_event_id

          remaining_events = CalendarEvent.where(series_uuid:, workflow_state: "active")
          expect(remaining_events.length).to eql series_count - 1
        end

        it "deletes an event and all following" do
          target_event_id = @event_series["duplicates"][0]["calendar_event"]["id"] # middle event in the series
          series_count = @event_series["duplicates"].length + 1
          series_uuid = @event_series["series_uuid"]

          json = api_call(:delete,
                          "/api/v1/calendar_events/#{target_event_id}?which=following",
                          { controller: "calendar_events_api", action: "destroy", id: target_event_id.to_s, which: "following", format: "json" })
          assert_status(200)

          expect(json.length).to eq 3
          updated_events = json.select { |e| e["workflow_state"] == "active" }
          deleted_events = json.select { |e| e["workflow_state"] == "deleted" }
          expect(updated_events.length).to eq 1
          expect(deleted_events.length).to eq 2
          expect(json[0].keys).to match_array expected_series_fields
          expect(deleted_events[0]["id"]).to be target_event_id
          expect(json[1]["id"]).to be @event_series["duplicates"][1]["calendar_event"]["id"]

          remaining_events = CalendarEvent.where(series_uuid:, workflow_state: "active")
          expect(remaining_events.length).to eql series_count - 2
          expect(remaining_events[0].rrule).to eql "FREQ=WEEKLY;INTERVAL=1;COUNT=1"
        end

        it "deletes all in the series" do
          target_event_id = @event_series["duplicates"][0]["calendar_event"]["id"] # middle event in the series
          series_uuid = @event_series["series_uuid"]

          json = api_call(:delete,
                          "/api/v1/calendar_events/#{target_event_id}?which=all",
                          { controller: "calendar_events_api", action: "destroy", id: target_event_id.to_s, which: "all", format: "json" })
          assert_status(200)
          expect(json.length).to eq 3

          remaining_events = CalendarEvent.where(series_uuid:, workflow_state: "active")
          expect(remaining_events.length).to be 0
        end

        it "returns an error for invalid 'which' parameter" do
          target_event_id = @event_series["id"]

          json = api_call(:delete,
                          "/api/v1/calendar_events/#{target_event_id}?which=bogus",
                          { controller: "calendar_events_api", action: "destroy", id: target_event_id.to_s, which: "bogus", format: "json" })
          assert_status(400)
          expect(json.length).to eq 1
          expect(json["error"]).to eql "Invalid parameter which='bogus'"
        end
      end

      describe "update" do
        before do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          @event_series = api_call(
            :post,
            "/api/v1/calendar_events",
            { controller: "calendar_events_api", action: "create", format: "json" },
            {
              calendar_event: {
                context_code: @course.asset_string,
                title: "many me",
                start_at: start_at.iso8601,
                end_at: end_at.iso8601,
                rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=3"
              }
            }
          )
        end

        it "updates one event from the series" do
          target_event = @event_series["duplicates"][0]["calendar_event"]
          target_event_id = target_event["id"]
          new_start_at = (Time.parse(target_event["start_at"]) + 15.minutes).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, title: "this is different" } })
          expect(json.keys).to match_array expected_series_fields
          expect(json["title"]).to eql "this is different"
          expect(json["start_at"]).to eql new_start_at
        end

        it "updates one event from the series and change it to a single event" do
          target_event = @event_series["duplicates"][1]["calendar_event"]
          target_event_id = target_event["id"]
          new_start_at = (Time.parse(target_event["start_at"]) + 15.minutes).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, title: "this is different", rrule: nil } })
          assert_status(200)
          expect(json.length).to be 1
          json.each do |event|
            expect(event.keys).to match_array expected_fields
            expect(event["id"]).to eql target_event_id
            expect(event["title"]).to eql "this is different"
            expect(event["start_at"]).to eql new_start_at
          end
        end

        it "updates all events in the series with the second event in the event list" do
          orig_events = [@event_series.except("duplicates")]
          orig_events += @event_series["duplicates"].pluck("calendar_event")
          target_event = @event_series["duplicates"][0]["calendar_event"]
          target_event_id = target_event["id"]
          new_title = "a new title"
          new_start_at = (Time.parse(target_event["start_at"]) + 15.minutes).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, title: new_title }, which: "all" })
          assert_status(200)
          expect(json.length).to be 3
          json.each_with_index do |event, i|
            expect(event.keys).to match_array expected_series_fields
            expect(event["id"]).to eql orig_events[i]["id"]
            expect(event["title"]).to eql new_title
            expect(event["start_at"]).to eql (Time.parse(orig_events[i]["start_at"]) + 15.minutes).iso8601
          end
        end

        it "updates an event and all following" do
          orig_events = [@event_series.except("duplicates")]
          orig_events += @event_series["duplicates"].pluck("calendar_event")
          target_event = @event_series["duplicates"][0]["calendar_event"]
          target_event_id = target_event["id"]
          series_uuid = target_event["series_uuid"]
          new_title = "a new title"
          new_start_at = (Time.parse(target_event["start_at"]) + 15.minutes).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, title: new_title }, which: "following" })
          assert_status(200)
          expect(json.length).to be 3
          json.each_with_index do |event, i|
            expect(event.keys).to match_array expected_series_fields
            expect(event["id"]).to eql orig_events[i]["id"]
            if i == 0
              expect(event["title"]).to eql orig_events[i]["title"]
              expect(event["start_at"]).to eql orig_events[i]["start_at"]
              # we changed start_at, so the changed events belong to a new series
              expect(event["series_uuid"]).to eql series_uuid
            else
              expect(event["title"]).to eql new_title
              expect(event["start_at"]).to eql (Time.parse(orig_events[i]["start_at"]) + 15.minutes).iso8601
              # we changed start_at, so the changed events belong to a new series
              expect(event["series_uuid"]).not_to eql series_uuid
            end
          end
          orig_series = CalendarEvent.where(series_uuid:)
          expect(orig_series.length).to be 1
          expect(orig_series[0].rrule).to eq "FREQ=WEEKLY;INTERVAL=1;COUNT=1"
        end

        it "returns an error when which='one' and the rrule changed" do
          target_event_id = @event_series["duplicates"][0]["calendar_event"]["id"].to_s
          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id, format: "json" },
                          { calendar_event: { title: "new title", rrule: "FREQ=WEEKLY;INTERVAL=1;COUNT=4" }, which: "one" })
          assert_status(400)
          expect(json["message"]).to eql "You may not update one event with a new schedule."
        end

        it "returns an error when which='all' the event is not the head event and the start date changes" do
          target_event = @event_series["duplicates"][0]["calendar_event"]
          target_event_id = target_event["id"].to_s
          new_start_at = (Time.parse(target_event["start_at"]) + 1.day).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id, format: "json" },
                          { calendar_event: { title: "new title", start_at: new_start_at }, which: "all" })
          assert_status(400)
          expect(json["message"]).to eql "You may not change the start date when changing all events in the series"
        end

        it "updates all series events when date changes and head event used" do
          orig_events = [@event_series.except("duplicates")]
          orig_events += @event_series["duplicates"].pluck("calendar_event")
          target_event = orig_events[0]
          target_event_id = target_event["id"].to_s
          new_start_at = (Time.parse(target_event["start_at"]) + 1.day).iso8601
          series_uuid = target_event["series_uuid"]
          new_title = "a new title"

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id, format: "json" },
                          { calendar_event: { title: new_title, start_at: new_start_at }, which: "all" })
          assert_status(200)
          expect(json.length).to be 3
          json.each_with_index do |event, i|
            expect(event["id"]).to eql orig_events[i]["id"]
            expect(event["title"]).to eql new_title
            expect(event["start_at"]).to eql (Time.parse(orig_events[i]["start_at"]) + 1.day).iso8601
            expect(event["series_uuid"]).to eql series_uuid
          end
        end

        it "extends the series when updating the rrule" do
          orig_events = [@event_series.except("duplicates")]
          orig_events += @event_series["duplicates"].pluck("calendar_event")
          target_event = @event_series["duplicates"][0]["calendar_event"]
          target_event_id = target_event["id"]
          rrule = "FREQ=DAILY;INTERVAL=1;COUNT=4"
          new_title = "a new title"

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { title: new_title, rrule: }, which: "following" })
          assert_status(200)
          expect(json.length).to be 5

          first_event = json.shift # we didn't update the first event in the series
          expect(first_event["title"]).to eql "many me"
          expect(first_event["rrule"]).to eql "FREQ=WEEKLY;INTERVAL=1;COUNT=1"

          orig_events.shift
          orig_events.each_with_index do |event, i|
            expect(json[i].keys).to match_array expected_series_fields
            expect(json[i]["id"]).to eql event["id"]
            expect(json[i]["title"]).to eql new_title
            expect(json[i]["rrule"]).to eql "FREQ=DAILY;INTERVAL=1;COUNT=4"
            # we changed start_at, so the changed events belong to a new series
            expect(json[0]["series_uuid"]).not_to eql event["series_uuid"]
          end
          # the new event
          expect(json[2]["title"]).to eql new_title
          expect(CalendarEvent.where(series_uuid: orig_events[0]["series_uuid"]).length).to be 1
          expect(CalendarEvent.where(series_uuid: json[0]["series_uuid"]).length).to be 4
          expect(CalendarEvent.where(series_head: true, id: json[0]["id"]).length).to be 1
        end

        it "truncates the series when updating the rrule" do
          orig_events = [@event_series.except("duplicates")]
          orig_events += @event_series["duplicates"].pluck("calendar_event")
          target_event = orig_events[0]
          target_event_id = target_event["id"]
          rrule = "FREQ=WEEKLY;INTERVAL=1;COUNT=2"
          new_title = "a new title"
          new_start_at = (Time.parse(target_event["start_at"]) + 15.minutes).iso8601

          json = api_call(:put,
                          "/api/v1/calendar_events/#{target_event_id}",
                          { controller: "calendar_events_api", action: "update", id: target_event_id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, title: new_title, rrule: }, which: "all" })
          assert_status(200)
          expect(json.length).to be 2
          json.each_with_index do |event, i|
            expect(json[i].keys).to match_array expected_series_fields
            expect(json[i]["id"]).to eql orig_events[i]["id"]
            expect(json[i]["title"]).to eql new_title
            expect(json[i]["start_at"]).to eql (Time.parse(orig_events[i]["start_at"]) + 15.minutes).iso8601
            expect(json[0]["series_uuid"]).to eql event["series_uuid"]
          end
        end

        it "creates series events from single event without changing datetime" do
          start_at = Time.zone.now.utc.change(hour: 0, min: 1)
          end_at = Time.zone.now.utc.change(hour: 23)
          single_event = @user.calendar_events.create!(title: "event", start_at: start_at.iso8601, end_at: end_at.iso8601)
          rrule = "FREQ=WEEKLY;INTERVAL=1;COUNT=2"
          new_title = "series events title"

          json = api_call(:put,
                          "/api/v1/calendar_events/#{single_event.id}",
                          { controller: "calendar_events_api", action: "update", id: single_event.id.to_s, format: "json" },
                          { calendar_event: { title: new_title, rrule: } })
          assert_status(200)
          expect(json.length).to be 2
          json.each_with_index do |series_event, i|
            expect(json[i]["title"]).to eql new_title
            expect(Time.parse(json[i]["start_at"])).to eql(Time.parse((single_event["start_at"] + i.weeks).iso8601))
            expect(json[0]["series_uuid"]).to eql series_event["series_uuid"]
          end
        end

        it "creates series events from single event including changing time" do
          single_event = @user.calendar_events.create!(title: "event", start_at: "2023-06-29 09:00:00", end_at: "2023-06-29 10:00:00")
          rrule = "FREQ=WEEKLY;INTERVAL=1;COUNT=2"
          new_start_at = Time.parse(single_event["start_at"].iso8601) + 15.minutes
          new_end_at = (Time.parse(single_event["end_at"].iso8601) + 15.minutes)

          json = api_call(:put,
                          "/api/v1/calendar_events/#{single_event.id}",
                          { controller: "calendar_events_api", action: "update", id: single_event.id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, end_at: new_end_at, rrule: } })
          assert_status(200)
          expect(json.length).to be 2
          json.each_with_index do |_event, i|
            expect(Time.parse(json[i]["start_at"])).to eql(new_start_at + i.weeks)
            expect(Time.parse(json[i]["end_at"])).to eql(new_end_at + i.weeks)
          end
        end

        it "creates series events from single event including changing date and time" do
          single_event = @user.calendar_events.create!(title: "event", start_at: "2023-06-29 09:00:00", end_at: "2023-06-29 10:00:00")
          rrule = "FREQ=WEEKLY;INTERVAL=1;COUNT=2"
          new_start_at = Time.parse(single_event["start_at"].iso8601) + 1.day + 15.minutes
          new_end_at = Time.parse(single_event["end_at"].iso8601) + 1.day + 15.minutes

          json = api_call(:put,
                          "/api/v1/calendar_events/#{single_event.id}",
                          { controller: "calendar_events_api", action: "update", id: single_event.id.to_s, format: "json" },
                          { calendar_event: { start_at: new_start_at, end_at: new_end_at, rrule: } })
          assert_status(200)
          expect(json.length).to be 2
          json.each_with_index do |_event, i|
            expect(Time.parse(json[i]["start_at"])).to eql(new_start_at + i.weeks)
            expect(Time.parse(json[i]["end_at"])).to eql(new_end_at + i.weeks)
          end
        end
      end
    end

    describe "moving events between calendars" do
      it "moves an event from a user to a course" do
        event = @user.calendar_events.create!(title: "event", start_at: "2012-01-08 12:00:00")
        json = api_call(:put,
                        "/api/v1/calendar_events/#{event.id}",
                        { controller: "calendar_events_api", action: "update", id: event.to_param, format: "json" },
                        { calendar_event: { context_code: @course.asset_string } })
        expect(json["context_code"]).to eq @course.asset_string
        expect(event.reload.context).to eq @course
      end

      it "moves an event from a course to a user" do
        event = @course.calendar_events.create!(title: "event", start_at: "2012-01-08 12:00:00")
        json = api_call(:put,
                        "/api/v1/calendar_events/#{event.id}",
                        { controller: "calendar_events_api", action: "update", id: event.to_param, format: "json" },
                        { calendar_event: { context_code: @user.asset_string } })
        expect(json["context_code"]).to eq @user.asset_string
        expect(event.reload.context).to eq @user
      end

      context "section-specific times" do
        before :once do
          @event = @course.calendar_events.build(title: "test", child_event_data: [{ start_at: "2012-01-01", end_at: "2012-01-02", context_code: @course.default_section.asset_string }])
          @event.updating_user = @user
          @event.save!
        end

        it "refuses to move a parent event" do
          json = api_call(:put,
                          "/api/v1/calendar_events/#{@event.id}",
                          { controller: "calendar_events_api", action: "update", id: @event.to_param, format: "json" },
                          { calendar_event: { context_code: @user.asset_string } },
                          {},
                          { expected_status: 400 })
          expect(json["message"]).to include "Cannot move events with section-specific times"
        end

        it "refuses to move a child event" do
          child_event = @event.child_events.first
          expect(child_event).to be_present
          json = api_call(:put,
                          "/api/v1/calendar_events/#{child_event.id}",
                          { controller: "calendar_events_api", action: "update", id: child_event.to_param, format: "json" },
                          { calendar_event: { context_code: @user.asset_string } },
                          {},
                          { expected_status: 400 })
          expect(json["message"]).to include "Cannot move events with section-specific times"
        end

        it "doesn't complain if you 'move' the event into the calendar it's already in" do
          api_call(:put,
                   "/api/v1/calendar_events/#{@event.id}",
                   { controller: "calendar_events_api", action: "update", id: @event.to_param, format: "json" },
                   { calendar_event: { context_code: @course.asset_string } })
          expect(response).to be_successful
        end
      end

      it "refuses to move a Scheduler appointment" do
        ag = AppointmentGroup.create!(title: "something", participants_per_appointment: 4, new_appointments: [["2012-01-01 12:00:00", "2012-01-01 13:00:00"]], contexts: [@course])
        ag.publish!
        appointment = ag.appointments.first
        json = api_call(:put,
                        "/api/v1/calendar_events/#{appointment.id}",
                        { controller: "calendar_events_api", action: "update", id: appointment.to_param, format: "json" },
                        { calendar_event: { context_code: @user.asset_string } },
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to include "Cannot move Scheduler appointments"
      end

      it "verifies the caller has permission to create the event in the destination context" do
        other_course = Course.create!
        event = @course.calendar_events.create!(title: "event", start_at: "2012-01-08 12:00:00")
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 { controller: "calendar_events_api", action: "update", id: event.to_param, format: "json" },
                 { calendar_event: { context_code: other_course.asset_string } },
                 {},
                 { expected_status: 401 })
      end
    end

    it "deletes an event" do
      event = @course.calendar_events.create(title: "event", start_at: "2012-01-08 12:00:00")
      json = api_call(:delete,
                      "/api/v1/calendar_events/#{event.id}",
                      { controller: "calendar_events_api", action: "destroy", id: event.id.to_s, format: "json" })
      expect(json.keys).to match_array expected_fields
      expect(event.reload).to be_deleted
    end

    it "deletes the appointment group if it has no appointments" do
      time = Time.utc(Time.now.year, Time.now.month, Time.now.day, 4, 20)
      @appointment_group = AppointmentGroup.create!(
        title: "appointment group",
        participants_per_appointment: 4,
        new_appointments: [
          [time + 3.days, time + 3.days + 1.hour]
        ],
        contexts: [@course]
      )

      api_call(:delete,
               "/api/v1/calendar_events/#{@appointment_group.appointments.first.id}",
               { controller: "calendar_events_api", action: "destroy", id: @appointment_group.appointments.first.id.to_s, format: "json" })
      expect(@appointment_group.reload).to be_deleted
    end

    it "apis translate event descriptions" do
      should_translate_user_content(@course) do |content|
        event = @course.calendar_events.create!(title: "event", start_at: "2012-01-08 12:00:00", description: content)
        json = api_call(:get,
                        "/api/v1/calendar_events/#{event.id}",
                        controller: "calendar_events_api",
                        action: "show",
                        format: "json",
                        id: event.id.to_s)
        json["description"]
      end
    end

    it "apis translate event descriptions in ics" do
      allow(HostUrl).to receive(:default_host).and_return("www.example.com")
      should_translate_user_content(@course, false) do |content|
        @course.calendar_events.create!(description: content, start_at: Time.now + 1.hour, end_at: Time.now + 2.hours)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}",
                        controller: "courses",
                        action: "show",
                        format: "json",
                        id: @course.id.to_s)
        get json["calendar"]["ics"]
        expect(response).to be_successful
        cal = Icalendar::Calendar.parse(response.body.dup)[0]
        cal.events[0].x_alt_desc.first
      end
    end

    it "omits assignment description in ics feed for a course" do
      allow(HostUrl).to receive(:default_host).and_return("www.example.com")
      assignment_model(description: "secret stuff here")
      get "/feeds/calendars/#{@course.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar::Calendar.parse(response.body.dup)[0]
      expect(cal.events[0].description).to be_nil
      expect(cal.events[0].x_alt_desc).to be_blank
    end

    it "works when event descriptions contain paths to user attachments" do
      attachment_with_context(@user)
      @user.calendar_events.create!(description: "/users/#{@user.id}/files/#{@attachment.id}", start_at: Time.now)
      api_call(:get, "/api/v1/calendar_events", {
                 controller: "calendar_events_api", action: "index", format: "json"
               })
      expect(response).to be_successful
    end

    context "child_events" do
      let_once :event do
        event = @course.calendar_events.build(title: "event", child_event_data: { "0" => { start_at: "2012-01-01 12:00:00", end_at: "2012-01-01 13:00:00", context_code: @course.default_section.asset_string } })
        event.updating_user = @user
        event.save!
        event
      end

      it "lists child events by default" do
        json = api_call(:get, "/api/v1/calendar_events?context_codes[]=course_#{@course.id}&start_date=2011-12-31&end_date=2012-01-02", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: Date.parse("2011-12-31"),
                          end_date: Date.parse("2012-01-02")
                        })
        expect(json[0]["child_events"].length).to be 1
      end

      it "excludes child events when asked to" do
        json = api_call(:get, "/api/v1/calendar_events?context_codes[]=course_#{@course.id}&start_date=2011-12-31&end_date=2012-01-02&excludes[]=child_events", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          start_date: Date.parse("2011-12-31"),
                          end_date: Date.parse("2012-01-02"),
                          excludes: ["child_events"]
                        })
        expect(json[0]["child_events"]).to be_nil
      end

      it "creates an event with child events" do
        json = api_call(:post,
                        "/api/v1/calendar_events",
                        { controller: "calendar_events_api", action: "create", format: "json" },
                        { calendar_event: { context_code: @course.asset_string, title: "ohai", child_event_data: { "0" => { start_at: "2012-01-01 12:00:00", end_at: "2012-01-01 13:00:00", context_code: @course.default_section.asset_string } } } })
        assert_status(201)
        expect(json.keys).to match_array expected_fields
        expect(json["title"]).to eql "ohai"
        expect(json["child_events"].size).to be 1
        expect(json["start_at"]).to eql "2012-01-01T12:00:00Z" # inferred from child event
        expect(json["end_at"]).to eql "2012-01-01T13:00:00Z"
        expect(json["hidden"]).to be_truthy
      end

      it "updates an event with child events" do
        json = api_call(:put,
                        "/api/v1/calendar_events/#{event.id}",
                        { controller: "calendar_events_api", action: "update", id: event.id.to_s, format: "json" },
                        { calendar_event: { title: "ohai", child_event_data: { "0" => { start_at: "2012-01-01 13:00:00", end_at: "2012-01-01 14:00:00", context_code: @course.default_section.asset_string } } } })
        expect(json.keys).to match_array expected_fields
        expect(json["title"]).to eql "ohai"
        expect(json["child_events"].size).to be 1
        expect(json["start_at"]).to eql "2012-01-01T13:00:00Z"
        expect(json["end_at"]).to eql "2012-01-01T14:00:00Z"
        expect(json["hidden"]).to be_truthy
      end

      it "removes all child events" do
        json = api_call(:put,
                        "/api/v1/calendar_events/#{event.id}",
                        { controller: "calendar_events_api", action: "update", id: event.id.to_s, format: "json" },
                        { calendar_event: { title: "ohai", remove_child_events: "1" } })
        expect(json.keys).to match_array expected_fields
        expect(json["title"]).to eql "ohai"
        expect(json["child_events"]).to be_empty
        expect(json["start_at"]).to eq "2012-01-01T12:00:00Z"
        expect(json["end_at"]).to eq "2012-01-01T13:00:00Z"
        expect(json["hidden"]).to be_falsey
      end

      it "adds the section name to a child event's title" do
        child_event_id = event.child_event_ids.first
        json = api_call(:get,
                        "/api/v1/calendar_events/#{child_event_id}",
                        { controller: "calendar_events_api", action: "show", id: child_event_id.to_s, format: "json" })
        expect(json.keys).to match_array((expected_fields + ["effective_context_code"]))
        expect(json["title"]).to eql "event (#{@course.default_section.name})"
        expect(json["hidden"]).to be_falsey
      end

      describe "visibility" do
        before(:once) do
          student_in_course(course: @course, active_all: true)
        end

        it "includes children of hidden events for teachers" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/calendar_events/#{event.id}",
                                  { controller: "calendar_events_api", action: "show", id: event.to_param, format: "json" })
          expect(json["child_events"].pluck("id")).to match_array(event.child_events.map(&:id))
        end

        it "omits children of hidden events for students" do
          json = api_call_as_user(@student,
                                  :get,
                                  "/api/v1/calendar_events/#{event.id}",
                                  { controller: "calendar_events_api", action: "show", id: event.to_param, format: "json" })
          expect(json["child_events"]).to be_empty
        end
      end

      it "allows media comments in the event description" do
        event.description = '<a href="/media_objects/abcde" class="instructure_inline_media_comment audio_comment" id="media_comment_abcde"><img></a>'
        event.save!
        child_event_id = event.child_event_ids.first
        api_call(:get,
                 "/api/v1/calendar_events/#{child_event_id}",
                 { controller: "calendar_events_api", action: "show", id: child_event_id.to_s, format: "json" })
        expect(response).to be_successful
      end
    end

    context "web_conferences" do
      before(:once) do
        plugin = PluginSetting.create!(name: "big_blue_button")
        plugin.update_attribute(:settings, { key: "value" })
      end

      let_once(:conference) { WebConference.create(context: @course, user: @user, conference_type: "BigBlueButton") }
      let_once(:event_with_conference) do
        @course.calendar_events.create(title: "event with conference",
                                       workflow_state: "active",
                                       web_conference: conference)
      end

      context "notifications" do
        before do
          Notification.create!(name: "Web Conference Invitation",
                               category: "TestImmediately")
          course_with_teacher(active_all: true, user: user_with_communication_channel(active_all: true))
        end

        it "sends only one conference invite notification for created web conference" do
          api_call(:post,
                   "/api/v1/calendar_events.json",
                   {
                     controller: "calendar_events_api", action: "create", format: "json"
                   },
                   {
                     calendar_event: {
                       context_code: "course_#{@course.id}",
                       title: "API Test",
                       web_conference: { conference_type: "BigBlueButton", title: "BBB Conference" }
                     }
                   })

          expect(Message.count).to eq 1
          expect(Message.last.user_id).to eq @user.id
          expect(Message.last.notification_name).to eq "Web Conference Invitation"
        end

        it "only creates stream items but not notifications when suppress_notifications is true" do
          initial_stream_item_count = StreamItem.count
          account = Account.default
          account.settings[:suppress_notifications] = true
          account.save!

          api_call(:post,
                   "/api/v1/calendar_events.json",
                   {
                     controller: "calendar_events_api", action: "create", format: "json"
                   },
                   {
                     calendar_event: {
                       context_code: "course_#{@course.id}",
                       title: "API Test",
                       web_conference: { conference_type: "BigBlueButton", title: "BBB Conference" }
                     }
                   })
          expect(Message.count).to eq 0
          expect(StreamItem.count).to eq(initial_stream_item_count + 1)
        end
      end

      it "does not show web conferences by default" do
        json = api_call(:get, "/api/v1/calendar_events/#{event_with_conference.id}", {
                          controller: "calendar_events_api", action: "show", format: "json", id: event_with_conference.id
                        })
        expect(json).not_to have_key "web_conference"
      end

      it "shows web conferences when include specified" do
        json = api_call(:get, "/api/v1/calendar_events/#{event_with_conference.id}?include[]=web_conference", {
                          controller: "calendar_events_api",
                          action: "show",
                          format: "json",
                          id: event_with_conference.id,
                          include: ["web_conference"]
                        })
        expect(json).to have_key "web_conference"
        expect(json["web_conference"]["id"]).to eq conference.id
      end

      it "creates with existing web_conference" do
        json = api_call(:post,
                        "/api/v1/calendar_events.json",
                        {
                          controller: "calendar_events_api", action: "create", format: "json"
                        },
                        {
                          calendar_event: {
                            context_code: "course_#{@course.id}",
                            title: "API Test",
                            web_conference: { id: conference.id }
                          }
                        })
        expect(CalendarEvent.find(json["id"]).web_conference_id).to eq conference.id
      end

      it "creates with new web_conference" do
        json = api_call(:post,
                        "/api/v1/calendar_events.json",
                        {
                          controller: "calendar_events_api", action: "create", format: "json"
                        },
                        {
                          calendar_event: {
                            context_code: "course_#{@course.id}",
                            title: "API Test",
                            web_conference: { conference_type: "BigBlueButton", title: "BBB Conference" }
                          }
                        })
        expect(CalendarEvent.find(json["id"]).web_conference).to have_attributes(conference_type: "BigBlueButton", title: "API Test")
      end

      it "sets defaults for new web_conference" do
        json = api_call(:post,
                        "/api/v1/calendar_events.json",
                        {
                          controller: "calendar_events_api", action: "create", format: "json"
                        },
                        {
                          calendar_event: {
                            context_code: "course_#{@course.id}",
                            title: "API Test",
                            web_conference: { conference_type: "BigBlueButton", title: "My BBB Conference" }
                          }
                        })
        conference = CalendarEvent.find(json["id"]).web_conference
        expect(conference.settings[:default_return_url]).to match(%r{/courses/#{@course.id}$})
        expect(conference.user).to eq @user
      end

      it "does not fail with blank titles" do
        json = api_call(:post,
                        "/api/v1/calendar_events.json",
                        {
                          controller: "calendar_events_api", action: "create", format: "json"
                        },
                        {
                          calendar_event: {
                            context_code: "course_#{@course.id}",
                            title: "",
                            web_conference: { conference_type: "BigBlueButton", title: "" }
                          }
                        })
        conference = CalendarEvent.find(json["id"]).web_conference
        expect(conference.settings[:default_return_url]).to match(%r{/courses/#{@course.id}$})
        expect(conference.user).to eq @user
      end

      it "fails to create with invald web_conference" do
        json = api_call(:post,
                        "/api/v1/calendar_events.json",
                        {
                          controller: "calendar_events_api", action: "create", format: "json"
                        },
                        {
                          calendar_event: {
                            context_code: "course_#{@course.id}",
                            title: "API Test",
                            web_conference: { title: "My BBB Conference" }
                          }
                        })
        expect(json["errors"]).to have_key("web_conference.conference_type")
      end

      it "updates with existing web_conference" do
        event = @course.calendar_events.create(title: "to update", workflow_state: "active")
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 {
                   controller: "calendar_events_api", action: "update", format: "json", id: event.id
                 },
                 {
                   calendar_event: {
                     web_conference: { id: conference.id }
                   }
                 })
        expect(event.reload.web_conference_id).to eq conference.id
      end

      it "updates with new web conference" do
        event = @course.calendar_events.create(title: "to update", workflow_state: "active", web_conference: conference)
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 {
                   controller: "calendar_events_api", action: "update", format: "json", id: event.id
                 },
                 {
                   calendar_event: {
                     web_conference: { conference_type: "BigBlueButton", title: "My Other BBB Conference" }
                   }
                 })
        expect(event.reload.web_conference).to have_attributes(conference_type: "BigBlueButton", title: "My Other BBB Conference")
      end

      it "fails to update with invalid web_conference" do
        event = @course.calendar_events.create(title: "to update", workflow_state: "active")
        json = api_call(:put,
                        "/api/v1/calendar_events/#{event.id}",
                        {
                          controller: "calendar_events_api", action: "update", format: "json", id: event.id
                        },
                        {
                          calendar_event: {
                            web_conference: { title: "Bad" }
                          }
                        })
        expect(json["errors"]).to have_key("web_conference.conference_type")
      end

      it "removes a web conference if empty argument provided" do
        event = @course.calendar_events.create(title: "to update", workflow_state: "active", web_conference: conference)
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 {
                   controller: "calendar_events_api", action: "update", format: "json", id: event.id
                 },
                 {
                   calendar_event: {
                     web_conference: ""
                   }
                 })
        expect(event.reload.web_conference).to be_nil
      end

      it "does not remove a web conference if no argument provided" do
        event = @course.calendar_events.create(title: "to update", workflow_state: "active", web_conference: conference)
        api_call(:put,
                 "/api/v1/calendar_events/#{event.id}",
                 {
                   controller: "calendar_events_api", action: "update", format: "json", id: event.id
                 },
                 {
                   calendar_event: {
                     location: "foo"
                   }
                 })
        expect(event.reload.web_conference_id).to eq conference.id
      end
    end

    context "important dates" do
      before :once do
        @course.calendar_events.create(title: "important date", start_at: Time.zone.today, important_dates: true)
        @course.calendar_events.create(title: "not important date", start_at: Time.zone.today)
        @course.calendar_events.create(title: "undated important", important_dates: true)
      end

      it "returns calendar events that have a date with important dates if the param is sent" do
        json = api_call(:get, "/api/v1/calendar_events?important_dates=true&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          important_dates: true
                        })
        expect(json.size).to be 1
        expect(json[0]["important_dates"]).to be true
      end
    end

    context "blackout date" do
      before :once do
        @course.calendar_events.create(title: "blackout date", start_at: Time.zone.today, blackout_date: true)
        @course.calendar_events.create(title: "not blackout date", start_at: Time.zone.today)
        @course.calendar_events.create(title: "undated blackout", blackout_date: true)
      end

      it "returns calendar events that have a date with blackout date if the param is sent" do
        json = api_call(:get, "/api/v1/calendar_events?blackout_date=true&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          context_codes: ["course_#{@course.id}"],
                          blackout_date: true
                        })
        expect(json.size).to be 1
        expect(json[0]["blackout_date"]).to be true
      end
    end
  end

  context "assignments" do
    expected_fields = %w[
      all_day
      all_day_date
      assignment
      context_code
      created_at
      description
      end_at
      html_url
      id
      start_at
      title
      type
      updated_at
      url
      workflow_state
      context_name
      context_color
      important_dates
      submission_types
    ]

    it "returns assignments within the given date range" do
      @course.assignments.create(title: "1", due_at: "2012-01-07 12:00:00")
      e2 = @course.assignments.create(title: "2", due_at: "2012-01-08 12:00:00")
      @course.assignments.create(title: "3", due_at: "2012-01-19 12:00:00")

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-08&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-08",
                        end_date: "2012-01-08"
                      })
      expect(json.size).to be 1
      expect(json.first.keys).to match_array expected_fields
      expect(json.first.slice("title", "start_at", "id")).to eql({ "id" => "assignment_#{e2.id}", "title" => "2", "start_at" => "2012-01-08T12:00:00Z" })
    end

    it "orders result set by base due_at" do
      @course.assignments.create(title: "2", due_at: "2012-01-08 12:00:00")
      @course.assignments.create(title: "1", due_at: "2012-01-07 12:00:00")
      @course.assignments.create(title: "3", due_at: "2012-01-19 12:00:00")

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-19&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-07",
                        end_date: "2012-01-19"
                      })
      expect(json.size).to be 3
      expect(json.first.keys).to match_array expected_fields
      expect(json.pluck("title")).to eq %w[1 2 3]
    end

    it "does not return the description if the assignment is locked" do
      student = user_factory(active_all: true, active_state: "active")
      @course.enroll_student(student, enrollment_state: "active")
      @course.assignments.create(description: "foo", unlock_at: 1.day.from_now)

      json = api_call_as_user(student, :get, "/api/v1/calendar_events", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                type: "assignment",
                                context_codes: ["course_#{@course.id}"],
                                all_events: true
                              })
      expect(json.first).to have_key("description")
      expect(json.first["description"]).to be_nil
    end

    it "sorts and paginate assignments" do
      undated = (1..7).map { |i| create_assignments(@course.id, 1, title: "#{@course.id}:#{i}", due_at: nil).first }
      dated = (1..18).map { |i| create_assignments(@course.id, 1, title: "#{@course.id}:#{i}", due_at: Time.parse("2012-01-20 12:00:00").advance(days: -i)).first }
      ids = dated.reverse + undated

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="next",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql(ids[0...10].map { |id| "assignment_#{id}" })

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=2", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10",
                        page: "2"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="next",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="prev",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql(ids[10...20].map { |id| "assignment_#{id}" })

      json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}&per_page=10&page=3", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        all_events: 1,
                        per_page: "10",
                        page: "3"
                      })
      expect(response.headers["Link"]).to match(%r{<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=2.*>; rel="prev",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=1.*>; rel="first",<http://www.example.com/api/v1/calendar_events.*type=assignment&.*page=3.*>; rel="last"})
      expect(json.pluck("id")).to eql(ids[20...25].map { |id| "assignment_#{id}" })
    end

    it "ignores invalid end_dates" do
      @course.assignments.create(title: "a", due_at: "2012-01-08 12:00:00")
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        start_date: "2012-01-08",
                        end_date: "2012-01-07"
                      })
      expect(json.size).to be 1
    end

    it "400s for bad dates" do
      raw_api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=201-201-208&end_date=201-201-209&context_codes[]=course_#{@course.id}", {
                     controller: "calendar_events_api",
                     action: "index",
                     format: "json",
                     type: "assignment",
                     context_codes: ["course_#{@course.id}"],
                     start_date: "201-201-208",
                     end_date: "201-201-209"
                   })
      expect(response).to have_http_status :bad_request
      json = JSON.parse response.body
      expect(json["errors"]["start_date"]).to eq "Invalid date or invalid datetime for start_date"
      expect(json["errors"]["end_date"]).to eq "Invalid date or invalid datetime for end_date"
    end

    it "returns assignments from up to 10 contexts" do
      contexts = [@course.asset_string]
      course_ids = create_courses(15, enroll_user: @me)
      create_assignments(course_ids, 1, due_at: "2012-01-08 12:00:00")
      contexts.concat(course_ids.map { |id| "course_#{id}" })
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-08&end_date=2012-01-07&per_page=25&context_codes[]=" + contexts.join("&context_codes[]="), {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: contexts,
                        start_date: "2012-01-08",
                        end_date: "2012-01-07",
                        per_page: "25"
                      })
      expect(json.size).to be 9 # first context has no events
    end

    it "returns undated assignments" do
      @course.assignments.create(title: "undated")
      @course.assignments.create(title: "dated", due_at: "2012-01-08 12:00:00")
      json = api_call(:get, "/api/v1/calendar_events?type=assignment&undated=1&context_codes[]=course_#{@course.id}", {
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: ["course_#{@course.id}"],
                        undated: "1"
                      })
      expect(json.size).to be 1
      expect(json.first["due_at"]).to be_nil
    end

    context "mark_submitted_assignments" do
      before :once do
        @e1 = @course.assignments.create(title: "1", due_at: "2012-01-07 12:00:00")
        @e2 = @course.assignments.create(title: "2", due_at: "2012-01-08 12:00:00")
        sub = @e1.find_or_create_submission(@user)
        sub.submission_type = "online_quiz"
        sub.workflow_state = "submitted"
        sub.save!
      end

      it "marks assignments with user_submitted" do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-06&end_date=2012-01-09&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          type: "assignment",
                          context_codes: ["course_#{@course.id}"],
                          start_date: "2012-01-06",
                          end_date: "2012-01-09"
                        })

        expect(json.size).to be 2
        expect(json[0]["assignment"]["user_submitted"]).to be_truthy
        expect(json[1]["assignment"]["user_submitted"]).to be_falsy
      end

      context "sharding" do
        specs_require_sharding

        it "marks assignments on another shard with user_submitted" do
          @shard2.activate do
            user2 = user_factory(active_all: true)
            @course.enroll_student(user2, enrollment_state: "active")
            sub = @e2.find_or_create_submission(user2)
            sub.submission_type = "online_quiz"
            sub.workflow_state = "submitted"
            sub.save!

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-06&end_date=2012-01-09&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-06",
                              end_date: "2012-01-09"
                            })

            expect(json.size).to be 2
            expect(json[0]["assignment"]["user_submitted"]).to be_falsy
            expect(json[1]["assignment"]["user_submitted"]).to be_truthy
          end
        end
      end
    end

    context "unpublished assignments" do
      before :once do
        @course1 = @course
        course_with_teacher(active_course: true, active_enrollment: true, user: @teacher)
        @course2 = @course

        @pub1 = @course1.assignments.create(title: "published assignment 1")
        @pub2 = @course2.assignments.create(title: "published assignment 2")
        [@pub1, @pub2].each do |a|
          a.workflow_state = "published"
          a.save!
        end

        @unpub1 = @course1.assignments.create(title: "unpublished assignment 1")
        @unpub2 = @course2.assignments.create(title: "unpublished assignment 2")
        [@unpub1, @unpub2].each do |a|
          a.workflow_state = "unpublished"
          a.save!
        end
      end

      context "for teachers" do
        it "returns all assignments" do
          json = api_call_as_user(@teacher,
                                  :get,
                                  "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  all_events: "1",
                                  context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"])

          expect(json.pluck("title")).to match_array [
            "published assignment 1",
            "published assignment 2",
            "unpublished assignment 1",
            "unpublished assignment 2"
          ]
        end
      end

      context "for teachers and students" do
        before do
          @teacher_student = user_factory(active_all: true)
          teacher_enrollment = @course1.enroll_teacher(@teacher_student)
          teacher_enrollment.workflow_state = "active"
          teacher_enrollment.save!
          @course2.enroll_student(@teacher_student, enrollment_state: "active")
        end

        it "returns published assignments and all assignments for teacher contexts" do
          json = api_call_as_user(@teacher_student,
                                  :get,
                                  "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  all_events: "1",
                                  context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"])

          expect(json.pluck("title")).to match_array [
            "published assignment 1",
            "published assignment 2",
            "unpublished assignment 1",
          ]
        end
      end

      context "for students" do
        before do
          @teacher_student = user_factory(active_all: true)
          @course1.enroll_student(@teacher_student, enrollment_state: "active")
          @course2.enroll_student(@teacher_student, enrollment_state: "active")
        end

        it "returns only published assignments" do
          json = api_call_as_user(@teacher_student,
                                  :get,
                                  "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}",
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  all_events: "1",
                                  context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"])

          expect(json.pluck("title")).to match_array [
            "published assignment 1",
            "published assignment 2",
          ]
        end
      end
    end

    context "differentiated assignments" do
      before :once do
        Timecop.travel(Time.utc(2015)) do
          course_with_teacher(active_course: true, active_enrollment: true, user: @teacher)

          @student_in_overriden_section = User.create
          @student_in_general_section = User.create

          @course.enroll_student(@student_in_general_section, enrollment_state: "active")
          @section = @course.course_sections.create!(name: "test section")
          student_in_section(@section, user: @student_in_overriden_section)

          @only_vis_to_o, @not_only_vis_to_o = (1..2).map { @course.assignments.create(title: "test assig", workflow_state: "published", due_at: "2012-01-07 12:00:00") }
          @only_vis_to_o.only_visible_to_overrides = true
          @only_vis_to_o.save!
          [@only_vis_to_o, @not_only_vis_to_o].each do |a|
            a.workflow_state = "published"
            a.save!
          end

          create_section_override_for_assignment(@only_vis_to_o, { course_section: @section })
        end
      end

      context "as a student" do
        it "only shows events for visible assignments" do
          json = api_call_as_user(@student_in_overriden_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                    controller: "calendar_events_api",
                                    action: "index",
                                    format: "json",
                                    type: "assignment",
                                    context_codes: ["course_#{@course.id}"],
                                    start_date: "2011-01-08",
                                    end_date: "2099-01-08"
                                  })
          expect(json.size).to be 2

          json = api_call_as_user(@student_in_general_section, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                    controller: "calendar_events_api",
                                    action: "index",
                                    format: "json",
                                    type: "assignment",
                                    context_codes: ["course_#{@course.id}"],
                                    start_date: "2011-01-08",
                                    end_date: "2099-01-08"
                                  })
          expect(json.size).to be 1
        end
      end

      context "as an observer" do
        before do
          @observer = User.create
          @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
        end

        context "following a student with visibility" do
          before { @observer_enrollment.update_attribute(:associated_user_id, @student_in_overriden_section.id) }

          it "only shows events for assignments visible to that student" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                      controller: "calendar_events_api",
                                      action: "index",
                                      format: "json",
                                      type: "assignment",
                                      context_codes: ["course_#{@course.id}"],
                                      start_date: "2011-01-08",
                                      end_date: "2099-01-08"
                                    })
            expect(json.size).to be 2
          end
        end

        context "following two students with visibility" do
          before do
            @observer_enrollment.update_attribute(:associated_user_id, @student_in_overriden_section.id)
            student_in_section(@section, user: @student_in_general_section)
            @course.enroll_user(@observer, "ObserverEnrollment", { allow_multiple_enrollments: true, associated_user_id: @student_in_general_section.id })
          end

          it "doesnt show duplicate events" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                      controller: "calendar_events_api",
                                      action: "index",
                                      format: "json",
                                      type: "assignment",
                                      context_codes: ["course_#{@course.id}"],
                                      start_date: "2011-01-08",
                                      end_date: "2099-01-08"
                                    })
            expect(json.size).to be 2
          end
        end

        context "following a student without visibility" do
          before { @observer_enrollment.update_attribute(:associated_user_id, @student_in_general_section.id) }

          it "only shows events for assignments visible to that student" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                      controller: "calendar_events_api",
                                      action: "index",
                                      format: "json",
                                      type: "assignment",
                                      context_codes: ["course_#{@course.id}"],
                                      start_date: "2011-01-08",
                                      end_date: "2099-01-08"
                                    })
            expect(json.size).to be 1
          end
        end

        context "in a section only" do
          it "shows events for all active assignment" do
            json = api_call_as_user(@observer, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                      controller: "calendar_events_api",
                                      action: "index",
                                      format: "json",
                                      type: "assignment",
                                      context_codes: ["course_#{@course.id}"],
                                      start_date: "2011-01-08",
                                      end_date: "2099-01-08"
                                    })
            expect(json.size).to be 2
          end
        end
      end

      context "as a teacher" do
        it "shows events for all active assignment" do
          json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?type=assignment&start_date=2011-01-08&end_date=2099-01-08&context_codes[]=course_#{@course.id}", {
                                    controller: "calendar_events_api",
                                    action: "index",
                                    format: "json",
                                    type: "assignment",
                                    context_codes: ["course_#{@course.id}"],
                                    start_date: "2011-01-08",
                                    end_date: "2099-01-08"
                                  })
          expect(json.size).to be 2
        end
      end
    end

    context "all assignments" do
      before :once do
        @course.assignments.create(title: "undated")
        @course.assignments.create(title: "dated", due_at: "2012-01-08 12:00:00")
      end

      it "returns all assignments" do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          type: "assignment",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1"
                        })
        expect(json.size).to be 2
      end

      it "returns all assignments, ignoring the undated flag" do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&undated=1&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          type: "assignment",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1",
                          undated: "1"
                        })
        expect(json.size).to be 2
      end

      it "returns all assignments, ignoring the start_date and end_date" do
        json = api_call(:get, "/api/v1/calendar_events?type=assignment&all_events=1&start_date=2012-02-01&end_date=2012-02-01&context_codes[]=course_#{@course.id}", {
                          controller: "calendar_events_api",
                          action: "index",
                          format: "json",
                          type: "assignment",
                          context_codes: ["course_#{@course.id}"],
                          all_events: "1",
                          start_date: "2012-02-01",
                          end_date: "2012-02-01"
                        })
        expect(json.size).to be 2
      end
    end

    it "gets a single assignment" do
      assignment = @course.assignments.create(title: "event")
      json = api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                        controller: "calendar_events_api", action: "show", id: "assignment_#{assignment.id}", format: "json"
                      })
      expect(json.keys).to match_array expected_fields
      expect(json.slice("title", "id")).to eql({ "id" => "assignment_#{assignment.id}", "title" => "event" })
    end

    it "enforces permissions" do
      assignment = course_factory.assignments.create(title: "event")
      raw_api_call(:get, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                     controller: "calendar_events_api", action: "show", id: "assignment_#{assignment.id}", format: "json"
                   })
      expect(JSON.parse(response.body)["status"]).to eq "unauthorized"
    end

    it "updates assignment due dates" do
      assignment = @course.assignments.create(title: "undated")

      json = api_call(:put,
                      "/api/v1/calendar_events/assignment_#{assignment.id}",
                      { controller: "calendar_events_api", action: "update", id: "assignment_#{assignment.id}", format: "json" },
                      { calendar_event: { start_at: "2012-01-09 12:00:00" } })
      expect(json.keys).to match_array expected_fields
      expect(json["start_at"]).to eql "2012-01-09T12:00:00Z"
    end

    it "does not delete assignments" do
      assignment = @course.assignments.create(title: "undated")
      raw_api_call(:delete, "/api/v1/calendar_events/assignment_#{assignment.id}", {
                     controller: "calendar_events_api", action: "destroy", id: "assignment_#{assignment.id}", format: "json"
                   })
      assert_status(404)
    end

    context "date overrides" do
      before :once do
        @default_assignment = @course.assignments.create(title: "overridden", due_at: "2012-01-12 12:00:00") # out of range
        @default_assignment.workflow_state = "published"
        @default_assignment.save!
      end

      context "as student" do
        before :once do
          @student = user_factory active_all: true, active_state: "active"
        end

        context "when no sections" do
          before :once do
            @course.enroll_student(@student, enrollment_state: "active")
          end

          it "returns an all-day override" do
            # make the assignment non-all day
            @default_assignment.due_at = DateTime.parse("2012-01-12 04:42:00")
            @default_assignment.save!
            expect(@default_assignment.all_day).to be_falsey
            expect(@default_assignment.all_day_date).to eq DateTime.parse("2012-01-12 04:42:00").to_date

            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: DateTime.parse("2012-01-21 23:59:00"))
            expect(@override.all_day).to be_truthy
            expect(@override.all_day_date).to eq DateTime.parse("2012-01-21 23:59:00").to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-01",
                              end_date: "2012-01-31",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"

            expect(json.first["all_day"]).to be_truthy
            expect(json.first["all_day_date"]).to eq "2012-01-21"
          end

          it "returns a non-all-day override" do
            @default_assignment.due_at = DateTime.parse("2012-01-12 23:59:00")
            @default_assignment.save!
            expect(@default_assignment.all_day).to be_truthy
            expect(@default_assignment.all_day_date).to eq DateTime.parse("2012-01-12 23:59:00").to_date

            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: DateTime.parse("2012-01-21 04:42:00"))
            expect(@override.all_day).to be_falsey
            expect(@override.all_day_date).to eq DateTime.parse("2012-01-21 04:42:00").to_date

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-31&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-01",
                              end_date: "2012-01-31",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"

            expect(json.first["all_day"]).to be_falsey
            expect(json.first["all_day_date"]).to eq "2012-01-21"
          end

          it "returns a non-overridden assignment" do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include("assignment_override")
          end

          it "returns an override when present" do
            @default_assignment.due_at = DateTime.parse("2012-01-08 12:00:00")
            @default_assignment.save!
            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: DateTime.parse("2012-01-14 12:00:00"))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first["end_at"]).to eq "2012-01-14T12:00:00Z"
            expect(json.first.keys).not_to include("assignment_override")
          end

          it "returns assignment when override is in range but assignment is not" do
            @default_assignment.due_at = DateTime.parse("2012-01-01 12:00:00") # out of range
            @default_assignment.save!
            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: DateTime.parse("2012-01-08 12:00:00")) # in range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["end_at"]).to eq "2012-01-08T12:00:00Z"
          end

          it "does not return an assignment when assignment due_at in range but override is out" do
            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: DateTime.parse("2012-01-17 12:00:00")) # out of range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 0 # nothing returned
          end

          it "returns user specific override" do
            override = assignment_override_model(assignment: @default_assignment,
                                                 due_at: DateTime.parse("2012-01-12 12:00:00"))
            override.assignment_override_students.create!(user: @user)
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
          end
        end

        context "with sections" do
          before :once do
            @section1 = @course.course_sections.create!(name: "Section A")
            @section2 = @course.course_sections.create!(name: "Section B")
            @course.enroll_user(@student, "StudentEnrollment", section: @section2, enrollment_state: "active")
          end

          it "returns a non-overridden assignment" do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include("assignment_override")
          end

          it "returns an override when present" do
            @default_assignment.due_at = DateTime.parse("2012-01-08 12:00:00")
            @default_assignment.save!
            override = assignment_override_model(assignment: @default_assignment, due_at: DateTime.parse("2012-01-14 12:00:00"))
            override.set = @section2
            override.save!
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first["end_at"]).to eq "2012-01-14T12:00:00Z"
          end

          it "returns 1 assignment for latest date" do
            # Setup assignment
            assignment_override_model(assignment: @default_assignment,
                                      set: @section1,
                                      due_at: DateTime.parse("2012-01-12 12:00:00")) # later than assignment
            assignment_override_model(assignment: @default_assignment,
                                      set: @section2,
                                      due_at: DateTime.parse("2012-01-14 12:00:00")) # latest
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["end_at"]).to eq "2012-01-14T12:00:00Z"
          end

          context "with user and section overrides" do
            before do
              override = assignment_override_model(
                assignment: @default_assignment,
                due_at: DateTime.parse("2012-01-12 12:00:00")
              )
              override.assignment_override_students.create!(user: @user)
              assignment_override_model(
                assignment: @default_assignment,
                set: @section2,
                due_at: DateTime.parse("2012-01-14 12:00:00")
              )
            end

            let(:json) do
              api_call(
                :get,
                "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}",
                controller: "calendar_events_api",
                action: "index",
                format: "json",
                type: "assignment",
                context_codes: ["course_#{@course.id}"],
                start_date: "2012-01-07",
                end_date: "2012-01-16",
                per_page: "25"
              )
            end

            it "prioritizes user overrides" do
              aggregate_failures do
                expect(json.size).to eq 1
                expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
              end
            end
          end
        end
      end

      context "as teacher" do
        it "returns 1 assignment when no overrides" do
          json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                            controller: "calendar_events_api",
                            action: "index",
                            format: "json",
                            type: "assignment",
                            context_codes: ["course_#{@course.id}"],
                            start_date: "2012-01-07",
                            end_date: "2012-01-16",
                            per_page: "25"
                          })
          expect(json.size).to eq 1 # 1 assignment
          expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
          expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
          expect(json.first.keys).not_to include("assignment_override")
        end

        it "gets explicit assignment with override info" do
          skip "not sure what the desired behavior here is"
          override = assignment_override_model(assignment: @default_assignment,
                                               set: @course.default_section,
                                               due_at: DateTime.parse("2012-01-14 12:00:00"))
          json = api_call(:get, "/api/v1/calendar_events/assignment_#{@default_assignment.id}", {
                            controller: "calendar_events_api", action: "show", id: "assignment_#{@default_assignment.id}", format: "json"
                          })
          # json.size.should == 2
          expect(json.slice("id", "override_id", "end_at")).to eql({ "id" => "assignment_#{@default_assignment.id}",
                                                                     "override_id" => override.id,
                                                                     "end_at" => "2012-01-14T12:00:00Z" })
          expect(json.keys).to match_array expected_fields
        end

        context "with sections" do
          before :once do
            @section1 = @course.course_sections.create!(name: "Section A")
            @section2 = @course.course_sections.create!(name: "Section B")
            student_in_section(@section1)
            student_in_section(@section2)
            @user = @teacher
          end

          it "returns 1 entry for each instance" do
            # Setup assignment
            override1 = assignment_override_model(assignment: @default_assignment,
                                                  set: @section1,
                                                  due_at: DateTime.parse("2012-01-14 12:00:00"))
            override2 = assignment_override_model(assignment: @default_assignment,
                                                  set: @section2,
                                                  due_at: DateTime.parse("2012-01-18 12:00:00"))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-19&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-19",
                              per_page: "25"
                            })
            expect(json.size).to eq 3
            # sort results locally by end_at
            json.sort_by! { |a| a["end_at"] }
            expect(json[0].keys).not_to include("assignment_override")
            expect(json[1]["assignment_overrides"][0]["id"]).to eq override1.id
            expect(json[2]["assignment_overrides"][0]["id"]).to eq override2.id
            expect(json[0]["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json[1]["end_at"]).to eq "2012-01-14T12:00:00Z"
            expect(json[2]["end_at"]).to eq "2012-01-18T12:00:00Z"
          end

          it "returns 1 assignment (override) when others are outside the range" do
            # Alter assignment
            @default_assignment.due_at = DateTime.parse("2012-01-01 12:00:00") # outside range
            @default_assignment.save!
            # Setup overrides
            override1 = assignment_override_model(assignment: @default_assignment,
                                                  set: @section1,
                                                  due_at: DateTime.parse("2012-01-12 12:00:00")) # in range
            assignment_override_model(assignment: @default_assignment,
                                      set: @section2,
                                      due_at: DateTime.parse("2012-01-18 12:00:00")) # outside range
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["assignment_overrides"][0]["id"]).to eq override1.id
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
          end
        end
      end

      context "as TA" do
        before :once do
          @ta = user_factory active_all: true, active_state: "active"
        end

        context "when no sections" do
          before :once do
            @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active")
          end

          it "returns a non-overridden assignment" do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first.keys).not_to include("assignment_override")
          end

          it "returns override when present" do
            @default_assignment.due_at = Time.zone.parse("2012-01-08 12:00:00")
            @default_assignment.save!
            assignment_override_model(assignment: @default_assignment,
                                      set: @course.default_section,
                                      due_at: Time.zone.parse("2012-01-14 12:00:00"))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # should only return the overridden assignment if all sections have an override
            expect(json[0].keys).to include("assignment_overrides")
            expect(json[0]["end_at"]).to eq "2012-01-14T12:00:00Z"
          end
        end

        context "when TA of one section" do
          before :once do
            @section1 = @course.course_sections.create!(name: "Section A")
            @section2 = @course.course_sections.create!(name: "Section B")
            @course.enroll_user(@ta, "TaEnrollment", enrollment_state: "active", section: @section1) # only in 1 section
            student_in_section(@section1)
            student_in_section(@section2)
            @user = @ta
          end

          it "receives all assignments including other sections" do
            @default_assignment.due_at = DateTime.parse("2012-01-08 12:00:00")
            @default_assignment.save!
            override1 = assignment_override_model(assignment: @default_assignment,
                                                  set: @section1,
                                                  due_at: DateTime.parse("2012-01-12 12:00:00"))
            override2 = assignment_override_model(assignment: @default_assignment,
                                                  set: @section2,
                                                  due_at: DateTime.parse("2012-01-14 12:00:00"))
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 3 # all versions
            json.sort_by! { |a| a["end_at"] }
            expect(json[0].keys).not_to include("assignment_override")
            expect(json[0]["end_at"]).to eq "2012-01-08T12:00:00Z"
            expect(json[1]["assignment_overrides"][0]["id"]).to eq override1.id
            expect(json[1]["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json[2]["assignment_overrides"][0]["id"]).to eq override2.id
            expect(json[2]["end_at"]).to eq "2012-01-14T12:00:00Z"
          end
        end
      end

      context "as observer" do
        before :once do
          @student = user_factory(active_all: true, active_state: "active")
          @observer = user_factory(active_all: true, active_state: "active")
        end

        context "when not observing any students" do
          before :once do
            @course.enroll_user(@observer,
                                "ObserverEnrollment",
                                enrollment_state: "active",
                                section: @course.default_section)
          end

          it "returns assignment for enrollment" do
            assignment_override_model(assignment: @default_assignment,
                                      set: @course.course_sections.create!(name: "Section 2"),
                                      due_at: Time.zone.parse("2012-01-14 12:00:00"))

            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
          end
        end

        context "when no sections" do
          it "returns assignments with no override" do
            @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active")
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 1 # 1 assignment
            expect(json.first["id"]).to eq "assignment_#{@default_assignment.id}"
            expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
          end

          context "observing single student" do
            before :once do
              @student_enrollment = @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active", section: @course.default_section)
              @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", section: @course.default_section)
              @observer_enrollment.update_attribute(:associated_user_id, @student.id)
            end

            it "returns student specific overrides" do
              assignment_override_model(assignment: @default_assignment,
                                        set: @course.default_section,
                                        due_at: DateTime.parse("2012-01-13 12:00:00"))
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                type: "assignment",
                                context_codes: ["course_#{@course.id}"],
                                start_date: "2012-01-07",
                                end_date: "2012-01-16",
                                per_page: "25"
                              })
              expect(json.size).to eq 1 # only 1
              expect(json.first["end_at"]).to eq "2012-01-13T12:00:00Z"
            end

            it "returns standard assignment" do
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                type: "assignment",
                                context_codes: ["course_#{@course.id}"],
                                start_date: "2012-01-07",
                                end_date: "2012-01-16",
                                per_page: "25"
                              })
              expect(json.size).to eq 1 # only 1
              expect(json.first["end_at"]).to eq "2012-01-12T12:00:00Z"
            end
          end
        end

        context "with sections" do
          before :once do
            @section1 = @course.course_sections.create!(name: "Section A")
            @section2 = @course.course_sections.create!(name: "Section B")
            @student_enrollment = @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active", section: @section1)
            @observer_enrollment = @course.enroll_user(@observer, "ObserverEnrollment", enrollment_state: "active", section: @section1)
            @observer_enrollment.update_attribute(:associated_user_id, @student.id)
          end

          context "observing single student" do
            it "returns linked student specific override" do
              assignment_override_model(assignment: @default_assignment,
                                        set: @section1,
                                        due_at: DateTime.parse("2012-01-13 12:00:00"))
              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                type: "assignment",
                                context_codes: ["course_#{@course.id}"],
                                start_date: "2012-01-07",
                                end_date: "2012-01-16",
                                per_page: "25"
                              })
              expect(json.size).to eq 1
              expect(json.first["end_at"]).to eq "2012-01-13T12:00:00Z"
            end

            it "returns only override for student section" do
              assignment_override_model(assignment: @default_assignment,
                                        set: @section1,
                                        due_at: DateTime.parse("2012-01-13 12:00:00"))
              assignment_override_model(assignment: @default_assignment,
                                        set: @section2,
                                        due_at: DateTime.parse("2012-01-14 12:00:00"))

              json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                                controller: "calendar_events_api",
                                action: "index",
                                format: "json",
                                type: "assignment",
                                context_codes: ["course_#{@course.id}"],
                                start_date: "2012-01-07",
                                end_date: "2012-01-16",
                                per_page: "25"
                              })
              expect(json.size).to eq 1
              expect(json.first["end_at"]).to eq "2012-01-13T12:00:00Z"
            end
          end

          context "observing multiple students" do
            before :once do
              @student2 = user_factory(active_all: true, active_state: "active")
            end

            context "when in same course section" do
              before do
                @student_enrollment2 = @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active", section: @section1)
                @observer_enrollment2 = ObserverEnrollment.new(user: @observer,
                                                               course: @course,
                                                               course_section: @section1,
                                                               workflow_state: "active")

                @observer_enrollment2.associated_user_id = @student2.id
                @observer_enrollment2.save!
              end

              it "returns a single assignment event" do
                @user = @observer
                assignment_override_model(assignment: @default_assignment,
                                          set: @section1,
                                          due_at: DateTime.parse("2012-01-14 12:00:00"))
                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-01&end_date=2012-01-30&per_page=25&context_codes[]=course_#{@course.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course.id}"],
                                  start_date: "2012-01-01",
                                  end_date: "2012-01-30",
                                  per_page: "25"
                                })
                expect(json.size).to eq 1
                expect(json.first["end_at"]).to eq "2012-01-14T12:00:00Z"
              end
            end

            context "when in same course different sections" do
              before do
                @student_enrollment2 = @course.enroll_user(@student2, "StudentEnrollment", enrollment_state: "active", section: @section2)
                @observer_enrollment2 = ObserverEnrollment.create!(user: @observer,
                                                                   course: @course,
                                                                   course_section: @section2,
                                                                   workflow_state: "active")

                @observer_enrollment2.update_attribute(:associated_user_id, @student2.id)
              end

              it "returns two assignments one for each section" do
                @user = @observer
                assignment_override_model(assignment: @default_assignment,
                                          set: @section1,
                                          due_at: DateTime.parse("2012-01-14 12:00:00"))
                assignment_override_model(assignment: @default_assignment,
                                          set: @section2,
                                          due_at: DateTime.parse("2012-01-15 12:00:00"))
                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course.id}"],
                                  start_date: "2012-01-07",
                                  end_date: "2012-01-16",
                                  per_page: "25"
                                })
                expect(json.size).to eq 2
                json.sort_by! { |a| a["end_at"] }
                expect(json[0]["end_at"]).to eq "2012-01-14T12:00:00Z"
                expect(json[1]["end_at"]).to eq "2012-01-15T12:00:00Z"
              end
            end

            context "when in different courses" do
              before do
                @course1 = @course
                @course2 = course_factory(active_all: true)

                @assignment1 = @default_assignment
                @assignment2 = @course2.assignments.create!(title: "Override2", due_at: "2012-01-13 12:00:00Z")
                [@assignment1, @assignment2].each(&:save!)

                @student1_enrollment = StudentEnrollment.create!(user: @student, workflow_state: "active", course_section: @course1.default_section, course: @course1)
                @student2_enrollment = StudentEnrollment.create!(user: @student2, workflow_state: "active", course_section: @course2.default_section, course: @course2)
                @observer1_enrollment = ObserverEnrollment.create!(user: @observer, workflow_state: "active", course_section: @course1.default_section, course: @course1)
                @observer2_enrollment = ObserverEnrollment.create!(user: @observer, workflow_state: "active", course_section: @course2.default_section, course: @course2)

                @observer1_enrollment.update_attribute(:associated_user_id, @student.id)
                @observer2_enrollment.update_attribute(:associated_user_id, @student2.id)
                @user = @observer
              end

              it "returns two assignments" do
                assignment_override_model(assignment: @assignment1, set: @course1.default_section, due_at: DateTime.parse("2012-01-14 12:00:00"))
                assignment_override_model(assignment: @assignment2, set: @course2.default_section, due_at: DateTime.parse("2012-01-15 12:00:00"))

                json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course1.id}&context_codes[]=course_#{@course2.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"],
                                  start_date: "2012-01-07",
                                  end_date: "2012-01-16",
                                  per_page: "25"
                                })

                expect(json.size).to eq 2
                json.sort_by! { |a| a["end_at"] }
                expect(json[0]["end_at"]).to eq "2012-01-14T12:00:00Z"
                expect(json[1]["end_at"]).to eq "2012-01-15T12:00:00Z"
              end
            end
          end
        end
      end

      # Admins who are not enrolled in the course
      context "as admin" do
        before :once do
          @admin = account_admin_user
          @section1 = @course.default_section
          @section2 = @course.course_sections.create!(name: "Section B")
          student_in_section(@section2)
          @user = @admin
        end

        context "when viewing own calendar" do
          it "returns 0 course assignments" do
            json = api_call(:get, "/api/v1/calendar_events?type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 0 # 0 assignments returned
          end
        end

        context "when viewing course calendar" do
          it "displays assignments and overrides" do # behave like teacher
            override = assignment_override_model(assignment: @default_assignment,
                                                 due_at: DateTime.parse("2012-01-15 12:00:00"),
                                                 set: @section2)
            json = api_call(:get, "/api/v1/calendar_events?&type=assignment&start_date=2012-01-07&end_date=2012-01-16&per_page=25&context_codes[]=course_#{@course.id}", {
                              controller: "calendar_events_api",
                              action: "index",
                              format: "json",
                              type: "assignment",
                              context_codes: ["course_#{@course.id}"],
                              start_date: "2012-01-07",
                              end_date: "2012-01-16",
                              per_page: "25"
                            })
            expect(json.size).to eq 2
            # Should include the default and override in return
            json.sort_by! { |a| a["end_at"] }
            expect(json[0]["end_at"]).to eq "2012-01-12T12:00:00Z"
            expect(json[0]["override_id"]).to be_nil
            expect(json[0].keys).not_to include("assignment_override")
            expect(json[1]["end_at"]).to eq "2012-01-15T12:00:00Z"
            expect(json[1]["assignment_overrides"][0]["id"]).to eq override.id
          end
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      before :once do
        @c0 = @course
        @a0 = @c0.assignments.create(workflow_state: "published", due_at: 1.day.from_now)
        @e0 = @c0.calendar_events.create!(start_at: 1.day.from_now, end_at: 1.day.from_now + 1.hour)
        @shard1.activate do
          @shard1_account = Account.create!
          @c1 = course_with_teacher(user: @me, account: @shard1_account, enrollment_state: "active").course
          @a1 = @c1.assignments.create(workflow_state: "published", due_at: 2.days.from_now)
          @e1 = @c1.calendar_events.create!(start_at: 2.days.from_now, end_at: 2.days.from_now + 1.hour)
        end
      end

      it "paginates assignments from multiple shards correctly" do
        json = api_call(:get,
                        "/api/v1/calendar_events?type=assignment&context_codes[]=course_#{@c0.id}&context_codes[]=course_#{@c1.id}&all_events=1&per_page=1",
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: [@c0.asset_string, @c1.global_asset_string],
                        all_events: 1,
                        per_page: 1)
        expect(json.size).to eq 1
        expect(json[0]["id"]).to eq @a0.asset_string

        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.detect { |link| link[:rel] == "next" }
        expect(next_link).not_to be_nil

        json = api_call(:get,
                        next_link[:uri].to_s,
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        type: "assignment",
                        context_codes: [@c0.asset_string, @c1.global_asset_string],
                        all_events: 1,
                        per_page: 1,
                        page: next_link["page"])
        expect(json.size).to eq 1
        expect(json[0]["id"]).to eq @a1.asset_string

        links = Api.parse_pagination_links(response.headers["Link"])
        expect(links.detect { |link| link[:rel] == "next" }).to be_nil
      end

      it "paginates events from multiple shards correctly" do
        json = api_call(:get,
                        "/api/v1/calendar_events?context_codes[]=course_#{@c0.id}&context_codes[]=course_#{@c1.id}&all_events=1&per_page=1&include[]=web_conference",
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        include: ["web_conference"],
                        context_codes: [@c0.asset_string, @c1.global_asset_string],
                        all_events: 1,
                        per_page: 1)
        expect(json.size).to eq 1
        expect(json[0]["id"]).to eq @e0.id

        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.detect { |link| link[:rel] == "next" }
        expect(next_link).not_to be_nil

        json = api_call(:get,
                        next_link[:uri].to_s,
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: [@c0.asset_string, @c1.global_asset_string],
                        include: ["web_conference"],
                        all_events: 1,
                        per_page: 1,
                        page: next_link["page"])
        expect(json.size).to eq 1
        expect(json[0]["id"]).to eq @e1.id

        links = Api.parse_pagination_links(response.headers["Link"])
        expect(links.detect { |link| link[:rel] == "next" }).to be_nil
      end

      it "returns important dates over multiple shards" do
        @e0.update important_dates: true
        @e1.update important_dates: true
        json = api_call(:get,
                        "/api/v1/calendar_events?context_codes[]=course_#{@c0.id}&context_codes[]=course_#{@c1.id}&all_events=1&important_dates=1",
                        controller: "calendar_events_api",
                        action: "index",
                        format: "json",
                        context_codes: [@c0.asset_string, @c1.global_asset_string],
                        all_events: 1,
                        important_dates: 1)
        expect(json.size).to eq 2
        expect(json.pluck("id")).to match_array([@e0.id, @e1.id])
      end
    end

    context "important dates" do
      before :once do
        @student = user_factory(active_all: true, active_state: "active")
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        @other_student = user_factory(active_all: true, active_state: "active")
        @course.enroll_user(@other_student, "StudentEnrollment", enrollment_state: "active")

        @course.assignments.create!(title: "important date", due_at: DateTime.current, important_dates: true)
        @course.assignments.create!(title: "important date without due", important_dates: true)
        overrides_assignment = @course.assignments.create!(title: "important date with override dates", important_dates: true)
        overrides_assignment.assignment_overrides.create!(due_at_overridden: true, due_at: DateTime.current, set: @course.default_section)
        specific_overrides_assignment = @course.assignments.create!(title: "important date with override for others", important_dates: true)
        override = specific_overrides_assignment.assignment_overrides.create!(due_at_overridden: true, due_at: DateTime.current, set_type: "ADHOC")
        override.assignment_override_students.create!(user: @other_student)
        @course.assignments.create!(title: "not important date", due_at: DateTime.current)
      end

      it "returns all assignments with important dates if the user is a teacher" do
        json = api_call_as_user(@teacher, :get, "/api/v1/calendar_events?important_dates=true&type=assignment&context_codes[]=course_#{@course.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course.id}"],
                                  important_dates: true
                                })
        expect(json.size).to be 4
        expect(json[0]["important_dates"]).to be true
      end

      it "returns assignments with dates for the user with important dates if the param is sent" do
        json = api_call_as_user(@other_student, :get, "/api/v1/calendar_events?important_dates=true&type=assignment&context_codes[]=course_#{@course.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course.id}"],
                                  important_dates: true
                                })
        expect(json.size).to be 3
        expect(json[0]["important_dates"]).to be true
      end

      it "returns assignments with important dates if the param is sent" do
        json = api_call_as_user(@student, :get, "/api/v1/calendar_events?important_dates=true&type=assignment&context_codes[]=course_#{@course.id}", {
                                  controller: "calendar_events_api",
                                  action: "index",
                                  format: "json",
                                  type: "assignment",
                                  context_codes: ["course_#{@course.id}"],
                                  important_dates: true
                                })
        expect(json.size).to be 2
        expect(json[0]["important_dates"]).to be true
      end
    end

    describe "log_event_count" do
      before :once do
        student_in_course(course: @course)
        assignment = @course.assignments.create!(workflow_state: "published", due_at: 1.day.from_now, submission_types: "online_text_entry")
        override = assignment.assignment_overrides.create!(due_at: 2.days.from_now, due_at_overridden: true)
        override.assignment_override_students.create!(user: @student)
      end

      before do
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:count)
      end

      let_once(:start_date) { Time.now }
      let_once(:end_date) { 1.week.from_now }

      it "logs when event count exceeds page size" do
        expect(InstStatsd::Statsd).to receive(:increment).with("calendar.events_api.per_page_exceeded.count").once
        expect(InstStatsd::Statsd).to receive(:count).with("calendar.events_api.per_page_exceeded.value", 2).once
        api_call_as_user(@teacher,
                         :get,
                         "/api/v1/calendar_events",
                         {
                           controller: "calendar_events_api",
                           action: "index",
                           format: "json",
                           type: "assignment",
                           context_codes: ["course_#{@course.id}"],
                           start_date: start_date.iso8601,
                           end_date: end_date.iso8601,
                           per_page: 1
                         })
      end

      it "does not log if the page size is not exceeded" do
        expect(InstStatsd::Statsd).not_to receive(:increment).with("calendar.events_api.per_page_exceeded.count")
        expect(InstStatsd::Statsd).not_to receive(:count).with("calendar.events_api.per_page_exceeded.value")
        api_call_as_user(@teacher,
                         :get,
                         "/api/v1/calendar_events",
                         {
                           controller: "calendar_events_api",
                           action: "index",
                           format: "json",
                           type: "assignment",
                           context_codes: ["course_#{@course.id}"],
                           start_date: start_date.iso8601,
                           end_date: end_date.iso8601,
                           per_page: 5
                         })
      end
    end
  end

  context "user index" do
    before :once do
      @student = user_factory(active_all: true, active_state: "active")
      @course.enroll_student(@student, enrollment_state: "active")
      @observer = user_factory(active_all: true, active_state: "active")
      @course.enroll_user(
        @observer,
        "ObserverEnrollment",
        enrollment_state: "active",
        associated_user_id: @student.id
      )
      add_linked_observer(@student, @observer)
      @contexts = [@course.asset_string]
      @ctx_str = @contexts.join("&context_codes[]=")
      @me = @observer
    end

    it "returns observee's calendar events" do
      3.times do |idx|
        @course.calendar_events.create(title: "event #{idx}", workflow_state: "active")
      end
      json = api_call(:get,
                      "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=#{@ctx_str}",
                      {
                        controller: "calendar_events_api",
                        action: "user_index",
                        format: "json",
                        context_codes: @contexts,
                        all_events: true,
                        user_id: @student.id
                      })
      expect(json.length).to be 3
    end

    it "returns submissions with assignments" do
      assg = @course.assignments.create(workflow_state: "published", due_at: 3.days.from_now, submission_types: "online_text_entry")
      assg.submit_homework @student, submission_type: "online_text_entry"
      json = api_call(
        :get,
        "/api/v1/users/#{@student.id}/calendar_events?all_events=true&type=assignment&include[]=submission&context_codes[]=#{@ctx_str}",
        {
          controller: "calendar_events_api",
          action: "user_index",
          format: "json",
          type: "assignment",
          include: ["submission"],
          context_codes: @contexts,
          all_events: true,
          user_id: @student.id
        }
      )
      expect(json.first["assignment"]["submission"]).not_to be_nil
    end

    it "allows specifying submission types" do
      @course.assignments.create(
        workflow_state: "published", due_at: 3.days.from_now, submission_types: "online_text_entry"
      )
      wiki_assignment = @course.assignments.create(
        workflow_state: "published", due_at: 3.days.from_now, submission_types: "wiki_page"
      )
      @course.assignments.create(workflow_state: "published", due_at: 3.days.from_now, submission_types: "not_graded")
      json = api_call(
        :get,
        "/api/v1/users/#{@student.id}/calendar_events",
        {
          controller: "calendar_events_api",
          action: "user_index",
          format: "json",
          type: "assignment",
          context_codes: @contexts,
          all_events: true,
          user_id: @student.id,
          submission_types: ["wiki_page"]
        }
      )
      expect(json.map { |a| a.dig("assignment", "id") }).to match_array [wiki_assignment.id]
    end

    it "allows specifying submission types to exclude" do
      text_assignment = @course.assignments.create(
        workflow_state: "published", due_at: 3.days.from_now, submission_types: "online_text_entry"
      )
      @course.assignments.create(workflow_state: "published", due_at: 3.days.from_now, submission_types: "wiki_page")
      ungraded_assignment = @course.assignments.create(
        workflow_state: "published", due_at: 3.days.from_now, submission_types: "not_graded"
      )
      json = api_call(
        :get,
        "/api/v1/users/#{@student.id}/calendar_events",
        {
          controller: "calendar_events_api",
          action: "user_index",
          format: "json",
          type: "assignment",
          context_codes: @contexts,
          all_events: true,
          user_id: @student.id,
          exclude_submission_types: ["wiki_page"]
        }
      )
      expect(json.map { |a| a.dig("assignment", "id") }).to match_array [text_assignment.id, ungraded_assignment.id]
    end

    context "web_conferences" do
      before(:once) do
        plugin = PluginSetting.create!(name: "big_blue_button")
        plugin.update_attribute(:settings, { key: "value" })
        3.times do |idx|
          conference = WebConference.create!(context: @course, user: @user, conference_type: "BigBlueButton")
          conference.add_initiator(@user)
          @course.calendar_events.create!(title: "event #{idx}",
                                          workflow_state: "active",
                                          web_conference: conference)
        end
      end

      it "does not return web conferences by default" do
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/calendar_events?all_events=true&context_codes[]=#{@ctx_str}",
                        {
                          controller: "calendar_events_api",
                          action: "user_index",
                          format: "json",
                          context_codes: @contexts,
                          all_events: true,
                          user_id: @user.id
                        })
        expect(json.any? { |e| e.key?("web_conference") }).to be false
      end

      it "includes web conferences when include specified" do
        json = api_call(:get,
                        "/api/v1/users/#{@user.id}/calendar_events?all_events=true&context_codes[]=#{@ctx_str}&include[]=web_conference",
                        {
                          controller: "calendar_events_api",
                          action: "user_index",
                          format: "json",
                          context_codes: @contexts,
                          all_events: true,
                          user_id: @user.id,
                          include: ["web_conference"]
                        })
        expect(json.pluck("web_conference").compact.length).to be 3
      end
    end
  end

  context "user_index (but for partial observers)" do
    before :once do
      @observed_course = @course
      @student = user_factory(active_all: true, active_state: "active")
      @observed_course.enroll_student(@student, enrollment_state: "active")
      @observer = user_factory(active_all: true, active_state: "active")
      @observed_course.enroll_user(@observer,
                                   "ObserverEnrollment",
                                   enrollment_state: "active",
                                   associated_user_id: @student.id)

      @observed_event = @observed_course.calendar_events.create!(title: "observed", workflow_state: "active")

      @unobserved_course = course_factory(active_all: true)
      @unobserved_course.enroll_student(@student, enrollment_state: "active")

      @me = @observer
    end

    it "returns observee's calendar events in the observed course" do
      json = api_call(:get,
                      "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=course_#{@observed_course.id}",
                      {
                        controller: "calendar_events_api",
                        action: "user_index",
                        format: "json",
                        all_events: true,
                        user_id: @student.id,
                        context_codes: ["course_#{@observed_course.id}"]
                      })
      expect(json.length).to be 1
      expect(json.first["id"]).to eq @observed_event.id
    end

    it "fails trying to get calendar events in a course the observer isn't in observing them in" do
      api_call(:get,
               "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=course_#{@observed_course.id}&context_codes[]=course_#{@unobserved_course.id}",
               {
                 controller: "calendar_events_api",
                 action: "user_index",
                 format: "json",
                 all_events: true,
                 user_id: @student.id,
                 context_codes: ["course_#{@observed_course.id}", "course_#{@unobserved_course.id}"]
               },
               {},
               {},
               { expected_status: 401 })
    end

    it "returns observee's calendar events in a group in the observed course" do
      group = @observed_course.groups.create!
      group.add_user(@student)
      event = group.calendar_events.create!(title: "group", workflow_state: "active")
      json = api_call(:get,
                      "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=group_#{group.id}",
                      {
                        controller: "calendar_events_api",
                        action: "user_index",
                        format: "json",
                        all_events: true,
                        user_id: @student.id,
                        context_codes: ["group_#{group.id}"]
                      })
      expect(json.length).to be 1
      expect(json.first["id"]).to eq event.id
    end

    it "fails trying to get calendar events for a group in a course the observer isn't in observing them in" do
      group = @unobserved_course.groups.create!
      group.add_user(@student)
      api_call(:get,
               "/api/v1/users/#{@student.id}/calendar_events?all_events=true&context_codes[]=group_#{group.id}",
               {
                 controller: "calendar_events_api",
                 action: "user_index",
                 format: "json",
                 all_events: true,
                 user_id: @student.id,
                 context_codes: ["group_#{group.id}"]
               },
               {},
               {},
               { expected_status: 401 })
    end
  end

  context "calendar feed" do
    before :once do
      time = Time.utc(Time.now.year, Time.now.month, Time.now.day, 4, 20)
      @student = user_factory(active_all: true, active_state: "active")
      @course.enroll_student(@student, enrollment_state: "active")
      @student2 = user_factory(active_all: true, active_state: "active")
      @course.enroll_student(@student2, enrollment_state: "active")

      @event = @course.calendar_events.create(title: "course event", start_at: time + 1.day)
      @assignment = @course.assignments.create(title: "original assignment", due_at: time + 2.days)
      @override = assignment_override_model(
        assignment: @assignment, due_at: @assignment.due_at + 3.days, set: @course.default_section
      )

      @appointment_group = AppointmentGroup.create!(
        title: "appointment group",
        participants_per_appointment: 4,
        new_appointments: [
          [time + 3.days, time + 3.days + 1.hour],
          [time + 3.days + 1.hour, time + 3.days + 2.hours],
          [time + 3.days + 2.hours, time + 3.days + 3.hours]
        ],
        contexts: [@course]
      )

      @appointment_event = @appointment_group.appointments[0]
      @appointment = @appointment_event.reserve_for(@student, @student)

      @appointment_event2 = @appointment_group.appointments[1]
      @appointment2 = @appointment_event2.reserve_for(@student2, @student2)
    end

    it "has events for the teacher" do
      raw_api_call(:get, "/feeds/calendars/#{@teacher.feed_code}.ics", {
                     controller: "calendar_events_api", action: "public_feed", format: "ics", feed_code: @teacher.feed_code
                   })
      expect(response).to be_successful

      expect(response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip)).to match_array [
        "assignment-override-#{@override.id}",
        "calendar-event-#{@event.id}",
        "calendar-event-#{@appointment_event.id}",
        "calendar-event-#{@appointment_event2.id}"
      ]
    end

    it "has events for the student" do
      raw_api_call(:get, "/feeds/calendars/#{@student.feed_code}.ics", {
                     controller: "calendar_events_api", action: "public_feed", format: "ics", feed_code: @student.feed_code
                   })
      expect(response).to be_successful

      expect(response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip)).to match_array [
        "assignment-override-#{@override.id}", "calendar-event-#{@event.id}", "calendar-event-#{@appointment.id}"
      ]

      # make sure the assignment actually has the override date
      expected_override_date_output = @override.due_at.utc.iso8601.gsub(/[-:]/, "").gsub(/\d\dZ$/, "00Z")
      expect(response.body.match(/DTSTART:\s*#{expected_override_date_output}/)).not_to be_nil
    end

    it "has events for a merged student" do
      old_code = @student.feed_code
      new_user = user_model
      UserMerge.from(@student).into(new_user)
      raw_api_call(:get, "/feeds/calendars/#{old_code}.ics", {
                     controller: "calendar_events_api", action: "public_feed", format: "ics", feed_code: old_code
                   })
      expect(response).to be_successful

      expect(response.body.scan(/UID:\s*event-([^\n]*)/).flatten.map(&:strip)).to match_array ["assignment-override-#{@override.id}", "calendar-event-#{@event.id}", "calendar-event-#{@appointment.id}"]

      # make sure the assignment actually has the override date
      expected_override_date_output = @override.due_at.utc.iso8601.gsub(/[-:]/, "").gsub(/\d\dZ$/, "00Z")
      expect(response.body.match(/DTSTART:\s*#{expected_override_date_output}/)).not_to be_nil
    end

    it "includes the appointment details in the teachers export" do
      get "/feeds/calendars/#{@teacher.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar::Calendar.parse(response.body.dup)[0]
      appointment_text = "Unnamed Course\n" + "\n" + "Participants: \n" + "User\n" + "\n"
      expect(cal.events[1].description).to eq appointment_text
      expect(cal.events[2].description).to eq appointment_text
    end

    it "does not expose details of other students appts to a student" do
      get "/feeds/calendars/#{@user.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar::Calendar.parse(response.body.dup)[0]
      expect(cal.events[1].description).to be_nil
    end

    it "omits DTEND for all day events" do
      # assignments due at 23:59 are treated as all day events
      due_at = 1.day.from_now.end_of_day
      @course.assignments.create(title: "i am all day", due_at:)
      get "/feeds/calendars/#{@user.feed_code}.ics"
      expect(response).to be_successful
      cal = Icalendar::Calendar.parse(response.body.dup).first
      all_day_event = (cal.events.select { |e| e.summary.include? "i am all day" }).first
      expect(all_day_event.dtstart).to eq(due_at.to_date)
      expect(all_day_event.dtend).to be_nil
    end

    it "renders unauthorized feed for bad code" do
      get "/feeds/calendars/user_garbage.ics"
      expect(response).to render_template("shared/unauthorized_feed")
    end

    context "with atom" do
      before :once do
        @assignment.update(description: "assignment description")
      end

      it "does not include the assignment description if the student doesn't have permission to see it" do
        @assignment.update(unlock_at: @assignment.due_at - 1.day)
        expect(@assignment.locked_for?(@student)).to be_truthy
        raw_api_call(:get, "/feeds/calendars/#{@student.feed_code}.atom", {
                       controller: "calendar_events_api", action: "public_feed", format: "atom", feed_code: @student.feed_code
                     })
        expect(response).to be_successful
        expect(response.body).not_to include("assignment description")
      end

      it "includes the assignment description if the student has permission to see it" do
        expect(@assignment.locked_for?(@student)).to be_falsey
        raw_api_call(:get, "/feeds/calendars/#{@student.feed_code}.atom", {
                       controller: "calendar_events_api", action: "public_feed", format: "atom", feed_code: @student.feed_code
                     })
        expect(response).to be_successful
        expect(response.body).to include("assignment description")
      end
    end
  end

  context "save_selected_contexts" do
    it "persists contexts" do
      api_call(:post, "/api/v1/calendar_events/save_selected_contexts", {
                 controller: "calendar_events_api",
                 action: "save_selected_contexts",
                 format: "json",
                 selected_contexts: %w[course_1 course_2 course_3]
               })
      expect(@user.reload.get_preference(:selected_calendar_contexts)).to eq(%w[course_1 course_2 course_3])
    end
  end

  context "save_enabled_account_calendars" do
    it "persists enabled accounts" do
      api_call(:post, "/api/v1/calendar_events/save_enabled_account_calendars", {
                 controller: "calendar_events_api",
                 action: "save_enabled_account_calendars",
                 format: "json",
                 enabled_account_calendars: %w[Account.default.id]
               })

      expect(@user.reload.get_preference(:enabled_account_calendars)).to eq(%w[Account.default.id])
    end

    it "marks feature as seen" do
      api_call(:post, "/api/v1/calendar_events/save_enabled_account_calendars", {
                 controller: "calendar_events_api",
                 action: "save_enabled_account_calendars",
                 format: "json",
                 mark_feature_as_seen: true
               })

      expect(@user.reload.get_preference(:account_calendar_events_seen)).to be(true)
    end

    it "emits account_calendars.modal.enabled_calendars to statsd" do
      allow(InstStatsd::Statsd).to receive(:count)
      subaccount = Account.default.sub_accounts.create!
      api_call(:post, "/api/v1/calendar_events/save_enabled_account_calendars", {
                 controller: "calendar_events_api",
                 action: "save_enabled_account_calendars",
                 format: "json",
                 enabled_account_calendars: [Account.default.id, subaccount.id]
               })

      expect(InstStatsd::Statsd).to have_received(:count).once.with("account_calendars.modal.enabled_calendars", 2)
    end
  end

  context "visible_contexts" do
    it "includes custom colors" do
      @user.set_preference(:custom_colors, { @course.asset_string => "#0099ff" })

      json = api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                        controller: "calendar_events_api",
                        action: "visible_contexts",
                        format: "json"
                      })

      context = json["contexts"].find do |c|
        c["asset_string"] == @course.asset_string
      end
      expect(context["color"]).to eq("#0099ff")
    end

    it "includes whether the context has been selected" do
      @user.set_preference(:selected_calendar_contexts, [@course.asset_string])

      json = api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                        controller: "calendar_events_api",
                        action: "visible_contexts",
                        format: "json"
                      })

      context = json["contexts"].find do |c|
        c["asset_string"] == @course.asset_string
      end
      expect(context["selected"]).to be(true)
    end

    it "includes course sections" do
      @section = @course.course_sections.try(:first)

      json = api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                        controller: "calendar_events_api",
                        action: "visible_contexts",
                        format: "json"
                      })

      context = json["contexts"].find do |c|
        c["sections"]&.find do |s|
          s["id"] == @section.id.to_s
        end
      end
      expect(context).not_to be_nil
      expect(context["sections"][0]).to include({ "can_create_appointment_groups" => true })
    end

    it "includes can_create_appointment_groups flag" do
      student = user_factory(active_all: true)
      @course.enroll_student(student, enrollment_state: "active")

      json = api_call_as_user(student, :get, "/api/v1/calendar_events/visible_contexts", {
                                controller: "calendar_events_api",
                                action: "visible_contexts",
                                format: "json"
                              })

      student_enrollment_context = json["contexts"].find do |c|
        c["id"] == @course.id.to_s
      end

      expect(student_enrollment_context).to include({ "can_create_appointment_groups" => false })
    end

    it "excludes concluded courses" do
      json = api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                        controller: "calendar_events_api",
                        action: "visible_contexts",
                        format: "json"
                      })
      context = json["contexts"].find do |c|
        c["id"] == @course.id.to_s
      end
      expect(context).to be_present

      @course.complete!
      json = api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                        controller: "calendar_events_api",
                        action: "visible_contexts",
                        format: "json"
                      })
      context = json["contexts"].find do |c|
        c["id"] == @course.id.to_s
      end
      expect(context).not_to be_present
    end

    describe "allow_observers_in_appointment_groups" do
      let :json do
        api_call(:get, "/api/v1/calendar_events/visible_contexts", {
                   controller: "calendar_events_api",
                   action: "visible_contexts",
                   format: "json"
                 })
      end

      it "is false for contexts with the setting disabled" do
        context = json["contexts"].find { |c| c["asset_string"] == "course_#{@course.id}" }
        expect(context["allow_observers_in_appointment_groups"]).to be false
      end

      it "is false for user contexts" do
        @user.account.settings[:allow_observers_in_appointment_groups] = { value: true }
        @user.account.save!
        context = json["contexts"].find { |c| c["asset_string"] == "user_#{@user.id}" }
        expect(context["allow_observers_in_appointment_groups"]).to be false
      end

      it "is true for contexts with the setting enabled" do
        @course.account.settings[:allow_observers_in_appointment_groups] = { value: true }
        @course.account.save!
        context = json["contexts"].find { |c| c["asset_string"] == "course_#{@course.id}" }
        expect(context["allow_observers_in_appointment_groups"]).to be true
      end
    end
  end

  describe "#set_course_timetable" do
    before :once do
      @path = "/api/v1/courses/#{@course.id}/calendar_events/timetable"
      @course.start_at = DateTime.parse("2016-05-06 1:00pm -0600")
      @course.conclude_at = DateTime.parse("2016-05-19 9:00am -0600")
      @course.time_zone = "America/Denver"
      @course.save!
    end

    it "checks for valid options" do
      timetables = { "all" => [{ weekdays: "moonday", start_time: "not a real time", end_time: "this either" }] }
      json = api_call(:post,
                      @path,
                      {
                        course_id: @course.id.to_param,
                        controller: "calendar_events_api",
                        action: "set_course_timetable",
                        format: "json"
                      },
                      { timetables: },
                      {},
                      { expected_status: 400 })

      expect(json["errors"]).to match_array(["invalid start time(s)", "invalid end time(s)", "weekdays are not valid"])
    end

    it "creates course-level events" do
      location_name = "best place evr"
      timetables = { "all" => [{ weekdays: "monday, thursday",
                                 start_time: "2:00 pm",
                                 end_time: "3:30 pm",
                                 location_name: }] }

      expect do
        api_call(:post,
                 @path,
                 {
                   course_id: @course.id.to_param,
                   controller: "calendar_events_api",
                   action: "set_course_timetable",
                   format: "json"
                 },
                 { timetables: })
      end.to change(Delayed::Job, :count).by(1)

      run_jobs

      expected_events = [
        { start_at: DateTime.parse("2016-05-09 2:00 pm -0600"), end_at: DateTime.parse("2016-05-09 3:30 pm -0600") },
        { start_at: DateTime.parse("2016-05-12 2:00 pm -0600"), end_at: DateTime.parse("2016-05-12 3:30 pm -0600") },
        { start_at: DateTime.parse("2016-05-16 2:00 pm -0600"), end_at: DateTime.parse("2016-05-16 3:30 pm -0600") }
      ]
      events = @course.calendar_events.for_timetable.to_a
      expect(events.map { |e| { start_at: e.start_at, end_at: e.end_at } }).to match_array(expected_events)
      expect(events.map(&:location_name).uniq).to eq [location_name]
    end

    it "creates section-level events" do
      section1 = @course.course_sections.create!
      section2 = @course.course_sections.new
      section2.sis_source_id = "sisss" # can even find by sis id, yay!
      section2.end_at = DateTime.parse("2016-05-25 9:00am -0600") # and also extend dates on the section
      section2.save!

      timetables = {
        section1.id => [{ weekdays: "Mon", start_time: "2:00 pm", end_time: "3:30 pm" }],
        "sis_section_id:#{section2.sis_source_id}" => [{ weekdays: "Thu", start_time: "3:30 pm", end_time: "4:30 pm" }]
      }

      expect do
        api_call(:post,
                 @path,
                 {
                   course_id: @course.id.to_param,
                   controller: "calendar_events_api",
                   action: "set_course_timetable",
                   format: "json"
                 },
                 { timetables: })
      end.to change(Delayed::Job, :count).by(2)

      run_jobs

      expected_events1 = [
        { start_at: DateTime.parse("2016-05-09 2:00 pm -0600"), end_at: DateTime.parse("2016-05-09 3:30 pm -0600") },
        { start_at: DateTime.parse("2016-05-16 2:00 pm -0600"), end_at: DateTime.parse("2016-05-16 3:30 pm -0600") }
      ]
      events1 = section1.calendar_events.for_timetable.to_a
      expect(events1.map { |e| { start_at: e.start_at, end_at: e.end_at } }).to match_array(expected_events1)

      expected_events2 = [
        { start_at: DateTime.parse("2016-05-12 3:30 pm -0600"), end_at: DateTime.parse("2016-05-12 4:30 pm -0600") },
        { start_at: DateTime.parse("2016-05-19 3:30 pm -0600"), end_at: DateTime.parse("2016-05-19 4:30 pm -0600") }
      ]
      events2 = section2.calendar_events.for_timetable.to_a
      expect(events2.map { |e| { start_at: e.start_at, end_at: e.end_at } }).to match_array(expected_events2)
    end

    it "is able to retrieve the timetable afterwards" do
      timetables = { "all" => [{ weekdays: "monday, thursday", start_time: "2:00 pm", end_time: "3:30 pm" }] }

      # set the timetables
      api_call(:post,
               @path,
               {
                 course_id: @course.id.to_param,
                 controller: "calendar_events_api",
                 action: "set_course_timetable",
                 format: "json"
               },
               { timetables: })

      json = api_call(:get, @path, {
                        course_id: @course.id.to_param,
                        controller: "calendar_events_api",
                        action: "get_course_timetable",
                        format: "json"
                      })

      expected = { "all" => [{ "weekdays" => "Mon,Thu",
                               "start_time" => "2:00 pm",
                               "end_time" => "3:30 pm",
                               "course_start_at" => @course.start_at.iso8601,
                               "course_end_at" => @course.end_at.iso8601 }] }
      expect(json).to eq expected
    end
  end

  describe "#set_course_timetable_events" do
    before :once do
      @path = "/api/v1/courses/#{@course.id}/calendar_events/timetable_events"
      @events = [
        { start_at: DateTime.parse("2016-05-09 2:00 pm -0600"), end_at: DateTime.parse("2016-05-09 3:30 pm -0600") },
        { start_at: DateTime.parse("2016-05-12 2:00 pm -0600"), end_at: DateTime.parse("2016-05-12 3:30 pm -0600") },
      ]
    end

    it "is able to create a bunch of events directly from a list" do
      expect do
        api_call(:post,
                 @path,
                 {
                   course_id: @course.id.to_param,
                   controller: "calendar_events_api",
                   action: "set_course_timetable_events",
                   format: "json"
                 },
                 { events: @events })
      end.to change(Delayed::Job, :count).by(1)

      run_jobs

      events = @course.calendar_events.for_timetable.to_a
      expect(events.map { |e| { start_at: e.start_at, end_at: e.end_at } }).to match_array(@events)
    end

    it "is able to create events for a course section" do
      section = @course.course_sections.create!
      expect do
        api_call(:post,
                 @path,
                 {
                   course_id: @course.id.to_param,
                   controller: "calendar_events_api",
                   action: "set_course_timetable_events",
                   format: "json"
                 },
                 { events: @events, course_section_id: section.id.to_param })
      end.to change(Delayed::Job, :count).by(1)

      run_jobs

      events = section.calendar_events.for_timetable.to_a
      expect(events.map { |e| { start_at: e.start_at, end_at: e.end_at } }).to match_array(@events)
    end
  end
end
