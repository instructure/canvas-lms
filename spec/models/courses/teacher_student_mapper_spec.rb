# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Courses
  describe TeacherStudentMapper do
    let(:teacher_id) { 1 }
    let(:privileged_teacher_id) { 2 }
    let(:student_id) { 3 }
    let(:course_section_id_1) { 4 }
    let(:course_section_id_2) { 5 }
    let(:mock_student_enrollments) do
      [
        double(user_id: student_id, course_section_id: course_section_id_1),
        double(user_id: student_id, course_section_id: course_section_id_2)
      ]
    end
    let(:mock_teacher_enrollments) do
      [
        double(user_id: teacher_id, course_section_id: course_section_id_1, limit_privileges_to_course_section: true),
        double(user_id: teacher_id, course_section_id: course_section_id_2, limit_privileges_to_course_section: true),
        double(user_id: privileged_teacher_id, course_section_id: 99, limit_privileges_to_course_section: false),
        double(user_id: 101, course_section_id: 99, limit_privileges_to_course_section: true)
      ]
    end
    let(:mock_only_section_limited_teacher_enrollments) do
      [
        double(user_id: teacher_id, course_section_id: course_section_id_1, limit_privileges_to_course_section: true),
        double(user_id: teacher_id, course_section_id: course_section_id_2, limit_privileges_to_course_section: true),
      ]
    end

    describe "#teachers_for_student" do
      it "returns teacher ids for a given student id" do
        teacher_student_mapper = TeacherStudentMapper.new(mock_student_enrollments, mock_teacher_enrollments)
        expect(teacher_student_mapper.teachers_for_student(student_id)).to match_array [teacher_id, privileged_teacher_id]
      end

      it "works even if all teachers are section limited" do
        teacher_student_mapper = TeacherStudentMapper.new(
          mock_student_enrollments,
          mock_only_section_limited_teacher_enrollments
        )
        expect(teacher_student_mapper.teachers_for_student(student_id)).to match_array [teacher_id]
      end
    end
  end
end
