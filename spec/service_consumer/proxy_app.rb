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

# ENV["RAILS_ENV"] = 'test'

class ProxyApp
  def initialize
    require ::File.expand_path('../../../config/environment', __FILE__)
    @real_provider_app = Rails.application
  end

  def call(env)
    # modify request (env) here
    # See http://www.rubydoc.info/github/rack/rack/file/SPEC for contents of the ENV
    # create a User
    AccountUser.create!(account: Account.default, user: User.create!)
    # create token
    full_token = Account.default.users.first.access_tokens.create!.full_token
    env["HTTP_AUTHORIZATION"] = "Bearer #{full_token}" if env.include?("HTTP_AUTHORIZATION")
    response = @real_provider_app.call(env)
    response
  end
end
