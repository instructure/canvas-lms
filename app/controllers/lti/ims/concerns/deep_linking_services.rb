# frozen_string_literal: true

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

module Lti::IMS::Concerns
  module DeepLinkingServices
    CLAIM_PREFIX = "https://purl.imsglobal.org/spec/lti-dl/claim/"

    def return_url_parameters
      @return_url_parameters ||= return_url_data.data
    end

    def return_url_data
      @return_url_data ||= Lti::DeepLinkingData.from_jwt(params[:data])
    end

    def validate_return_url_data
      render_error({ errors: return_url_data.errors }) unless return_url_data.valid?
    end

    def validate_jwt
      render_error(deep_linking_jwt.errors) and return unless deep_linking_jwt.valid?
    end

    def deep_linking_jwt
      @deep_linking_jwt ||= DeepLinkingJwt.new(params[:JWT], @context)
    end

    def render_error(errors)
      InstStatsd::Statsd.increment("canvas.deep_linking_controller.request_error", tags: { code: 400 })
      render json: errors, status: :bad_request
    end

    def messaging_value(type)
      deep_linking_jwt["#{CLAIM_PREFIX}#{type}"].presence&.to_s
    end

    def content_items
      @content_items ||= deep_linking_jwt["#{CLAIM_PREFIX}content_items"] || []
    end

    def client_id
      deep_linking_jwt.developer_key
    end

    def tool
      @tool ||= ContextExternalTool.find_active_external_tool_by_client_id(client_id, @context)
    end

    def lti_resource_links
      content_items.filter { |item| item[:type] == "ltiResourceLink" }
    end

    def for_placement?(placement)
      return_url_parameters[:placement]&.to_sym == placement
    end

    class DeepLinkingJwt
      include ActiveModel::Validations

      validate :verified_jwt

      def initialize(raw_jwt_str, context)
        @raw_jwt_str = raw_jwt_str
        @context = context
      end

      delegate :[], to: :verified_jwt

      def developer_key
        @developer_key ||= DeveloperKey.find_cached(client_id)
      end

      private

      def verified_jwt
        @verified_jwt ||= begin
          jwt_hash = if developer_key&.public_jwk_url.present?
                       get_jwk_from_url
                     else
                       JSON::JWT.decode(@raw_jwt_str, public_key)
                     end
          standard_claim_errors(jwt_hash)
          developer_key_errors
          return if @errors.present? # rubocop:disable Lint/NoReturnInBeginEndBlocks

          jwt_hash
        rescue JSON::JWT::InvalidFormat
          errors.add(:jwt, "JWT format is invalid")
        rescue JSON::JWS::UnexpectedAlgorithm
          errors.add(:jwt, "JWT has unexpected alg")
        rescue JSON::JWS::VerificationFailed
          errors.add(:jwt, "JWT verification failure")
        rescue JSON::JWT::Exception
          errors.add(:jwt, "JWT exception")
        rescue ActiveRecord::RecordNotFound
          errors.add(:jwt, "Client not found")
        end
      end

      def get_jwk_from_url
        pub_jwk_from_url = HTTParty.get(developer_key&.public_jwk_url)
        JSON::JWT.decode(@raw_jwt_str, JSON::JWK::Set.new(pub_jwk_from_url.parsed_response))
      rescue JSON::JWT::Exception => e
        errors.add(:jwt, e.message)
        raise JSON::JWS::VerificationFailed
      end

      def standard_claim_errors(jwt_hash)
        hash = jwt_hash.dup

        # The nonce and jti share the same purpose here
        hash["jti"] = hash["nonce"]

        # Temporarily make the client ID the sub
        hash["sub"] = hash["iss"]

        validator = Canvas::Security::JwtValidator.new(
          jwt: hash,
          expected_aud: Canvas::Security.config["lti_iss"],
          require_iss: true,
          skip_jti_check: true
        )
        validator.validate
        validator.errors.to_h.each do |k, v|
          errors.add(k, v.to_s)
        end
      end

      def developer_key_errors
        account = @context.respond_to?(:account) ? @context.account : @context
        errors.add(:developer_key, "Developer key inactive in context") unless developer_key.binding_on_in_account?(account)
        errors.add(:developer_key, "Developer key inactive") unless developer_key.workflow_state == "active"
      end

      def client_id
        @client_id ||= JSON::JWT.decode(@raw_jwt_str, :skip_verification)["iss"]
      end

      def public_key
        @public_key ||= begin
          public_jwk = developer_key&.public_jwk
          JSON::JWK.new(public_jwk) if public_jwk.present?
        end
      end
    end
  end
end
