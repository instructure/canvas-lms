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
  class AssignmentSetAssociation < ActiveRecord::Base
    include Deletion

    validates :assignment_id, presence: true
    validates :assignment_id, uniqueness: { scope: :assignment_set_id, conditions: -> { active } }
    validate :not_trigger
    validate :assignment_in_same_course

    acts_as_list scope: { assignment_set: self, deleted_at: nil }

    belongs_to :assignment_set, required: true
    belongs_to :assignment, class_name: "AbstractAssignment"
    has_one :scoring_range, through: :assignment_set
    has_one :rule, through: :assignment_set
    belongs_to :root_account, class_name: "Account"

    after_save :clear_caches

    before_create :set_root_account_id
    def set_root_account_id
      self.root_account_id ||= assignment_set.root_account_id
    end

    def clear_caches
      if saved_change_to_deleted_at? && assignment.deleted?
        # normally this will be cleared by the rule, but not after assignment deletion
        self.class.connection.after_transaction_commit do
          assignment.context.clear_cache_key(:conditional_release)
        end
      end
    end

    delegate :course_id, to: :rule, allow_nil: true

    private

    def not_trigger
      r = rule || assignment_set.scoring_range.rule # may not be saved yet
      if assignment_id == r.trigger_assignment_id
        errors.add(:assignment_id, "can't match rule trigger_assignment_id")
      end
    end

    def assignment_in_same_course
      r = rule || assignment_set.scoring_range.rule # may not be saved yet
      if assignment_id_changed? && assignment&.context_id != r.course_id
        errors.add(:assignment_id, "invalid assignment")
      end
    end
  end
end
