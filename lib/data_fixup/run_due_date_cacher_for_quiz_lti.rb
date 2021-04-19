# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

module DataFixup::RunDueDateCacherForQuizLTI
  def self.run(start_at, end_at)

    # The migration will have us at most a range of 100,000 items,
    # we'll break it down to a thousand at a time here.
    Course.find_ids_in_ranges(start_at: start_at, end_at: end_at) do |batch_start, batch_end|
      courses_to_recompute =
        Course.joins(assignments: :external_tool_tag).
          joins("INNER JOIN #{ContextExternalTool.quoted_table_name} ON content_tags.content_type='ContextExternalTool' AND context_external_tools.id = content_tags.content_id").
          with_enrollments.
          not_completed.
          where(id: batch_start..batch_end, workflow_state: :available).
          merge(ContextExternalTool.quiz_lti).
          distinct

      courses_to_recompute.each { |c| DueDateCacher.recompute_course(c, run_immediately: true) }
    end
  end
end
