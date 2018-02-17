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

  belongs_to :resource_link,
             inverse_of: :line_items,
             foreign_key: :lti_resource_link_id,
             class_name: 'Lti::ResourceLink'
  belongs_to :assignment, inverse_of: :line_items
  has_many :results,
           inverse_of: :line_item,
           class_name: 'Lti::Result',
           foreign_key: :lti_line_item_id,
           dependent: :destroy
end
