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

# Shared utilities for the opaque data stored in the deep linking return url.
# This data is stored in JWT form to prevent tampering with the parameters that
# the DeepLinkingController requires to successfully process content items, and
# ensures that each deep linking launch can only create content items once.
module Lti
  module DeepLinkingData
    ERROR_TYPES = {
      presence_required: "Do not modify the deep_link_return_url in any way.",
      invalid_or_malformed: "Do not modify the deep_link_return_url in any way.",
      already_used: "Do not attempt to submit content items multiple times.",
    }.freeze

    # Returns a JWT string created from the `data` hash parameter, and some sane
    # defaults used in validating the JWT during the deep linking response.
    #
    # This JWT can only be used once. It is meant to be used only in constructing
    # the `deep_link_return_url`, used in LTI 1.3 deep linking launches.
    #
    # @param [Hash] data to include in the JWT
    # @return [String] the encoded JWT string
    def self.jwt_from(data)
      default_data = {
        nonce: SecureRandom.uuid
      }
      CanvasSecurity.create_jwt(default_data.merge(data))
    end

    # Returns a TokenData object created from the `jwt` JWT string parameter,
    # and validates that the JWT is correctly formed, has not expired, and has
    # not already been used.
    #
    # This data is only meant to be consumed by the DeepLinkingController as it
    # processes content items from an LTI 1.3 deep linking launch.
    #
    # @param [String] jwt the raw JWT string
    # @return [TokenData] the payload of the JWT and any validation errors
    def self.from_jwt(jwt)
      unless jwt.present?
        return TokenData.new({}, format_error(:presence_required))
      end

      data = begin
        CanvasSecurity.decode_jwt(jwt, ignore_expiration: true)
      rescue CanvasSecurity::InvalidToken
        nil
      end

      unless data.present?
        return TokenData.new({}, format_error(:invalid_or_malformed))
      end

      nonce_key = "nonce:deep_linking_response:#{data[:nonce]}"
      unless Lti::Security.check_and_store_nonce(nonce_key, Time.zone.now, 1.hour)
        return TokenData.new({}, format_error(:already_used))
      end

      TokenData.new(data.except(:nonce), nil)
    end

    TokenData = Struct.new(:data, :errors) do
      def valid?
        errors.nil?
      end
    end

    # Returns a JSON error structured like the errors
    # that are built by ActiveModel::Validations, to
    # match other errors returned in the API
    def self.format_error(type)
      {
        data_jwt: [
          {
            attribute: "?data=JWT",
            type:,
            message: ERROR_TYPES[type]
          }
        ]
      }
    end
  end
end
