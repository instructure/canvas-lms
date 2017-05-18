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

class TokensController < ApplicationController
  before_action :require_registered_user
  before_action { |c| c.active_tab = "profile" }
  before_action :require_password_session
  before_action :require_non_masquerading, :except => :show

  def require_non_masquerading
    render_unauthorized_action if @real_current_user
  end

  def create
    token_params = access_token_params
    token_params[:developer_key] = DeveloperKey.default
    @token = @current_user.access_tokens.build(token_params)
    if @token.save
      render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
    else
      render :json => @token.errors, :status => :bad_request
    end
  end

  def destroy
    @token = @current_user.access_tokens.find(params[:id])
    @token.destroy
    render :json => @token.as_json(:include_root => false)
  end

  def update
    @token = @current_user.access_tokens.find(params[:id])
    if @token.update_attributes(access_token_params)
      render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
    else
      render :json => @token.errors, :status => :bad_request
    end
  end

  def show
    @token = @current_user.access_tokens.find(params[:id])
    render :json => @token.as_json(:include_root => false, :methods => [:app_name,:visible_token])
  end

  private

  def access_token_params
    params.require(:access_token).permit(:purpose, :expires_at, :regenerate,  :remember_access, :scopes => [])
  end
end
