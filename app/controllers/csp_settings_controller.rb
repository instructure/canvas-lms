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
#

# @API Content Security Policy Settings
# @beta
#
# API for enabling/disabling the use of Content Security Policy headers and
# configuring whitelisted domains

class CspSettingsController < ApplicationController
  before_action :require_context, :require_user, :require_permissions
  before_action :get_domain, :only => [:add_domain, :remove_domain]

  # @API Get current settings for account or course
  #
  # Update multiple modules in an account.
  #
  # @response_field enabled Whether CSP is enabled.
  # @response_field inherited Whether the current CSP settings are inherited from a parent account.
  # @response_field effective_whitelist If enabled, lists the currently whitelisted domains
  #   (includes domains automatically whitelisted through external tools).
  # @response_field tools_whitelist (Account-only) Lists the automatically whitelisted domains with
  #   their respective external tools
  # @response_field current_account_whitelist (Account-only) Lists the current list of domains
  #   explicitly whitelisted by this account. (Note: this list will not take effect unless
  #   CSP is explicitly enabled on this account)
  def get_csp_settings
    render :json => csp_settings_json
  end

  # @API Enable, disable, or clear explicit CSP setting
  #
  # Either explicitly sets CSP to be on or off for courses and sub-accounts,
  # or clear the explicit settings to default to those set by a parent account
  #
  # @argument status [Required, String, "enabled"|"disabled"|"inherited"]
  #   If set to "enabled" for an account, CSP will be enabled for all its courses and sub-accounts (that
  #   have not explicitly enabled or disabled it), using the domain whitelist set on this account.
  #   If set to "disabled", CSP will be disabled for this account or course and for all sub-accounts
  #   that have not explicitly re-enabled it.
  #   If set to "inherited", this account or course will reset to the default state where CSP settings
  #   are inherited from the first parent account to have them explicitly set.
  #
  def set_csp_setting
    case params[:status]
    when "enabled"
      if @context.is_a?(Course)
        if @context.account.csp_enabled?
          @context.inherit_csp! # just un-disable
        else
          return render :json => {:message => "must be enabled on account-level first"}, :status => :bad_request
        end
      else
        @context.enable_csp!
      end
    when "disabled"
      @context.disable_csp!
    when "inherited"
      @context.inherit_csp!
    else
      return render :json => {:message => "invalid setting"}, :status => :bad_request
    end
    render :json => csp_settings_json
  end

  # @API Add a domain to account whitelist
  #
  # Adds a domain to the whitelist for the current account. Note: this will not take effect
  # unless CSP is explicitly enabled on this account.
  #
  # @argument domain [Required, String]
  def add_domain
    if @context.add_domain!(@domain)
      render :json => {:current_account_whitelist => @context.csp_domains.active.pluck(:domain).sort}
    else
      render :json => {:message => "invalid domain"}, :status => :bad_request
    end
  end

  # @API Remove a domain from account whitelist
  #
  # Removes a domain from the whitelist for the current account.
  #
  # @argument domain [Required, String]
  def remove_domain
    @context.remove_domain!(@domain)
    render :json => {:current_account_whitelist => @context.csp_domains.active.pluck(:domain).sort}
  end

  protected
  def require_permissions
    account = @context.is_a?(Course) ? @context.account : @context
    !!authorized_action(account, @current_user, :manage_account_settings)
  end

  def get_domain
    @domain = params.require(:domain)
    unless @domain.is_a?(String) # could do stricter checking someday maybe
      render :json => {:message => "invalid domain"}, :status => :bad_request
      return false
    end
    @domain
  end

  def csp_settings_json
    json = {
      :enabled => @context.csp_enabled?,
      :inherited => @context.csp_inherited?,
    }
    json[:effective_whitelist] = @context.csp_whitelisted_domains if @context.csp_enabled?
    if @context.is_a?(Account)
      tools_whitelist = {}
      @context.csp_tools_grouped_by_domain.each do |domain, tools|
        tools_whitelist[domain] = tools.map do |tool|
          {:id => tool.id, :name => tool.name, :account_id => tool.context_id}
        end
      end
      json[:tools_whitelist] = tools_whitelist
      json[:current_account_whitelist] = @context.csp_domains.active.pluck(:domain).sort
    end
    json
  end
end
