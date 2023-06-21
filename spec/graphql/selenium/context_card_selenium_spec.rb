# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative "../../selenium/common"

describe "graphql student context cards" do
  include_context "in-process server selenium tests"

  def add_enrollment(enrollment_state, section)
    enrollment = student_in_course(workflow_state: enrollment_state, course_section: section)
    enrollment.accept! if ["active", "completed"].include? enrollment_state
  end

  def grade_assignment(course, student, grader)
    @ass = course.assignments.create!({
                                        title: "some assignment",
                                        submission_types: "online_url,online_upload"
                                      })
    @ass.submit_homework(student, {
                           submission_type: "online_url",
                           url: "http://www.google.com"
                         })
    @ass.grade_student(student, grade: 5, grader:)
  end

  context "with graphql enabled as a teacher" do
    before do
      course_with_teacher_logged_in
      @section = @course.default_section
      add_enrollment("active", @section)
      grade_assignment(@course, @student, @teacher)
    end

    it "pulls student context card data from graphql", priority: "2" do
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Header__Name h2 a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/users/#{@student.id}")
    end

    it "links to student submissions page", priority: "2" do
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Progress__Bar a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/assignments/#{@ass.id}/submissions/#{@student.id}")
    end

    it "links to grades page", priority: "2" do
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-QuickLinks a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/grades/#{@student.id}")
    end
  end

  context "with graphql enabled as an admin" do
    before do
      course_with_admin_logged_in
      @section = @course.default_section
      add_enrollment("active", @section)
      grade_assignment(@course, @student, @admin)
    end

    it "pulls student context card data from graphql on gradebook page", priority: "2" do
      get "/courses/#{@course.id}/gradebook"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Header__Name h2 a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/users/#{@student.id}")
    end

    it "shoulds pull student context card data from graphql on sections page", priority: "2" do
      get "/courses/#{@course.id}/sections/#{@section.id}"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Header__Name h2 a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/users/#{@student.id}")
    end

    it "shoulds pull student context card data from graphql on people page", priority: "2" do
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Header__Name h2 a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/users/#{@student.id}")
    end

    it "links to student submissions page", priority: "2" do
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-Progress__Bar a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/assignments/#{@ass.id}/submissions/#{@student.id}")
    end

    it "links to grades page", priority: "2" do
      get "/courses/#{@course.id}/users"
      wait_for_ajaximations
      f("a[data-student_id='#{@student.id}']").click
      wait_for_ajaximations
      expect(f(".StudentContextTray-Header__Name h2 a")).to include_text("User")
      cool_link = f(".StudentContextTray-QuickLinks a")
      expect(cool_link["href"]).to include("/courses/#{@course.id}/grades/#{@student.id}")
    end
  end
end
