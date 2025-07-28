# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module LtiAdvantage::Messages
  # Class represeting an LTI 1.3 AssetProcessorSettingsRequest.
  class AssetProcessorSettingsRequest < JwtMessage
    MESSAGE_TYPE = "LtiAssetProcessorSettingsRequest"
    # Required claims for this message type
    REQUIRED_CLAIMS = (superclass::REQUIRED_CLAIMS + %i[
      activity
      context
      roles
    ]).freeze

    attr_accessor(*(REQUIRED_CLAIMS - %i[context roles activity]))

    validates_presence_of(*REQUIRED_CLAIMS)
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of AssetProcessorSettingsRequest.
    #
    # @param [Hash] attributes for message initialization.
    # @return [AssetProcessorSettingsRequest]
    def initialize(params = {})
      self.message_type = MESSAGE_TYPE
      self.version = "1.3.0"
      super
    end
  end
end
