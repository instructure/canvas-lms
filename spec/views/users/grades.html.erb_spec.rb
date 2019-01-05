#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../views_helper"

describe "users/grades" do
  context "as a teacher" do
    let_once(:course) { Course.create!(workflow_state: "available") }
    let_once(:student) { course_with_user("StudentEnrollment", course: course, active_all: true).user }
    let_once(:teacher) { course_with_user("TeacherEnrollment", course: course, active_all: true).user }
    let(:student_enrollment) { course.enrollments.find_by(user: student) }

    it "shows the computed score, even if override scores exist and feature is enabled" do
      course.enable_feature!(:final_grades_override)
      view_context(course, teacher)
      student_enrollment.scores.create!(course_score: true, current_score: 73.0, override_score: 89.2)
      current_active_enrollments = teacher.
        enrollments.
        current.
        preload(:course, :enrollment_state, :scores).
        shard(teacher).
        to_a
      presenter = GradesPresenter.new(current_active_enrollments)
      assign(:presenter, presenter)
      render "users/grades"
      expect(Nokogiri::HTML(response.body).css('.teacher_grades .percent').text).to include "73.00%"
    end
  end
end
