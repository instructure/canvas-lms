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

class Lti::LineItem < ApplicationRecord
  validates :score_maximum, :label, :assignment, presence: true
  validates :score_maximum, numericality: true
  validate :lti_link_id_has_one_assignment

  belongs_to :resource_link,
             inverse_of: :line_items,
             foreign_key: :lti_resource_link_id,
             class_name: 'Lti::ResourceLink'
  belongs_to :assignment,
             inverse_of: :line_items
  has_many :results,
           inverse_of: :line_item,
           class_name: 'Lti::Result',
           foreign_key: :lti_line_item_id,
           dependent: :destroy

  def assignment_line_item?
    return true if resource_link.blank?
    resource_link.line_items.order(:created_at).first.id == self.id
  end

  private

  def lti_link_id_has_one_assignment
    return if resource_link.blank?
    ids = resource_link.line_items.pluck(:assignment_id)
    return if ids.size.zero?
    return if ids.uniq.size == 1 && ids.first == assignment_id
    errors.add(:assignment, 'does not match ltiLink')
  end
end
