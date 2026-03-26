# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module OutcomeAlignmentsSpecHelper
  def self.mock_os_aligned_outcomes(outcomes, associated_asset_id, with_quiz: true, with_items: false, num_items: 2)
    (outcomes || []).to_h do |o|
      quiz_alignment = {
        artifact_type: "quizzes.quiz",
        artifact_id: "1",
        associated_asset_type: "canvas.assignment.quizzes",
        associated_asset_id: associated_asset_id.to_s,
        title: ""
      }
      item_alignments = (1..num_items)
                        .to_a
                        .map do |idx|
        {
          artifact_type: "quizzes.item",
          artifact_id: (100 + idx).to_s,
          associated_asset_type: "canvas.assignment.quizzes",
          associated_asset_id: associated_asset_id.to_s,
          title: "Question Number #{100 + idx}"
        }
      end
      alignments = []
      alignments << quiz_alignment if with_quiz
      alignments << item_alignments if with_items
      [o.id.to_s, alignments.flatten]
    end
  end
end
