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
  # Class representing an 1EdTech Eula Message request (part of Asset Processor spec),
  # used to display an End User License Agreement to a user (often a student)
  class EulaRequest < JwtMessage
    MESSAGE_TYPE = "LtiEulaRequest"
    # Required claims for this message type
    REQUIRED_CLAIMS = (superclass::REQUIRED_CLAIMS + %i[
      eulaservice
      roles
    ]).freeze

    TYPED_ATTRIBUTES = superclass::TYPED_ATTRIBUTES.merge(
      eulaservice: LtiAdvantage::Claims::Eulaservice
    ).freeze

    validates_presence_of(*REQUIRED_CLAIMS)
    validates_with LtiAdvantage::TypeValidator

    # Returns a new instance of EulaRequest.
    #
    # @param [Hash] attributes for message initialization.
    # @return [EulaRequest]
    def initialize(params = {})
      self.message_type = MESSAGE_TYPE
      self.version = "1.3.0"
      super
    end

    def eulaservice
      @eulaservice ||= TYPED_ATTRIBUTES[:eulaservice].new
    end
  end
end
