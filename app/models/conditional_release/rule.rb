#
# Copyright (C) 2020 - present Instructure, Inc.
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

module ConditionalRelease
  class Rule < ActiveRecord::Base
    include Deletion

    validates :course_id, presence: true
    validates :trigger_assignment_id, presence: true
    belongs_to :trigger_assignment, :class_name => "Assignment"

    belongs_to :course
    has_many :scoring_ranges, -> { active.order(position: :asc) }, inverse_of: :rule, dependent: :destroy
    has_many :assignment_sets, -> { active }, through: :scoring_ranges
    has_many :assignment_set_associations, -> { active.order(position: :asc) }, through: :scoring_ranges
    accepts_nested_attributes_for :scoring_ranges, allow_destroy: true

    scope :with_assignments, -> do
      having_assignments = joins(all_includes).group(Arel.sql("conditional_release_rules.id"))
      preload(all_includes).where(id: having_assignments.pluck(:id))
    end

    def self.all_includes
      { scoring_ranges: { assignment_sets: :assignment_set_associations } }
    end

    def assignment_sets_for_score(score)
      AssignmentSet.where(scoring_range: scoring_ranges.for_score(score)).preload(:assignment_set_associations)
    end
  end
end
