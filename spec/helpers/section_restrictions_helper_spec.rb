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

require "spec_helper"

describe SectionRestrictionsHelper do
  include SectionRestrictionsHelper

  before :once do
    course_with_teacher(active_all: true)

    @section1 = @course.course_sections.create!(name: "Section 1")
    @section2 = @course.course_sections.create!(name: "Section 2")
    @section3 = @course.course_sections.create!(name: "Section 3")

    @student1 = user_factory(active_all: true, name: "Student 1")
    @student2 = user_factory(active_all: true, name: "Student 2")
    @student3 = user_factory(active_all: true, name: "Student 3")

    @course.enroll_student(@student1, section: @section1, enrollment_state: "active")
    @course.enroll_student(@student2, section: @section2, enrollment_state: "active")
    @course.enroll_student(@student3, section: @section3, enrollment_state: "active")

    @unrestricted_teacher = @teacher

    @restricted_teacher = user_factory(active_all: true, name: "Restricted Teacher")
    @course.enroll_teacher(@restricted_teacher, section: @section1, enrollment_state: "active")
    Enrollment.limit_privileges_to_course_section!(@course, @restricted_teacher, true)

    @multi_section_teacher = user_factory(active_all: true, name: "Multi Section Teacher")
    @course.enroll_teacher(@multi_section_teacher, section: @section1, enrollment_state: "active", allow_multiple_enrollments: true)
    @course.enroll_teacher(@multi_section_teacher, section: @section2, enrollment_state: "active", allow_multiple_enrollments: true)
    Enrollment.limit_privileges_to_course_section!(@course, @multi_section_teacher, true)

    @ta = user_factory(active_all: true, name: "TA")
    @course.enroll_ta(@ta, section: @section2, enrollment_state: "active")
    Enrollment.limit_privileges_to_course_section!(@course, @ta, true)
  end

  describe "#user_has_section_restrictions?" do
    it "returns false for unrestricted teachers" do
      result = user_has_section_restrictions?(@course, @unrestricted_teacher)
      expect(result).to be false
    end

    it "returns true for restricted teachers" do
      result = user_has_section_restrictions?(@course, @restricted_teacher)
      expect(result).to be true
    end

    it "returns true for restricted TAs" do
      result = user_has_section_restrictions?(@course, @ta)
      expect(result).to be true
    end

    it "returns true for multi-section restricted teachers" do
      result = user_has_section_restrictions?(@course, @multi_section_teacher)
      expect(result).to be true
    end

    it "returns false for students" do
      result = user_has_section_restrictions?(@course, @student1)
      expect(result).to be false
    end

    it "returns false when user is nil" do
      result = user_has_section_restrictions?(@course, nil)
      expect(result).to be false
    end

    it "returns false when course is nil" do
      result = user_has_section_restrictions?(nil, @restricted_teacher)
      expect(result).to be false
    end

    it "returns false when course is not a Course object" do
      account = Account.default
      result = user_has_section_restrictions?(account, @restricted_teacher)
      expect(result).to be false
    end
  end

  describe "#get_user_section_ids" do
    it "returns section IDs for single-section user" do
      section_ids = get_user_section_ids(@course, @restricted_teacher)
      expect(section_ids).to eq([@section1.id])
    end

    it "returns multiple section IDs for multi-section usre" do
      section_ids = get_user_section_ids(@course, @multi_section_teacher)
      expect(section_ids).to match_array([@section1.id, @section2.id])
    end

    it "returns empty array for users not enrolled in course" do
      other_user = user_factory(active_all: true)
      section_ids = get_user_section_ids(@course, other_user)
      expect(section_ids).to be_empty
    end

    it "excludes deleted enrollments" do
      deleted_user = user_factory(active_all: true)
      enrollment = @course.enroll_teacher(deleted_user, section: @section1, enrollment_state: "active")
      enrollment.destroy

      section_ids = get_user_section_ids(@course, deleted_user)
      expect(section_ids).to be_empty
    end

    it "excludes inactive enrollments" do
      inactive_user = user_factory(active_all: true)
      enrollment = @course.enroll_teacher(inactive_user, section: @section1, enrollment_state: "active")
      enrollment.deactivate

      section_ids = get_user_section_ids(@course, inactive_user)
      expect(section_ids).to be_empty
    end

    it "excludes completed enrollments" do
      completed_user = user_factory(active_all: true)
      enrollment = @course.enroll_teacher(completed_user, section: @section1, enrollment_state: "active")
      enrollment.complete!

      section_ids = get_user_section_ids(@course, completed_user)
      expect(section_ids).to be_empty
    end
  end

  describe "#get_visible_student_ids_in_course" do
    it "returns students from single section for restricted user" do
      student_ids = get_visible_student_ids_in_course(@course, @restricted_teacher)
      expect(student_ids).to eq([@student1.id])
    end

    it "returns students from multiple sections for multi-section user" do
      student_ids = get_visible_student_ids_in_course(@course, @multi_section_teacher)
      expect(student_ids).to match_array([@student1.id, @student2.id])
    end

    it "excludes non-student enrollment types" do
      # Enroll a teacher in the same section as the restricted teacher
      other_teacher = user_factory(active_all: true)
      @course.enroll_teacher(other_teacher, section: @section1, enrollment_state: "active")

      student_ids = get_visible_student_ids_in_course(@course, @restricted_teacher)
      expect(student_ids).not_to include(other_teacher.id)
      expect(student_ids).to eq([@student1.id])
    end
  end

  context "edge cases" do
    it "handles user with no enrollments gracefully" do
      user_with_no_enrollments = user_factory(active_all: true)

      expect(user_has_section_restrictions?(@course, user_with_no_enrollments)).to be false
      expect(get_user_section_ids(@course, user_with_no_enrollments)).to be_empty
      expect(get_visible_student_ids_in_course(@course, user_with_no_enrollments)).to be_empty
    end

    it "handles course with no sections gracefully" do
      empty_course = course_factory(active_all: true)

      expect(get_user_section_ids(empty_course, @restricted_teacher)).to be_empty
      expect(get_visible_student_ids_in_course(empty_course, @restricted_teacher)).to be_empty
    end
  end
end
