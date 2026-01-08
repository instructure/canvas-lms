# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

require_relative "../spec_helper"

describe PlannerController do
  include Api::V1::PlannerItem

  context "cross-shard planner items" do
    specs_require_sharding

    before :once do
      @user = User.create!(name: "Cross-Shard Student")
      @user.pseudonyms.create!(
        account: Account.default,
        unique_id: "student@test.com"
      )

      @shard1.activate do
        @cross_shard_account = Account.create!(name: "Cross-Shard Account")
        @cross_shard_course = @cross_shard_account.courses.create!(
          name: "Cross-Shard Course",
          workflow_state: "available"
        )
        @cross_shard_assignment = @cross_shard_course.assignments.create!(
          name: "Cross-Shard Assignment",
          due_at: 3.days.from_now,
          workflow_state: "published"
        )
        @cross_shard_enrollment = @cross_shard_course.enroll_student(
          @user,
          enrollment_state: "active"
        )
      end
    end

    before do
      user_session(@user)
      @user.instance_variable_set(:@cached_course_ids, nil)
      Rails.cache.clear
    end

    it "returns planner items from courses on different shards" do
      get :index,
          params: {
            start_date: 1.week.ago.iso8601,
            end_date: 1.week.from_now.iso8601
          },
          format: :json

      expect(response).to be_successful
      json = json_parse(response.body)

      expect(json.length).to eq(1)
      expect(json[0]["plannable"]["title"]).to eq("Cross-Shard Assignment")
      expect(json[0]["plannable_type"]).to eq("assignment")
    end

    it "associates user with course shard on enrollment" do
      expect(@user.associated_shards).to include(@shard1)
    end

    it "includes cross-shard course in user's course list" do
      course_ids = @user.participating_student_course_ids
      expect(course_ids).to include(@cross_shard_course.id)
    end

    it "returns planner notes from cross-shard courses" do
      @shard1.activate do
        PlannerNote.create!(
          user: @user,
          title: "Cross-Shard Note",
          todo_date: 2.days.from_now,
          course: @cross_shard_course
        )
      end

      get :index,
          params: {
            start_date: 1.week.ago.iso8601,
            end_date: 1.week.from_now.iso8601
          },
          format: :json

      expect(response).to be_successful
      json = json_parse(response.body)

      expect(json.length).to eq(2)
      plannable_types = json.pluck("plannable_type")
      expect(plannable_types).to include("assignment", "planner_note")
    end

    it "returns calendar events from cross-shard courses" do
      @shard1.activate do
        CalendarEvent.create!(
          context: @cross_shard_course,
          title: "Cross-Shard Event",
          start_at: 4.days.from_now
        )
      end

      get :index,
          params: {
            start_date: 1.week.ago.iso8601,
            end_date: 1.week.from_now.iso8601
          },
          format: :json

      expect(response).to be_successful
      json = json_parse(response.body)

      expect(json.length).to eq(2)
      plannable_types = json.pluck("plannable_type")
      expect(plannable_types).to include("assignment", "calendar_event")
    end

    it "returns items when user is enrolled in courses on multiple different shards" do
      @shard2.activate do
        @second_cross_shard_account = Account.create!(name: "Second Cross-Shard Account")
        @second_cross_shard_course = @second_cross_shard_account.courses.create!(
          name: "Second Cross-Shard Course",
          workflow_state: "available"
        )
        @second_cross_shard_assignment = @second_cross_shard_course.assignments.create!(
          name: "Second Cross-Shard Assignment",
          due_at: 5.days.from_now,
          workflow_state: "published"
        )
        @second_cross_shard_course.enroll_student(
          @user,
          enrollment_state: "active"
        )
      end

      get :index,
          params: {
            start_date: 1.week.ago.iso8601,
            end_date: 1.week.from_now.iso8601
          },
          format: :json

      expect(response).to be_successful
      json = json_parse(response.body)

      expect(json.length).to eq(2)
      titles = json.map { |item| item["plannable"]["title"] }
      expect(titles).to include("Cross-Shard Assignment", "Second Cross-Shard Assignment")
      expect(@user.associated_shards).to include(@shard1, @shard2)
    end
  end
end
