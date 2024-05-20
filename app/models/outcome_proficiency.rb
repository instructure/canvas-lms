# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

class OutcomeProficiency < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  def self.emit_live_events_on_any_update?
    true
  end

  has_many :outcome_proficiency_ratings,
           -> { order "points DESC, id ASC" },
           dependent: :destroy,
           inverse_of: :outcome_proficiency,
           autosave: true
  belongs_to :context, polymorphic: %i[account course], required: true

  validates :outcome_proficiency_ratings, presence: { message: t("Missing required ratings") }, unless: :deleted?
  validate :single_mastery_rating, unless: :deleted?
  validate :strictly_decreasing_points, unless: :deleted?
  validates :context, presence: true
  validates :context_id, uniqueness: { scope: :context_type }
  resolves_root_account through: :context

  before_save :detect_changes_for_rubrics
  after_save :clear_cached_proficiencies
  after_save :propagate_changes_to_rubrics

  def destroy_permanently!
    outcome_proficiency_ratings.delete_all
    super
  end

  def undestroy
    transaction do
      OutcomeProficiencyRating.where(outcome_proficiency: self).update_all(workflow_state: "active", updated_at: Time.zone.now.utc)
      reload
      super
    end
  end

  def as_json(_options = {})
    {
      "ratings" => outcome_proficiency_ratings.map(&:as_json)
    }
  end

  def replace_ratings(ratings)
    # update existing ratings & create any new ratings
    ratings.each_with_index do |val, idx|
      if idx <= outcome_proficiency_ratings.size - 1
        outcome_proficiency_ratings[idx].assign_attributes(val.to_hash.symbolize_keys)
      else
        outcome_proficiency_ratings.build(val)
      end
    end
    # delete unused ratings
    outcome_proficiency_ratings[ratings.length..].each(&:mark_for_destruction)
  end

  def ratings_hash
    outcome_proficiency_ratings.map do |rating|
      {
        points: rating.points,
        mastery: rating.mastery,
        description: rating.description,
        color: rating.color
      }
    end
  end

  def points_possible
    outcome_proficiency_ratings.first.points
  end

  def mastery_points
    outcome_proficiency_ratings.find(&:mastery).points
  end

  def self.default_ratings
    ratings = []
    ratings << { description: I18n.t("Exceeds Mastery"), points: 4, mastery: false, color: "0374B5" }
    ratings << { description: I18n.t("Mastery"), points: 3, mastery: true, color: "0B874B" }
    ratings << { description: I18n.t("Near Mastery"), points: 2, mastery: false, color: "FAB901" }
    ratings << { description: I18n.t("Below Mastery"), points: 1, mastery: false, color: "D97900" }
    ratings << { description: I18n.t("No Evidence"), points: 0, mastery: false, color: "E0061F" }
    ratings
  end

  def self.find_or_create_default!(context)
    proficiency = OutcomeProficiency.find_by(context:)
    if proficiency&.workflow_state == "active"
      return proficiency
    end

    GuardRail.activate(:primary) do
      OutcomeProficiency.transaction do
        proficiency ||= OutcomeProficiency.new(context:)
        proficiency.workflow_state = "active"
        proficiency.replace_ratings(default_ratings)
        proficiency.save!
        proficiency
      end
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  rescue ActiveRecord::RecordInvalid => e
    raise unless e.record.errors[:context_id] == ["has already been taken"]

    retry
  end

  private

  def next_ratings
    outcome_proficiency_ratings.reject(&:marked_for_destruction?)
  end

  def single_mastery_rating
    if next_ratings.count(&:mastery) != 1
      errors.add(:outcome_proficiency_ratings, t("Exactly one rating can have mastery"))
    end
  end

  def strictly_decreasing_points
    next_ratings.each_cons(2) do |l, r|
      next unless l.points <= r.points

      errors.add(
        :outcome_proficiency_ratings,
        t("Points should be strictly decreasing: %{l} <= %{r}", l: l.points, r: r.points)
      )
    end
  end

  def clear_cached_proficiencies
    if context_type == "Account"
      context.clear_downstream_caches(:resolved_outcome_proficiency)
    end
  end

  def detect_changes_for_rubrics
    @update_rubrics = changed_for_autosave?
  end

  def propagate_changes_to_rubrics
    return unless root_account.feature_enabled?(:account_level_mastery_scales)
    return unless @update_rubrics

    @update_rubrics = false

    self.class.connection.after_transaction_commit do
      delay_if_production(strand: "update_rubrics_from_mastery_scales_#{global_id}").update_associated_rubrics
    end
  end

  def update_associated_rubrics
    updateable_rubric_scopes.each do |rubric_scope|
      rubric_scope.in_batches do |batch|
        updateable = batch
                     .active
                     .aligned_to_outcomes
                     .unassessed_and_with_at_most_one_association
        updateable.each(&:update_mastery_scales)
      end
    end
  end

  def updateable_rubric_scopes
    case context_type
    when "Account"
      [
        Rubric.where(
          context_type: "Account",
          context_id: [context_id] + Account.sub_account_ids_recursive(context_id)
        ),
        Rubric.where(context: context.associated_courses)
      ]
    else
      [Rubric.where(context:)]
    end
  end
end
