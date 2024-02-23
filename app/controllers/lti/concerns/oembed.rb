# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

module Lti::Concerns
  module Oembed
    class OembedAuthorizationError < StandardError; end

    # Does standard JWT validation and also verifies
    # the current user is the same user that the
    # tool issued a token for
    #
    # Validating this token helps Canvas ensure that
    # an authorized tool is requesting oembed object
    # embedding.
    def validate_oembed_token!
      error_message ||= jwt_validator.error_message unless jwt_validator.valid?
      error_message = "The current user has changed" unless same_user?

      return if error_message.blank?

      log_error(error_message)
      raise OembedAuthorizationError, error_message
    end

    def log_error(message)
      logger.warn "[OEmbed] #{message}"
    end

    def jwt_validator
      @jwt_validator ||= Canvas::Security::JwtValidator.new(
        jwt: verified_jwt,
        expected_aud: Canvas::Security.config["lti_iss"],
        require_iss: true
      )
    end

    def oembed_endpoint
      uri_source[:endpoint]
    end

    def oembed_url
      uri_source[:url]
    end

    def oembed_object_uri
      URI.parse(oembed_endpoint + (oembed_endpoint.include?("?") ? "&url=" : "?url=") + CGI.escape(oembed_url) + "&format=json")
    end

    def uri_source
      verified_jwt
    end

    def associated_tool
      tool = ContextExternalTool.active.where(root_account: @domain_root_account).find_by(consumer_key: unverified_jwt[:iss])
      return tool if tool.present?

      # Could not find matching tool in the current account
      raise ActiveRecord::RecordNotFound
    end

    def current_user_lti_id
      # Use LTI 1.1 ID, but fall back on LTI 1.3
      User.find_by(lti_context_id: verified_jwt[:sub]) ||
        User.find_by(lti_id: verified_jwt[:sub])
    end

    # The subject claim of the oembed_token
    # identifies the current user at the time
    # the token was issued
    #
    # This method checks to make sure the
    # current user has not changed since the
    # token was issued
    def same_user?
      ContextExternalTool.opaque_identifier_for(@current_user, Shard.current) == verified_jwt[:sub] ||
        @current_user.lti_id == verified_jwt[:sub]
    end

    # Returns the validated oembed_token
    #
    # The secret used to sign the token
    # is the shared_secret of the tool who
    # request the oembed embedding
    def verified_jwt
      @verified_jwt ||= begin
        JSON::JWT.decode(
          params.require(:oembed_token),
          associated_tool.shared_secret
        )
      rescue JSON::JWS::VerificationFailed, JSON::JWS::UnexpectedAlgorithm
        raise OembedAuthorizationError, "Error validating oembed_token signature"
      end
    end

    def unverified_jwt
      @unverified_jwt ||= JSON::JWT.decode(params.require(:oembed_token), :skip_verification)
    end
  end
end
