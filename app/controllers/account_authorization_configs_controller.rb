#
# Copyright (C) 2011 Instructure, Inc.
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

class AccountAuthorizationConfigsController < ApplicationController
  before_filter :require_context, :require_root_account_management

  def show
    @account_config = @account.account_authorization_config
    @account_config ||= @account.build_account_authorization_config
    @saml_identifiers = Onelogin::Saml::NameIdentifiers::ALL_IDENTIFIERS
    @accounts = []
  end

  def create
    @account_config = @account.build_account_authorization_config(params[:account_authorization_config])
    if @account_config.save
      render :json => @account_config.to_json
    else
      render :json => @account_config.errors.to_json
    end
  end

  def update
    @account_config = @account.account_authorization_config
    if @account_config.update_attributes(params[:account_authorization_config])
      render :json => @account_config.to_json
    else
      render :json => @@account_config.errors.to_json
    end
  end

  def destroy
    @account_config = @account.account_authorization_config
    @account_config.destroy
    redirect_to :account_account_authorization_config
  end
end
