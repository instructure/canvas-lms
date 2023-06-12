# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "da_homework_assignee_module"

module DifferentiatedAssignments
  module Users
    class << self
      attr_reader :first_student,
                  :second_student,
                  :third_student,
                  :fourth_student,
                  :teacher,
                  :ta,
                  :first_observer,
                  :third_observer,
                  :student_group_x,
                  :student_group_y,
                  :student_group_z

      def initialize
        @first_student   = create_user("Student1")
        @second_student  = create_user("Student2")
        @third_student   = create_user("Student3")
        @fourth_student  = create_user("Student4")
        @teacher         = create_user("Teacher1")
        @ta              = create_user("TeacherAssistant1")
        @first_observer  = create_user("Observer1")
        @third_observer  = create_user("Observer3")
        @student_group_x = create_student_group("Student Group X")
        @student_group_y = create_student_group("Student Group Y")
        @student_group_z = create_student_group("Student Group Z")
        enroll_users
      end

      def student(homework_assignee)
        case homework_assignee
        when HomeworkAssignee::Student::FIRST_STUDENT
          DifferentiatedAssignments::Users.first_student
        when HomeworkAssignee::Student::SECOND_STUDENT
          DifferentiatedAssignments::Users.second_student
        when HomeworkAssignee::Student::THIRD_STUDENT
          DifferentiatedAssignments::Users.third_student
        when HomeworkAssignee::Student::FOURTH_STUDENT
          DifferentiatedAssignments::Users.fourth_student
        end
      end

      def section(homework_assignee)
        case homework_assignee
        when HomeworkAssignee::Section::SECTION_A
          DifferentiatedAssignments::Sections.section_a
        when HomeworkAssignee::Section::SECTION_B
          DifferentiatedAssignments::Sections.section_b
        when HomeworkAssignee::Section::SECTION_C
          DifferentiatedAssignments::Sections.section_c
        end
      end

      def group(homework_assignee)
        case homework_assignee
        when HomeworkAssignee::Group::GROUP_X
          DifferentiatedAssignments::Users.student_group_x
        when HomeworkAssignee::Group::GROUP_Y
          DifferentiatedAssignments::Users.student_group_y
        when HomeworkAssignee::Group::GROUP_Z
          DifferentiatedAssignments::Users.student_group_z
        end
      end

      private

      include Factories

      def create_user(username)
        user_with_pseudonym(username:, name: username, active_all: true)
      end

      def create_student_group(group_name)
        DifferentiatedAssignments.the_course.groups.create!(name: group_name)
      end

      def enroll_users
        enroll_teacher
        enroll_ta
        enroll_students
        enroll_observers
      end

      def enroll_teacher
        DifferentiatedAssignments.the_course.enroll_teacher(teacher).accept!
      end

      def enroll_ta
        DifferentiatedAssignments.the_course.enroll_ta(ta).accept!
      end

      def enroll_students
        enroll_first_student
        enroll_second_student
        enroll_third_student
        enroll_fourth_student
      end

      def enroll_first_student
        student = first_student
        enroll_student_in_section_a(student)
        add_user_to_group(group: student_group_x, user: student, is_leader: true)
      end

      def enroll_second_student
        student = second_student
        enroll_student_in_section_b(student)
        add_user_to_group(group: student_group_x, user: student)
      end

      def enroll_third_student
        student = third_student
        enroll_student_in_section_a(student)
        enroll_student_in_section_b(student)
        add_user_to_group(group: student_group_y, user: student, is_leader: true)
      end

      def enroll_fourth_student
        student = fourth_student
        enroll_student_in_section_c(student)
        add_user_to_group(group: student_group_y, user: student)
      end

      def enroll_student_in_section_a(student)
        enroll_student_in_section(student, DifferentiatedAssignments::Sections.section_a)
      end

      def enroll_student_in_section_b(student)
        enroll_student_in_section(student, DifferentiatedAssignments::Sections.section_b)
      end

      def enroll_student_in_section_c(student)
        enroll_student_in_section(student, DifferentiatedAssignments::Sections.section_c)
      end

      def enroll_student_in_section(student, section)
        DifferentiatedAssignments.the_course.self_enroll_student(
          student,
          section:,
          allow_multiple_enrollments: true
        )
      end

      def add_user_to_group(opts)
        user = opts[:user]
        user_group = opts[:group]
        user_group.add_user user
        user_group.leader = user if opts.fetch(:is_leader, false)
        user_group.save!
      end

      def enroll_observers
        enroll_first_observer
        enroll_third_observer
      end

      def enroll_first_observer
        enroll_observer(first_observer, first_student)
      end

      def enroll_third_observer
        enroll_observer(third_observer, third_student)
      end

      def enroll_observer(an_observer, student_to_observe)
        DifferentiatedAssignments.the_course.enroll_user(
          an_observer,
          "ObserverEnrollment",
          enrollment_state: "active",
          associated_user_id: student_to_observe.id
        )
      end
    end
  end
end
