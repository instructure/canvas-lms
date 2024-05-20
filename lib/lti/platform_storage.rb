# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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
  class PlatformStorage
    # This represents the name for the target browser frame for
    # Platform Storage messages and should be used when constructing the iframe.
    FORWARDING_TARGET = "post_message_forwarding"

    def self.signing_secret
      Rails.application&.credentials&.dig(:lti_platform_storage, :signing_secret)
    end
  end
end
