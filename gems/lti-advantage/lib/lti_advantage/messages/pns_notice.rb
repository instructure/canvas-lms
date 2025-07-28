# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
  # Class represeting an LTI 1.3 PnsNotice.
  class PnsNotice < JwtMessage
    # Required claims for this message type
    REQUIRED_CLAIMS = (superclass::REQUIRED_CLAIMS - %i[
      target_link_uri
      message_type
    ] + %i[
      notice
    ]).freeze

    # Claims to type check
    TYPED_ATTRIBUTES = superclass::TYPED_ATTRIBUTES.merge(
      notice: LtiAdvantage::Models::PnsNoticeClaim
    ).freeze

    attr_accessor(*REQUIRED_CLAIMS)

    validates_presence_of(*REQUIRED_CLAIMS)
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of PnsNotice.
    #
    # @param [Hash] attributes for message initialization.
    # @return [PnsNotice]
    def initialize(params = {})
      self.version = "1.3.0"
      super
    end

    def notice
      @notice ||= TYPED_ATTRIBUTES[:notice].new
    end
  end
end
