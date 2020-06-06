#
# Copyright (C) 2012 - present Instructure, Inc.
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
  before_action :set_key, only: [:update, :destroy ]
  before_action :require_manage_developer_keys

  include Api::V1::DeveloperKey

  def index
    raise ActiveRecord::RecordNotFound unless @context.root_account?
    respond_to do |format|
      format.html do
        set_navigation
        js_env(
          accountEndpoint: api_v1_account_developer_keys_path(@context),
          enableTestClusterChecks: DeveloperKey.test_cluster_checks_enabled?,
          validLtiScopes: TokenScopes::LTI_SCOPES,
          validLtiPlacements: Lti::ResourcePlacement.valid_placements(@domain_root_account),
          includesFeatureFlagEnabled: Account.site_admin.feature_enabled?(:developer_key_support_includes)
        )

        render :index_react
      end

      format.json do
        @keys = Api.paginate(index_scope, self, account_developer_keys_url(@context))
        render :json => developer_keys_json(
          @keys,
          @current_user,
          session,
          account_context,
          inherited: params[:inherited].present?,
          include_tool_config: params[:inherited].blank?
        )
      end
    end
  end

  def create
    @key = DeveloperKey.new(developer_key_params)
    @key.account = @context if params[:account_id] && @context != Account.site_admin
    if @key.save
      render :json => developer_key_json(@key, @current_user, session, account_context)
    else
      render :json => @key.errors, :status => :bad_request
    end
  end

  def update
    @key.process_event!(params[:developer_key].delete(:event)) if params[:developer_key].key?(:event)
    @key.attributes = developer_key_params unless params[:developer_key].empty?
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
    set_active_tab 'developer_keys'
    add_crumb t('#crumbs.developer_keys', "Developer Keys")
  end

  private

  def index_scope
    scope = if params[:inherited].present?
      # Return site admin keys that have been made
      # visible to inheriting accounts
      return DeveloperKey.none if @context.site_admin?
      Account.site_admin.shard.activate do
        DeveloperKey.visible.site_admin
      end
    elsif @context.site_admin?
      # Return all siteadmin keys
      if Account.site_admin.feature_enabled?(:site_admin_keys_only)
        DeveloperKey.site_admin
      else
        DeveloperKey
      end
    else
      # Only return keys that belong to the current account
      DeveloperKey.where(account_id: @context.id)
    end
    scope = scope.eager_load(:tool_configuration) unless params[:inherited]
    scope.nondeleted.preload(:account).order("developer_keys.id DESC")
  end

  def set_key
    @key = DeveloperKey.nondeleted.find(params[:id])
  end

  def account_context
    if @key
      return @key.account || Account.site_admin
    elsif params[:account_id]
      require_account_context
      return @context if context_is_domain_root_account?
    end

    # failover to what require_site_admin_with_permission uses
    return Account.site_admin
  end

  def context_is_domain_root_account?
    @context == @domain_root_account
  end

  def require_manage_developer_keys
    require_context_with_permission(account_context, :manage_developer_keys)
  end

  def developer_key_params
    params.require(:developer_key).permit(
      :auto_expire_tokens,
      :email,
      :icon_url,
      :name,
      :notes,
      :redirect_uri,
      :redirect_uris,
      :vendor_code,
      :visible,
      :test_cluster_only,
      :require_scopes,
      :allow_includes,
      scopes: []
    )
  end
end
