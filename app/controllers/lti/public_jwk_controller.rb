#
# Copyright (C) 2019 - present Instructure, Inc.
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

module Lti
  class PublicJwkController < ApplicationController
    include Ims::Concerns::LtiServices
    include Api::V1::DeveloperKey

    MIME_TYPE = 'application/vnd.ims.lis.v2.publicjwk+json'.freeze

    ACTION_SCOPE_MATCHERS = {
      update: all_of(TokenScopes::LTI_UPDATE_PUBLIC_JWK_SCOPE)
    }.freeze.with_indifferent_access

    def update
      developer_key.update! public_jwk: public_jwk
      render json: developer_key_json(developer_key, @current_user, session, context), content_type: MIME_TYPE
    end

    private

    def public_jwk
      params.require(:developer_key)[:public_jwk]&.to_unsafe_h
    end

    def scopes_matcher
      ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
    end
  end
end
