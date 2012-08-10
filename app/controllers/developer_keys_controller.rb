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
  before_filter :require_manage_site_settings
  before_filter :set_site_admin_context, :set_navigation, :only => [:index]
  # TODO: Make this API work for non-site-admins that want to list/manage
  # their own developer keys

  include Api::V1::DeveloperKey
  
  def require_manage_site_settings
    require_site_admin_with_permission(:manage_developer_keys)
  end

  def index
    @keys = DeveloperKey.scoped(:order => 'id DESC', :include => :account)
    @keys = Api.paginate(@keys, self, developer_keys_path)
    respond_to do |format|
      format.html
      format.json { render :json => developer_keys_json(@keys, @current_user, session) }
    end
  end
  
  def create
    @key = DeveloperKey.new(params[:developer_key])
    if @key.save
      render :json => developer_key_json(@key, @current_user, session)
    else
      render :json => @key.errors.to_json, :status => :bad_request
    end
  end
  
  def update
    @key = DeveloperKey.find(params[:id])
    @key.attributes = params[:developer_key]
    if @key.save
      render :json => developer_key_json(@key, @current_user, session)
    else
      render :json => @key.errors.to_json, :status => :bad_request
    end
  end
  
  def destroy
    @key = DeveloperKey.find(params[:id])
    @key.destroy
    render :json => developer_key_json(@key, @current_user, session)
  end
  
  protected
  def set_navigation
    @active_tab = 'developer_keys'
    add_crumb t('#crumbs.developer_keys', "Developer Keys")
  end
end
