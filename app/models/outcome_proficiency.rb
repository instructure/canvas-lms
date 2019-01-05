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
  has_many :outcome_proficiency_ratings, -> { order 'points DESC, id ASC' },
    dependent: :destroy, inverse_of: :outcome_proficiency, autosave: true
  belongs_to :account, inverse_of: :outcome_proficiency

  validates :account, uniqueness: true, presence: true
  validates :outcome_proficiency_ratings, presence: { message: t('Missing required ratings') }
  validate :single_mastery_rating
  validate :strictly_decreasing_points

  def as_json(_options={})
    {
      'ratings' => self.outcome_proficiency_ratings.map(&:as_json)
    }
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
