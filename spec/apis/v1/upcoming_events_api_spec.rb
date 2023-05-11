# frozen_string_literal: true

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

require_relative "../api_spec_helper"

describe UsersController, type: :request do
  include Api

  before(:once) do
    Account.find_or_create_by!(id: 0).update(name: "Dummy Root Account", workflow_state: "deleted", root_account_id: nil)
  end

  context "without current_user" do
    it "checks for auth" do
      get("/api/v1/users/self/upcoming_events")
      assert_status(401)
    end
  end

  context "with current_user" do
    before :once do
      course_with_teacher(active_all: true, user: user_with_pseudonym(active_user: true))
      @me = @user
      # course_with_student(:active_all => true)
    end

    it "gets an empty list of upcoming events" do
      json = api_call(:get,
                      "/api/v1/users/self/upcoming_events",
                      controller: "users",
                      action: "upcoming_events",
                      format: "json")
      expect(json).to eq []
    end

    context "having a calendar event on the user" do
      before do
        @user.calendar_events.create!(
          title: "Upcoming Event",
          start_at: 1.day.from_now
        ) { |c| c.context = @user }
      end

      it "gets the event" do
        json = api_call(:get,
                        "/api/v1/users/self/upcoming_events",
                        controller: "users",
                        action: "upcoming_events",
                        format: "json")
        expect(json.pluck("title")).to eq ["Upcoming Event"]
      end
    end

    context "having a calendar event and assignment on the course" do
      before do
        @course.calendar_events.create!(
          title: "Upcoming Course Event",
          start_at: 1.day.from_now
        ) { |c| c.context = @course }
        @course.assignments.create!(
          title: "Upcoming Assignment",
          points_possible: 10,
          due_at: 2.days.from_now
        )
      end

      it "gets the events" do
        json = api_call(:get,
                        "/api/v1/users/self/upcoming_events",
                        controller: "users",
                        action: "upcoming_events",
                        format: "json")
        expect(json.pluck("title")).to eq [
          "Upcoming Course Event",
          "Upcoming Assignment"
        ]
      end

      it "doesn't gets the events if the course is unpublished and the user is a teacher" do
        @course.claim!
        json = api_call(:get,
                        "/api/v1/users/self/upcoming_events",
                        controller: "users",
                        action: "upcoming_events",
                        format: "json")
        expect(json.pluck("title")).to eq [
          "Upcoming Course Event",
          "Upcoming Assignment"
        ]
      end

      it "doesn't gets the events if the course is unpublished and the user is a student" do
        student_in_course(active_all: true, course: @course)
        @course.claim!
        json = api_call(:get,
                        "/api/v1/users/self/upcoming_events",
                        controller: "users",
                        action: "upcoming_events",
                        format: "json")
        expect(json).to be_blank
      end
    end
  end
end
