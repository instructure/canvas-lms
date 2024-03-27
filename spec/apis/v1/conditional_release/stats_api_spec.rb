# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require_relative "../../../conditional_release_spec_helper"
require_relative "../../api_spec_helper"

module ConditionalRelease
  describe StatsController, type: :request do
    before(:once) do
      course_with_teacher(active_all: true)
    end

    before do
      user_session(@teacher)
    end

    context "rules stats" do
      before(:once) do
        @rule = create(:rule, course: @course)
      end

      describe "GET students_per_range" do
        before :once do
          @url = "/api/v1/courses/#{@course.id}/mastery_paths/stats/students_per_range"
          @base_params = {
            controller: "conditional_release/stats",
            action: "students_per_range",
            format: "json",
            course_id: @course.id.to_s,
            trigger_assignment: @rule.trigger_assignment_id,
          }
        end

        it "requires grade viewing rights" do
          student_in_course(course: @course, active_all: true)
          api_call(:get, @url, @base_params, {}, {}, { expected_status: 401 })
        end

        it "shows stats for export" do
          expect(Stats).to receive(:students_per_range).with(@rule, false).and_return [0, 1, 2]
          json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
          expect(json).to eq [0, 1, 2]
        end

        it "includes trend if requested" do
          expect(Stats).to receive(:students_per_range).with(@rule, true).and_return [0, 1, 2]
          json = api_call(:get, @url, @base_params.merge(include: "trends"), {}, {}, { expected_status: 200 })
          expect(json).to eq [0, 1, 2]
        end

        it "requires trigger_assignment" do
          json = api_call(:get, @url, @base_params.except(:trigger_assignment), {}, {}, { expected_status: 400 })
          expect(json["message"]).to eq "trigger_assignment required"
        end
      end

      describe "GET student_details" do
        before :once do
          @url = "/api/v1/courses/#{@course.id}/mastery_paths/stats/student_details"
          student_in_course(course: @course, active_all: true)
          @user = @teacher
          @base_params = {
            controller: "conditional_release/stats",
            action: "student_details",
            format: "json",
            course_id: @course.id.to_s,
            trigger_assignment: @rule.trigger_assignment_id,
            student_id: @student.id
          }
        end

        it "requires grade viewing rights" do
          @user = @student
          api_call(:get, @url, @base_params, {}, {}, { expected_status: 401 })
        end

        it "requires a student id" do
          json = api_call(:get, @url, @base_params.except(:student_id), {}, {}, { expected_status: 400 })
          expect(json["message"]).to eq "student_id required"
        end

        it "requires trigger_assignment" do
          json = api_call(:get, @url, @base_params.except(:trigger_assignment), {}, {}, { expected_status: 400 })
          expect(json["message"]).to eq "trigger_assignment required"
        end

        it "calls into stats" do
          expect(Stats).to receive(:student_details).with(@rule, @student.id.to_s).and_return([1, 2, 3])
          json = api_call(:get, @url, @base_params, {}, {}, { expected_status: 200 })
          expect(json).to eq [1, 2, 3]
        end
      end
    end
  end
end
