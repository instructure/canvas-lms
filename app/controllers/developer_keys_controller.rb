#
# Copyright (C) 2012 Instructure, Inc.
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

class DeveloperKeysController < ApplicationController
  before_filter :set_key, only: [:update, :destroy ]
  before_filter :require_manage_developer_keys
  before_filter :set_navigation, :set_keys, :only => [:index]

  include Api::V1::DeveloperKey

  def index
    @keys = Api.paginate(@keys, self, developer_keys_url)
    respond_to do |format|
      format.html
      format.json { render :json => developer_keys_json(@keys, @current_user, session, account_context) }
    end
  end

  def create
    @key = DeveloperKey.new(params[:developer_key])
    @key.account = @context if params[:account_id]
    if @key.save
      render :json => developer_key_json(@key, @current_user, session, account_context)
    else
      render :json => @key.errors, :status => :bad_request
    end
  end

  def update
    @key.attributes = params[:developer_key]
    if @key.save
      render :json => developer_key_json(@key, @current_user, session, account_context)
    else
      render :json => @key.errors, :status => :bad_request
    end
  end

  def destroy
    @key.destroy
    render :json => developer_key_json(@key, @current_user, session, account_context)
  end

  protected
  def set_navigation
    @active_tab = 'developer_keys'
    add_crumb t('#crumbs.developer_keys', "Developer Keys")
  end

  private
  def set_key
    @key = DeveloperKey.find(params[:id])
  end

  def set_keys
    if params[:account_id]
      @keys = @context.developer_keys.preload(:account).order("id DESC")
    else
      set_site_admin_context
      @keys = DeveloperKey.preload(:account).order("id DESC")
    end
  end

  def account_context
    if params[:account_id]
      require_account_context
      return @context if @context == @domain_root_account
    elsif @key && @key.account
      return @key.account
    end

    # failover to what require_site_admin_with_permission uses
    return Account.site_admin
  end

  def require_manage_developer_keys
    require_context_with_permission(account_context, :manage_developer_keys)
  end
end
