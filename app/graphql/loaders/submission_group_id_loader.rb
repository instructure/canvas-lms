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

class Loaders::SubmissionGroupIdLoader < GraphQL::Batch::Loader
  def perform(submissions)
    mapping = Group.ids_by_student_by_assignment(*student_and_assignment_ids(submissions))
    submissions.each { |sub| fulfill(sub, mapping.dig(sub.assignment_id, sub.user_id)) }
  end

  private

  def student_and_assignment_ids(submissions)
    submissions.each_with_object([Set.new, Set.new]) do |sub, (student_ids, assignment_ids)|
      student_ids << sub.user_id
      assignment_ids << sub.assignment_id
    end
  end
end
