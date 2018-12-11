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

require 'active_model'

module LtiAdvantage::Models
  class DeepLinkingSetting
    include ActiveModel::Model
    include ActiveModel::Serializers::JSON

    REQUIRED_ATTRIBUTES = %i[
      accept_types
      accept_presentation_document_targets
      deep_link_return_url
    ].freeze

    TYPED_ATTRIBUTES = {
      accept_types: Array,
      accept_media_types: Array,
      accept_presentation_document_targets: Array
    }.freeze

    attr_accessor(*REQUIRED_ATTRIBUTES)
    attr_accessor :accept_media_types,
                  :accept_multiple,
                  :auto_create,
                  :data,
                  :text,
                  :title

    validates_presence_of(*REQUIRED_ATTRIBUTES)
    validates_with LtiAdvantage::TypeValidator

    def attributes
      instance_values
    end
  end
end