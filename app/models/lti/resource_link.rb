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

class Lti::ResourceLink < ApplicationRecord
  validates :resource_link_id, presence: true

  has_many :line_items,
            inverse_of: :resource_link,
            class_name: 'Lti::LineItem',
            dependent: :destroy,
            foreign_key: :lti_resource_link_id

  before_validation :generate_resource_link_id, on: :create

  private

  def generate_resource_link_id
    self.resource_link_id ||= SecureRandom.uuid
  end
end
