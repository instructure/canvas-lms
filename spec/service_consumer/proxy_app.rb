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

class ProxyApp
  def initialize(api_token=nil)
    @full_token = api_token if api_token
    require ::File.expand_path('../../../config/environment', __FILE__)
    @real_provider_app = CanvasRails::Application
  end

  def call(env)
    env["HTTP_AUTHORIZATION"] = "Bearer #{full_token}" if env.include?("HTTP_AUTHORIZATION")
    response = @real_provider_app.call(env)
    response
  end

  def full_token
    @full_token ||= create_user_account_pseudo_token(User.last.id)
  end

  def create_user_account_pseudo_token(user_id=nil, account=Account.default, _password="password1", purpose="purpose")
    AccountUser.create!(account: account, user: user_create_or_find(user_id))
    pseudonym_create
    # create token
    @user.access_tokens.create!(purpose: purpose).full_token
  end

  def user_create_or_find(user_id=nil)
    @user ||= user_id.nil? ? User.create! : User.find(user_id)
  end

  def account(account_id=nil)
    @account ||= account_id ? Account.find(account_id) : Account.default
  end

  def pseudonym_create(unique_user="admin", password="password")
    @psuedonym ||= Pseudonym.create!(user: @user,
                                     account: account,
                                     unique_id: unique_user + @user.id.to_s,
                                     password: password,
                                     password_confirmation: password)
  end
end
