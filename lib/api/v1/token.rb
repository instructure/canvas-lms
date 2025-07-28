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
#

module Api::V1::Token
  include Api::V1::Json

  def token_json(token, user, session)
    hash = api_json(token,
                    user,
                    session,
                    only: %w[id
                             created_at
                             permanent_expires_at
                             purpose
                             real_user_id
                             remember_access
                             scopes
                             updated_at
                             user_id
                             workflow_state],
                    methods: %w[app_name visible_token])
    hash[:expires_at] = hash.delete(:permanent_expires_at)
    hash[:can_manually_regenerate] = token.can_manually_regenerate?
    hash
  end
end
