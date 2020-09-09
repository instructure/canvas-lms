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

class OutcomeProficiencyRating < ApplicationRecord
  include Canvas::SoftDeletable
  extend RootAccountResolver

  belongs_to :outcome_proficiency, inverse_of: :outcome_proficiency_ratings

  validates :description, presence: true
  validates :points, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :color, presence: true, format: /\A([A-Fa-f0-9]{6})\z/i
  resolves_root_account through: :outcome_proficiency

  alias original_destroy destroy
  private :original_destroy
  def destroy
    if self.marked_for_destruction?
      self.destroy_permanently!
    else
      original_destroy
    end
  end

  def as_json(_options={})
    {}.tap do |h|
      h['description'] = self.description
      h['points'] = self.points
      h['mastery'] = self.mastery
      h['color'] = self.color
    end
  end
end
