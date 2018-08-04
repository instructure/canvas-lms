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
  USER_HEADER = 'HTTP_AUTH_USER'.freeze

  def call(env)
    # Users calling the API will know the user name of the
    # user that they want to identify as. For example, "Admin1".
    if expects_auth_header?(env)
      user = find_requesting_user(env)

      # You can create an access token without having a pseudonym;
      # however, when Canvas receives a request and looks up the user
      # for that access token, it expects that user to have a pseudonym.
      Pseudonym.create!(user: user, unique_id: "#{user.name}@instructure.com") if user.pseudonyms.empty?
      token = user.access_tokens.create!.full_token

      env[AUTH_HEADER] = "Bearer #{token}"
    end

    # Unset the 'AUTH_USER' header -- that's only for this proxy,
    # don't pass it along to Canvas.
    env.delete(USER_HEADER)

    CanvasRails::Application.call(env)
  end

  private

  def expects_auth_header?(env)
    env[AUTH_HEADER]
  end

  def find_requesting_user(env)
    user = User.first

    user_name = env[USER_HEADER]
    if user_name
      user = User.where(name: user_name).first
      raise "There is no user with name #{user_name}." unless user
    end

    user
  end
end
