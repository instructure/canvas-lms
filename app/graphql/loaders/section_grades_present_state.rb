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
#

class Loaders::SectionGradesPresentState < GraphQL::Batch::Loader
  def initialize(assignment_id, root_account_id)
    super()
    @assignment_id = assignment_id
    @root_account_id = root_account_id
  end

  def cache_key(section)
    [self.class, @assignment_id, @root_account_id, section.id]
  end

  def perform(sections)
    assignment = Assignment.find_by!(id: @assignment_id, root_account_id: @root_account_id)

    section_course_ids = sections.map(&:course_id)
    raise ActiveRecord::RecordNotFound if section_course_ids.uniq.size > 1 || !section_course_ids.include?(assignment.context_id)

    section_grades_present_status = assignment.submissions
                                              .where(enrollments: { course_id: assignment.context_id })
                                              .joins("INNER JOIN #{Enrollment.quoted_table_name} ON submissions.user_id = enrollments.user_id")
                                              .merge(Enrollment.active.not_fake)
                                              .group("enrollments.course_section_id")
                                              .pluck("enrollments.course_section_id", Arel.sql("bool_or(submissions.excused = true OR (submissions.score IS NOT NULL AND submissions.workflow_state = 'graded'))"))
                                              .to_h
    sections.each { |section| fulfill(section, !!section_grades_present_status[section.id]) }
  end
end
