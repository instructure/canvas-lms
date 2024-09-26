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

module Canvas::OAuth
  module GrantTypes
    class AuthorizationCodeWithPKCE < AuthorizationCode
      # PKCE can be used by public or confidential clients as defined in RFC 6749.
      def allow_public_client?
        true
      end

      private

      def validate_type
        unless Canvas::OAuth::PKCE.valid_code_verifier?(code: opts[:code], code_verifier: opts[:code_verifier])
          raise Canvas::OAuth::RequestError, :invalid_grant
        end

        super
      end
    end
  end
end
