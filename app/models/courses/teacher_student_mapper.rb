#
# Copyright (C) 2014 Instructure, Inc.
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
  class TeacherStudentMapper
    def initialize(student_enrollments, teacher_enrollments)
      @teachers_by_students_index = index_teacher_ids_by_student_id(index_section_ids_by_students_id(student_enrollments), index_teacher_ids_by_section_id(teacher_enrollments))
    end

    def teachers_for_student(user_id)
      @teachers_by_students_index[user_id]
    end

    private

    def index_teacher_ids_by_student_id(section_ids_indexed_by_student_id, teacher_ids_indexed_by_section_id)
      teacher_ids_indexed_by_student_id = {}
      section_ids_indexed_by_student_id.each do |user_id, section_ids|
        teacher_ids_indexed_by_student_id[user_id] = []
        section_ids.each do |section_id|
          teacher_ids_indexed_by_student_id[user_id].concat(teacher_ids_indexed_by_section_id[section_id]) if teacher_ids_indexed_by_section_id[section_id]
          teacher_ids_indexed_by_student_id[user_id].concat(teacher_ids_indexed_by_section_id[:all])
        end
        teacher_ids_indexed_by_student_id[user_id].uniq!
      end

      teacher_ids_indexed_by_student_id
    end

    def index_section_ids_by_students_id(student_enrollments)
      section_ids_indexed_by_student_id = {}
      student_enrollments.each do |student_enrollment|
        section_ids_indexed_by_student_id[student_enrollment.user_id] ||= []
        section_ids_indexed_by_student_id[student_enrollment.user_id] << student_enrollment.course_section_id
      end
      section_ids_indexed_by_student_id
    end

    def index_teacher_ids_by_section_id(teacher_enrollments)
      teacher_ids_indexed_by_section_id = {}
      teacher_enrollments.each do |teacher_enrollment|
        if teacher_enrollment.limit_privileges_to_course_section
          key = teacher_enrollment.course_section_id
        else
          key = :all
        end

        teacher_ids_indexed_by_section_id[key] ||=[]
        teacher_ids_indexed_by_section_id[key] << teacher_enrollment.user_id
      end
      teacher_ids_indexed_by_section_id
    end

  end
end