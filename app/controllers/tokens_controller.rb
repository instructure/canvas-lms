# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# @API Access Tokens
class TokensController < ApplicationController
  include Api::V1::Json

  before_action :require_registered_user
  before_action { |c| c.active_tab = "profile" }
  before_action :require_password_session
  before_action :require_non_masquerading, except: [:destroy, :show]

  def require_non_masquerading
    render_unauthorized_action if @real_current_user
  end

  def create
    return render_unauthorized_action unless @current_user.access_tokens.temp_record.grants_right?(@current_user, :create)

    token_params = access_token_params
    token_params[:developer_key] = DeveloperKey.default
    @token = @current_user.access_tokens.build(token_params)
    if @token.save
      render json: @token.as_json(include_root: false, methods: [:app_name, :visible_token])
    else
      render json: @token.errors, status: :bad_request
    end
  end

  def update
    return render_unauthorized_action unless @current_user.access_tokens.temp_record.grants_right?(@current_user, :update)

    @token = @current_user.access_tokens.find(params[:id])
    if @token.update(access_token_params)
      render json: @token.as_json(include_root: false, methods: [:app_name, :visible_token])
    else
      render json: @token.errors, status: :bad_request
    end
  end

  def show
    @token = @current_user.access_tokens.find(params[:id])
    render json: @token.as_json(include_root: false, methods: [:app_name, :visible_token])
  end

  #
  # @API Delete an access token
  #
  # The ID can be the actual database ID of the token, or the 'token_hint' value.
  #
  def destroy
    get_context
    if (hint = AccessToken.token_hint?(params[:id]))
      token = @context.access_tokens.find_by(token_hint: hint)
    end
    token ||= @context.access_tokens.find(params[:id])

    # this is a unique API where we check against the real current user first if masquerading,
    # since that's currently the only way that an admin can view another user's tokens at the moment
    unless (@real_current_user && token.grants_right?(@real_current_user, session, :delete)) ||
           token.grants_right?(@current_user, session, :delete)
      return render_unauthorized_action
    end

    token.destroy
    render json: api_json(token, @current_user, session)
  end

  private

  def access_token_params
    params.require(:access_token).permit(:purpose, :permanent_expires_at, :regenerate, :remember_access, scopes: [])
  end
end
