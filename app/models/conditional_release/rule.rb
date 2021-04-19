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
  class Rule < ActiveRecord::Base
    include Deletion

    validates :course_id, presence: true
    validates :trigger_assignment_id, presence: true
    validate :trigger_assignment_in_same_course
    belongs_to :trigger_assignment, :class_name => "Assignment"

    belongs_to :course
    belongs_to :root_account, :class_name => "Account"
    has_many :scoring_ranges, -> { active.order(position: :asc) }, inverse_of: :rule, dependent: :destroy
    has_many :assignment_sets, -> { active }, through: :scoring_ranges
    has_many :assignment_set_associations, -> { active.order(position: :asc) }, through: :scoring_ranges
    accepts_nested_attributes_for :scoring_ranges, allow_destroy: true

    after_save :clear_caches

    before_create :set_root_account_id
    def set_root_account_id
      self.root_account_id ||= course.root_account_id
    end

    def trigger_assignment_in_same_course
      if trigger_assignment_id_changed? && trigger_assignment&.context_id != course_id
        errors.add(:trigger_assignment_id, "invalid trigger assignment")
      end
    end

    scope :with_assignments, -> do
      having_assignments = joins(Rule.preload_associations).group(Arel.sql("conditional_release_rules.id"))
      preload(Rule.preload_associations).where(id: having_assignments.pluck(:id))
    end

    def self.preload_associations
      { scoring_ranges: { assignment_sets: :assignment_set_associations } }
    end

    def self.includes_for_json
      {
        scoring_ranges: {
          include: {
            assignment_sets: {
              include: {assignment_set_associations: {except: [:root_account_id, :deleted_at]}},
              except: [:root_account_id, :deleted_at]
            }
          },
          except: [:root_account_id, :deleted_at]
        }
      }
    end

    def assignment_sets_for_score(score)
      AssignmentSet.active.where(scoring_range: scoring_ranges.for_score(score))
    end

    def clear_caches
      self.class.connection.after_transaction_commit do
        self.trigger_assignment.clear_cache_key(:conditional_release)
        self.course.clear_cache_key(:conditional_release)
      end
    end

    def self.is_trigger_assignment?(assignment)
      # i'm only using the cache key currently for this one case but i figure it can be extended to handle caching around all rule data fetching
      RequestCache.cache('conditional_release_is_trigger', assignment) do
        Rails.cache.fetch_with_batched_keys('conditional_release_is_trigger', batch_object: assignment, batched_keys: :conditional_release) do
          assignment.shard.activate { self.active.where(:trigger_assignment_id => assignment).exists? }
        end
      end
    end
  end
end
