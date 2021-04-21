# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module CanvasSecurity
  ##
  # PageViewJwt maps standard attribues for a canvas interaction
  # to a very compact keyset to minimize size of the
  # payload.  This has been pulled out from the PageView
  # model itself because pieces of middleware need
  # to be able to expand this into the proper attribute
  # names (like RequestContextGenerator) so this mapping
  # is a different domain concept from the page view
  # model itself.
  module PageViewJwt

    ##
    # Used to generate a packaged JWT from
    # the standard attributes for a page_view.
    # @param [Hash] pv_attributes - expected to contain
    #  3 keys:
    #    - request_id [String]
    #    - user_id [Int] (global id of the user)
    #    - created_at [DateTime] (when the pageview happend)
    def self.generate(pv_attributes)
      CanvasSecurity.create_jwt({
        i: pv_attributes[:request_id],
        u: pv_attributes[:user_id],
        c: pv_attributes[:created_at].try(:utc).try(:iso8601, 2)
      })
    end

    ##
    # unpacks a pv token with abbreviated keys
    # to the original attribute set.  Reverse of ".generate".
    # the standard attributes for a page_view.
    # @param [String] token - expected to contain
    def self.decode(token)
      data = CanvasSecurity.decode_jwt(token)
      return nil unless data
      return {
        request_id: data[:i],
        user_id: data[:u],
        created_at: data[:c]
      }
    end
  end
end