#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Lti
  class Link < ApplicationRecord
    belongs_to :linkable, polymorphic: [:originality_report]
    validates :vendor_code, :product_code, :resource_type_code, :resource_link_id, presence: true
    validates :resource_link_id, uniqueness: true

    before_validation :generate_resource_link_id, on: :create

    serialize :custom_parameters

    def message_handler(context)
      MessageHandler.by_resource_codes(vendor_code: vendor_code,
                                       product_code: product_code,
                                       resource_type_code: resource_type_code,
                                       context: context)
    end

    def originality_report
      if linkable.is_a?(OriginalityReport)
        linkable
      end
    end

    def generate_resource_link_id
      self.resource_link_id ||= SecureRandom.uuid
    end
  end
end
