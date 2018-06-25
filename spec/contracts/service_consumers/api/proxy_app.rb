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

class PactApiConsumerProxy

  AUTH_HEADER = 'HTTP_AUTHORIZATION'.freeze
  USER_ID_HEADER = 'HTTP_AUTH_USER_ID'.freeze

  def call(env)
    # Users calling the API will know the user ID of the
    # user that they want to identify as. These are given
    # in the provider state descriptions.
    if expects_auth_header(env)
      user = User.find(requesting_user_id(env))
      token = user.access_tokens.create!.full_token
      env[AUTH_HEADER] = "Bearer #{token}"
      # Unset the 'AUTH_USER_ID' header -- that's only for this proxy,
      # don't pass it along to Canvas.
      env.delete(USER_ID_HEADER)
    end

    CanvasRails::Application.call(env)
  end

  private

  def expects_auth_header(env)
    env[AUTH_HEADER]
  end

  def requesting_user_id(env)
    env[USER_ID_HEADER] || '1'
  end
end
