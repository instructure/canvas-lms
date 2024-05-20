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
#

class UserLmgbOutcomeOrderings < ActiveRecord::Base
  belongs_to :usre
  belongs_to :course
  belongs_to :learning_outcome

  validates :user_id, :course_id, :learning_outcome_id, :position, presence: true

  def self.get_lmgb_outcome_ordering(user_id, course_id)
    ordering = where(user_id:, course_id:).order(:position).pluck(:learning_outcome_id, :position)

    # If the relation is empty, then return learning outcomes "as is"
    return nil if ordering.empty?

    # Format information to be cleaner and return
    ordering.map { |entry| { "outcome_id" => entry[0], "position" => entry[1] } }
  end

  def self.set_lmgb_outcome_ordering(root_account_id, user_id, course_id, outcome_position_map)
    rows = outcome_position_map.map do |entry|
      { root_account_id:, user_id:, course_id:, learning_outcome_id: entry["outcome_id"], position: entry["position"] }
    end
    transaction do
      # Remove entries from previous ordering
      # This helps keep this table up-to-date with
      #   outcomes in the course and makes sure there are
      #   no orphaned entries
      where(user_id:, course_id:).delete_all

      insert_all(rows, unique_by: :index_user_lmgb_outcome_orderings)
    end
  end
end
