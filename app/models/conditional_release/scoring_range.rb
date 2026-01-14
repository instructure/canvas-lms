# frozen_string_literal: true

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
  class ScoringRange < ActiveRecord::Base
    include BoundsValidations
    include Deletion

    belongs_to :rule, optional: false
    belongs_to :root_account, class_name: "Account"
    has_many :assignment_sets, -> { active.order(position: :asc) }, inverse_of: :scoring_range, dependent: :destroy
    has_many :assignment_set_associations, -> { active.order(position: :asc) }, through: :assignment_sets
    accepts_nested_attributes_for :assignment_sets, allow_destroy: true

    before_create :set_root_account_id
    def set_root_account_id
      self.root_account_id ||= rule.root_account_id
    end

    delegate :course_id, to: :rule

    acts_as_list scope: { rule: self, deleted_at: nil }

    scope :for_score, lambda { |score|
      # Special case: if score is 1.0 (100%) and upper_bound is 1.0, include it
      # Otherwise, upper bound is exclusive (upper_bound > score)
      upper_condition = if (score * 100).round == 100
                          arel_table[:upper_bound].gteq(score).or(arel_table[:upper_bound].eq(nil))
                        else
                          arel_table[:upper_bound].gt(score).or(arel_table[:upper_bound].eq(nil))
                        end
      lower_condition = arel_table[:lower_bound].lteq(score).or(arel_table[:lower_bound].eq(nil))
      where(upper_condition.and(lower_condition))
    }

    def contains_score(score)
      return false unless score
      return false if lower_bound.present? && lower_bound > score

      # Special case: if score is 1.0 (100%) and upper_bound is 1.0, include it
      # Otherwise, upper bound is exclusive
      if (score * 100).round == 100 && upper_bound.present? && (upper_bound * 100).round == 100
        return false if upper_bound < score
      elsif upper_bound.present? && upper_bound <= score
        return false
      end

      true
    end

    def assignment_sets
      super.build if super.empty?
      super
    end
  end
end
