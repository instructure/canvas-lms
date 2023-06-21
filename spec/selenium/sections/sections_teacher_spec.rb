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

require_relative "../common"

describe "sections" do
  include_context "in-process server selenium tests"

  context "as a teacher" do
    it "only shows users enrolled in the section on the section page" do
      course_with_teacher_logged_in(active_course: true, active_user: true)
      @section = @course.course_sections.create!
      e2 = student_in_course(active_all: true, name: "Señor Chang")
      e2.course_section = @section
      e2.save!

      get "/courses/#{@course.id}/sections/#{@section.id}"
      wait_for_ajaximations

      expect(ff("#current-enrollment-list .user").count).to eq 1
      expect(f("#enrollment_#{e2.id}")).to include_text e2.user.name

      get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
      wait_for_ajaximations

      expect(ff("#current-enrollment-list .user").count).to eq 1
      expect(f("#enrollment_#{@teacher.enrollments.first.id}")).to include_text @teacher.name
    end

    it "shows readable role types that includes custom roles" do
      course_with_teacher_logged_in(active_course: true, active_user: true)
      custom_student = user_factory(name: "Señor Chang")
      role = custom_student_role("CustomStudentRole", account: @course.account)
      @course.enroll_user(custom_student, "StudentEnrollment", role:)

      get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
      wait_for_ajaximations

      expect(f("#enrollment_#{@user.enrollments.first.id}").text).to match(/CustomStudentRole/)
    end

    it "does not include X buttons for enrollments that can't be removed" do
      course_with_teacher_logged_in(active_all: true)
      e1 = student_in_course(active_all: true, name: "Mr. Bland")
      e2 = student_in_course(active_all: true, name: "Señor Havin' A Little Trouble")
      sis = e2.course.root_account.sis_batches.create
      e2.sis_batch_id = sis.id
      e2.save!

      get "/courses/#{@course.id}/sections/#{@course.default_section.id}"
      wait_for_ajaximations

      expect(fj("#enrollment_#{e1.id} .unenroll_user_link")).not_to be_nil
      expect(f("#content")).not_to contain_css("#enrollment_#{e2.id} .unenroll_user_link")
    end
  end
end
