# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class Loaders::SectionGradePostedState < GraphQL::Batch::Loader
  def initialize(assignment_id, root_account_id)
    super()
    @assignment_id = assignment_id
    @root_account_id = root_account_id
  end

  def perform(sections)
    assignment = Assignment.find_by!(id: @assignment_id, root_account_id: @root_account_id)

    section_course_ids = sections.map(&:course_id)
    raise ActiveRecord::RecordNotFound if section_course_ids.uniq.size > 1 || !section_course_ids.include?(assignment.context_id)

    section_grade_post_status = assignment.submissions
                                          .where(enrollments: { course_id: assignment.context_id })
                                          .joins("INNER JOIN #{Enrollment.quoted_table_name} ON submissions.user_id = enrollments.user_id")
                                          .merge(Enrollment.active)
                                          .group("enrollments.course_section_id")
                                          .pluck("enrollments.course_section_id", Arel.sql("bool_and(submissions.posted_at IS NOT NULL)"))
                                          .to_h
    sections.each { |section| fulfill(section, section_grade_post_status.fetch(section.id, false)) }
  end
end
