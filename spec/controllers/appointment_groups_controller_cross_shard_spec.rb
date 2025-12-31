# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../apis/api_spec_helper"

describe AppointmentGroupsController, type: :request do
  specs_require_sharding

  before :once do
    @shard1.activate do
      @user = user_with_pseudonym(active_all: true)
    end

    @shard2.activate do
      @account = Account.create!
      @course = @account.courses.create!
      @course.offer!
      @course.enroll_student(@user, enrollment_state: "active")

      @ag = AppointmentGroup.create!(
        title: "Cross-Shard Appointment",
        contexts: [@course],
        new_appointments: [
          ["#{Time.zone.now.year + 1}-01-01 12:00:00",
           "#{Time.zone.now.year + 1}-01-01 13:00:00"]
        ]
      )
      @ag.publish!
    end
  end

  describe "GET 'index' with scope=reservable" do
    it "returns appointment groups from other shards" do
      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable" }
        )

        expect(json.size).to eq(1)
        expect(json.first["id"]).to eq(@ag.id)
        expect(json.first["title"]).to eq("Cross-Shard Appointment")
      end
    end

    it "filters by context_codes across shards" do
      @shard1.activate do
        @account1 = Account.create!
        @course1 = @account1.courses.create!
        @course1.offer!
        @course1.enroll_student(@user, enrollment_state: "active")

        @ag1 = AppointmentGroup.create!(
          title: "Same-Shard Appointment",
          contexts: [@course1],
          new_appointments: [
            ["#{Time.zone.now.year + 1}-01-01 14:00:00",
             "#{Time.zone.now.year + 1}-01-01 15:00:00"]
          ]
        )
        @ag1.publish!

        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&context_codes[]=course_#{@course.id}",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            context_codes: ["course_#{@course.id}"] }
        )

        expect(json.size).to eq(1)
        expect(json.first["id"]).to eq(@ag.id)
        expect(json.first["title"]).to eq("Cross-Shard Appointment")
      end
    end

    it "returns appointment groups from multiple shards when filtering by multiple context codes" do
      @shard1.activate do
        @account1 = Account.create!
        @course1 = @account1.courses.create!
        @course1.offer!
        @course1.enroll_student(@user, enrollment_state: "active")

        @ag1 = AppointmentGroup.create!(
          title: "Same-Shard Appointment",
          contexts: [@course1],
          new_appointments: [
            ["#{Time.zone.now.year + 1}-01-01 14:00:00",
             "#{Time.zone.now.year + 1}-01-01 15:00:00"]
          ]
        )
        @ag1.publish!

        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&context_codes[]=course_#{@course.id}&context_codes[]=course_#{@course1.id}",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            context_codes: ["course_#{@course.id}", "course_#{@course1.id}"] }
        )

        expect(json.size).to eq(2)
        titles = json.pluck("title")
        expect(titles).to contain_exactly("Cross-Shard Appointment", "Same-Shard Appointment")
      end
    end

    it "returns no appointment groups when filtering by non-existent context" do
      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&context_codes[]=course_999999",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            context_codes: ["course_999999"] }
        )

        expect(json.size).to eq(0)
      end
    end
  end

  describe "GET 'index' with scope=manageable" do
    it "returns manageable appointment groups from other shards" do
      @shard2.activate do
        @course.enroll_teacher(@user, enrollment_state: "active")
      end

      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=manageable",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "manageable" }
        )

        expect(json.size).to eq(1)
        expect(json.first["id"]).to eq(@ag.id)
        expect(json.first["title"]).to eq("Cross-Shard Appointment")
      end
    end

    it "filters manageable appointment groups by context_codes across shards" do
      @shard2.activate do
        @course.enroll_teacher(@user, enrollment_state: "active")
      end

      @shard1.activate do
        @account1 = Account.create!
        @course1 = @account1.courses.create!
        @course1.offer!
        @course1.enroll_teacher(@user, enrollment_state: "active")

        @ag1 = AppointmentGroup.create!(
          title: "Same-Shard Manageable Appointment",
          contexts: [@course1],
          new_appointments: [
            ["#{Time.zone.now.year + 1}-01-01 14:00:00",
             "#{Time.zone.now.year + 1}-01-01 15:00:00"]
          ]
        )
        @ag1.publish!

        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=manageable&context_codes[]=course_#{@course.id}",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "manageable",
            context_codes: ["course_#{@course.id}"] }
        )

        expect(json.size).to eq(1)
        expect(json.first["id"]).to eq(@ag.id)
        expect(json.first["title"]).to eq("Cross-Shard Appointment")
      end
    end
  end

  describe "pagination across shards" do
    it "paginates correctly with appointment groups on multiple shards" do
      @shard1.activate do
        @account1 = Account.create!
        @course1 = @account1.courses.create!
        @course1.offer!
        @course1.enroll_student(@user, enrollment_state: "active")

        5.times do |i|
          ag = AppointmentGroup.create!(
            title: "Shard1 AG #{i}",
            contexts: [@course1],
            new_appointments: [
              ["#{Time.zone.now.year + 1}-01-#{i + 1} 12:00:00",
               "#{Time.zone.now.year + 1}-01-#{i + 1} 13:00:00"]
            ]
          )
          ag.publish!
        end
      end

      @shard2.activate do
        5.times do |i|
          ag = AppointmentGroup.create!(
            title: "Shard2 AG #{i}",
            contexts: [@course],
            new_appointments: [
              ["#{Time.zone.now.year + 1}-02-#{i + 1} 12:00:00",
               "#{Time.zone.now.year + 1}-02-#{i + 1} 13:00:00"]
            ]
          )
          ag.publish!
        end
      end

      @shard1.activate do
        json1 = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&per_page=5",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            per_page: "5" }
        )

        expect(json1.size).to eq(5)

        links = Api.parse_pagination_links(response.headers["Link"])
        next_link = links.detect { |p| p[:rel] == "next" }
        expect(next_link).to be_present

        json2 = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            per_page: "5",
            page: next_link["page"] }
        )

        expect(json2.size).to be >= 5

        # Verify no duplicates across pages
        all_ids = (json1 + json2).pluck("id")
        expect(all_ids.uniq.size).to eq(all_ids.size)
      end
    end
  end

  describe "include parameters" do
    it "preloads associations correctly across shards" do
      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&include[]=appointments&include[]=participant_count",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            include: %w[appointments participant_count] }
        )

        expect(json.size).to eq(1)
        expect(json.first["appointments"]).to be_present
        expect(json.first["appointments"].size).to eq(1)
        expect(json.first["participant_count"]).to eq(0)
      end
    end
  end

  describe "date filtering across shards" do
    it "respects include_past_appointments parameter for reservable appointments" do
      @shard2.activate do
        @past_ag = AppointmentGroup.create!(
          title: "Past Appointment",
          contexts: [@course],
          new_appointments: [
            ["#{Time.zone.now.year - 1}-01-01 12:00:00",
             "#{Time.zone.now.year - 1}-01-01 13:00:00"]
          ]
        )
        @past_ag.publish!
      end

      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable" }
        )

        expect(json.pluck("title")).not_to include("Past Appointment")

        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=reservable&include_past_appointments=true",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "reservable",
            include_past_appointments: "true" }
        )

        expect(json.pluck("title")).to include("Past Appointment")
      end
    end

    it "respects include_past_appointments parameter for manageable appointments" do
      @shard2.activate do
        @course.enroll_teacher(@user, enrollment_state: "active")

        @past_ag = AppointmentGroup.create!(
          title: "Past Manageable Appointment",
          contexts: [@course],
          new_appointments: [
            ["#{Time.zone.now.year - 1}-01-01 12:00:00",
             "#{Time.zone.now.year - 1}-01-01 13:00:00"]
          ]
        )
        @past_ag.publish!
      end

      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups?scope=manageable",
          { controller: "appointment_groups",
            action: "index",
            format: "json",
            scope: "manageable" }
        )

        expect(json).to be_an(Array)
      end
    end
  end

  describe "GET 'next_appointment'" do
    it "finds next appointment across shards" do
      @shard1.activate do
        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups/next_appointment?appointment_group_ids[]=#{@ag.id}",
          { controller: "appointment_groups",
            action: "next_appointment",
            format: "json",
            appointment_group_ids: [@ag.id.to_s] }
        )

        expect(json).to be_an(Array)
        expect(json.size).to eq(1)
        expect(json.first["appointment_group_id"]).to eq("#{@ag.shard.id}~#{@ag.local_id}")
        expect(json.first["start_at"]).to be_present
      end
    end

    it "finds next appointment across multiple shards with multiple appointment group IDs" do
      @shard1.activate do
        @account1 = Account.create!
        @course1 = @account1.courses.create!
        @course1.offer!
        @course1.enroll_student(@user, enrollment_state: "active")

        @ag1 = AppointmentGroup.create!(
          title: "Same-Shard Appointment",
          contexts: [@course1],
          new_appointments: [
            ["#{Time.zone.now.year + 1}-01-02 14:00:00",
             "#{Time.zone.now.year + 1}-01-02 15:00:00"]
          ]
        )
        @ag1.publish!

        json = api_call_as_user(
          @user,
          :get,
          "/api/v1/appointment_groups/next_appointment?appointment_group_ids[]=#{@ag.id}&appointment_group_ids[]=#{@ag1.id}",
          { controller: "appointment_groups",
            action: "next_appointment",
            format: "json",
            appointment_group_ids: [@ag.id.to_s, @ag1.id.to_s] }
        )

        expect(json).to be_an(Array)
        expect(json.size).to eq(1)
        expect(json.first["appointment_group_id"]).to eq("#{@ag.shard.id}~#{@ag.local_id}")
      end
    end
  end

  describe "POST 'reserve' across shards" do
    it "allows student to reserve appointment on different shard" do
      @shard2.activate do
        @appointment = @ag.appointments.first
      end

      @shard1.activate do
        json = api_call_as_user(
          @user,
          :post,
          "/api/v1/calendar_events/#{@appointment.id}/reservations",
          { controller: "calendar_events_api",
            action: "reserve",
            format: "json",
            id: @appointment.id.to_s }
        )

        expect(response).to be_successful
        expect(json["appointment_group_id"]).to eq("#{@ag.shard.id}~#{@ag.local_id}")
        expect(json["parent_event_id"]).to eq("#{@appointment.shard.id}~#{@appointment.local_id}")
      end
    end

    it "returns 403 when appointment group is not eligible for user" do
      @shard2.activate do
        @appointment = @ag.appointments.first
        @other_course = @account.courses.create!
        @other_course.offer!

        @ag_other = AppointmentGroup.create!(
          title: "Other Course Appointment",
          contexts: [@other_course],
          new_appointments: [
            ["#{Time.zone.now.year + 1}-01-01 14:00:00",
             "#{Time.zone.now.year + 1}-01-01 15:00:00"]
          ]
        )
        @ag_other.publish!
        @other_appointment = @ag_other.appointments.first
      end

      @shard1.activate do
        api_call_as_user(
          @user,
          :post,
          "/api/v1/calendar_events/#{@other_appointment.id}/reservations",
          { controller: "calendar_events_api",
            action: "reserve",
            format: "json",
            id: @other_appointment.id.to_s },
          {},
          {},
          { expected_status: 403 }
        )
      end
    end
  end
end
