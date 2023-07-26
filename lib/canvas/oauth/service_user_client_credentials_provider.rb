# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module Canvas::OAuth
  class ServiceUserClientCredentialsProvider < ClientCredentialsProvider
    def initialize(...)
      @errors = []

      super
    end

    def valid?
      validate!

      errors.empty?
    end

    def generate_token
      {
        access_token: token.to_unencrypted_token_string,
        token_type: "Bearer",
        expires_in: token.jwt_payload[:exp] - token.jwt_payload[:iat],
      }
    end

    def assertion_method_permitted?
      true
    end

    def valid_scopes?
      return true unless key.require_scopes? || @scopes.present?

      super
    end

    def error_message
      errors.join(", ")
    end

    private

    def token
      InstAccess::Token.for_user(
        user_uuid: key.service_user.uuid,
        account_uuid: root_account.uuid,
        canvas_domain: host,
        user_global_id: key.service_user.global_id,
        region: ApplicationController.region,
        client_id: key.global_id,
        instructure_service: key.internal_service?
      )
    end

    def validate!
      @errors = []

      if key.nil? || !key.usable?
        errors << "Unknown client_id"
        return
      end

      if key.service_user.blank? || key.service_user.deleted?
        errors << "No active service"
      end
    end

    attr_accessor :errors
  end
end
