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
  self.ignored_columns = %i[account_id]

  def self.emit_live_events_on_any_update?
    true
  end

  has_many :outcome_proficiency_ratings, -> { order 'points DESC, id ASC' },
    dependent: :destroy, inverse_of: :outcome_proficiency, autosave: true
  belongs_to :context, polymorphic: %i[account course], required: true

  validates :outcome_proficiency_ratings, presence: { message: t('Missing required ratings') }, unless: :deleted?
  validate :single_mastery_rating, unless: :deleted?
  validate :strictly_decreasing_points, unless: :deleted?
  validates :context, presence: true
  validates :context_id, uniqueness: { scope: :context_type }
  resolves_root_account through: :context

  alias original_destroy_permanently! destroy_permanently!
  private :original_destroy_permanently!
  def destroy_permanently!
    self.outcome_proficiency_ratings.delete_all
    original_destroy_permanently!
  end

  alias original_undestroy undestroy
  private :original_undestroy
  def undestroy
    transaction do
      OutcomeProficiencyRating.where(outcome_proficiency: self).update_all(workflow_state: 'active', updated_at: Time.zone.now.utc)
      self.reload
      original_undestroy
    end
  end

  def as_json(_options={})
    {
      'ratings' => self.outcome_proficiency_ratings.map(&:as_json)
    }
  end

  def replace_ratings(ratings)
    # update existing ratings & create any new ratings
    ratings.each_with_index do |val, idx|
      if idx <= outcome_proficiency_ratings.count - 1
        outcome_proficiency_ratings[idx].assign_attributes(val.to_hash.symbolize_keys)
      else
        outcome_proficiency_ratings.build(val)
      end
    end
    # delete unused ratings
    outcome_proficiency_ratings[ratings.length..-1].each(&:mark_for_destruction)
  end

  def ratings_hash
    outcome_proficiency_ratings.map do |rating|
      {
        points: rating.points,
        mastery: rating.mastery,
        description: rating.description
      }
    end
  end

  def points_possible
    outcome_proficiency_ratings.first.points
  end

  def mastery_points
    outcome_proficiency_ratings.where(mastery: true).first.points
  end

  private

  def next_ratings
    self.outcome_proficiency_ratings.reject(&:marked_for_destruction?)
  end

  def single_mastery_rating
    if next_ratings.count(&:mastery) != 1
      self.errors.add(:outcome_proficiency_ratings, t('Exactly one rating can have mastery'))
    end
  end

  def strictly_decreasing_points
    next_ratings.each_cons(2) do |l, r|
      if l.points <= r.points
        self.errors.add(:outcome_proficiency_ratings,
          t("Points should be strictly decreasing: %{l} <= %{r}", l: l.points, r: r.points))
      end
    end
  end
end
