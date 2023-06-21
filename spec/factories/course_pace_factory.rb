# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module Factories
  def course_pace_model(opts = {})
    course = opts.delete(:course) || opts[:context] || course_model(reusable: true)
    @course_pace = factory_with_protected_attributes(course.course_paces, valid_course_pace_attributes.merge(opts))
    course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
      @course_pace.course_pace_module_items.create(module_item:, duration: 0)
    end
    @course_pace
  end

  def section_pace_model(opts = {})
    section = opts.delete(:section) || opts[:context] || add_section(course_model(reusable: true))
    @section_pace = factory_with_protected_attributes(section.course.course_paces, valid_section_pace_attributes(section).merge(opts))
    section.course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
      @section_pace.course_pace_module_items.create(module_item:, duration: 0)
    end
    @section_pace
  end

  def student_enrollment_pace_model(opts = {})
    student_enrollment = opts.delete(:student_enrollment) || opts[:context] || add_section(course_model(reusable: true))
    @student_enrollment_pace = factory_with_protected_attributes(student_enrollment.course.course_paces, valid_student_enrollment_pace_attributes(student_enrollment).merge(opts))
    student_enrollment.course.context_module_tags.can_have_assignment.not_deleted.each do |module_item|
      @student_enrollment_pace.course_pace_module_items.create(module_item:, duration: 0)
    end
    @student_enrollment_pace
  end

  def valid_course_pace_attributes
    {
      workflow_state: "active",
      exclude_weekends: true,
      hard_end_dates: true,
      published_at: Time.current,
      course_section: nil,
      user: nil
    }
  end

  def valid_section_pace_attributes(section)
    {
      workflow_state: "active",
      exclude_weekends: true,
      hard_end_dates: true,
      published_at: Time.current,
      course_section: section,
      user: nil
    }
  end

  def valid_student_enrollment_pace_attributes(student_enrollment)
    {
      workflow_state: "active",
      exclude_weekends: true,
      hard_end_dates: true,
      published_at: Time.current,
      course_section: nil,
      user: student_enrollment.user
    }
  end
end
