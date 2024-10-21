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
class DataFixup::SetConcludedGradingSchemeIds
  def self.run
    GuardRail.activate(:primary) do
      Assignment.where(grading_standard_id: nil, grading_type: ["letter_grade", "gpa_scale"])
                .joins(:course)
                .where(courses: { grading_standard_id: nil, workflow_state: "completed" })
                .in_batches(of: 10_000).update_all(grading_standard_id: 0)
    end
  end
end
