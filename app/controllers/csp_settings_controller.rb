# frozen_string_literal: true

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
# configuring allowed domains

class CspSettingsController < ApplicationController
  before_action :require_context, :require_user
  before_action :require_read_permissions, only: [:get_csp_settings, :csp_log]
  before_action :require_permissions, except: [:get_csp_settings, :csp_log]
  before_action :get_domain, only: [:add_domain, :remove_domain]

  # @API Get current settings for account or course
  #
  # Update multiple modules in an account.
  #
  # @response_field enabled Whether CSP is enabled.
  # @response_field inherited Whether the current CSP settings are inherited from a parent account.
  # @response_field settings_locked Whether current CSP settings can be overridden by sub-accounts and courses.
  # @response_field effective_whitelist If enabled, lists the currently allowed domains
  #   (includes domains automatically allowed through external tools).
  # @response_field tools_whitelist (Account-only) Lists the automatically allowed domains with
  #   their respective external tools
  # @response_field current_account_whitelist (Account-only) Lists the current list of domains
  #   explicitly allowed by this account. (Note: this list will not take effect unless
  #   CSP is explicitly enabled on this account)
  def get_csp_settings
    render json: csp_settings_json
  end

  # @API Enable, disable, or clear explicit CSP setting
  #
  # Either explicitly sets CSP to be on or off for courses and sub-accounts,
  # or clear the explicit settings to default to those set by a parent account
  #
  # Note: If "inherited" and "settings_locked" are both true for this account or course,
  # then the CSP setting cannot be modified.
  #
  # @argument status [Required, String, "enabled"|"disabled"|"inherited"]
  #   If set to "enabled" for an account, CSP will be enabled for all its courses and sub-accounts (that
  #   have not explicitly enabled or disabled it), using the allowed domains set on this account.
  #   If set to "disabled", CSP will be disabled for this account or course and for all sub-accounts
  #   that have not explicitly re-enabled it.
  #   If set to "inherited", this account or course will reset to the default state where CSP settings
  #   are inherited from the first parent account to have them explicitly set.
  #
  def set_csp_setting
    if ["enabled", "disabled"].include?(params[:status]) && @context.csp_inherited? && @context.csp_locked?
      return render json: { message: "cannot set when locked by parent account" }, status: :bad_request
    end

    case params[:status]
    when "enabled"
      if @context.is_a?(Course)
        if @context.account.csp_enabled?
          @context.inherit_csp! # just un-disable
        else
          return render json: { message: "must be enabled on account-level first" }, status: :bad_request
        end
      else
        @context.enable_csp!
      end
    when "disabled"
      @context.disable_csp!
    when "inherited"
      @context.inherit_csp!
    else
      return render json: { message: "invalid setting" }, status: :bad_request
    end
    RequestCache.clear # clear inherited account settings
    render json: csp_settings_json
  end

  # @API Lock or unlock current CSP settings for sub-accounts and courses
  #
  # Can only be set if CSP is explicitly enabled or disabled on this account (i.e. "inherited" is false).
  #
  # @argument settings_locked [Required, Boolean]
  #   Whether sub-accounts and courses will be prevented from overriding settings inherited from this account.
  #
  def set_csp_lock
    if @context.csp_inherited?
      return render json: { message: "CSP must be explicitly set on this account" }, status: :bad_request
    end

    if value_to_boolean(params.require(:settings_locked))
      @context.lock_csp!
    else
      @context.unlock_csp!
    end
    render json: csp_settings_json
  end

  # @API Add an allowed domain to account
  #
  # Adds an allowed domain for the current account. Note: this will not take effect
  # unless CSP is explicitly enabled on this account.
  #
  # @argument domain [Required, String]
  def add_domain
    if @context.add_domain!(@domain)
      render json: { current_account_whitelist: @context.csp_domains.active.pluck(:domain).sort }
    else
      render json: { message: "invalid domain" }, status: :bad_request
    end
  end

  # @API Add multiple allowed domains to an account
  #
  # Adds multiple allowed domains for the current account. Note: this will not take effect
  # unless CSP is explicitly enabled on this account.
  #
  # @argument domains [Required, Array]
  def add_multiple_domains
    domains = params.require(:domains)

    invalid_domains = domains.reject { |domain| URI.parse(domain) rescue nil }
    unless invalid_domains.empty?
      render json: { message: "invalid domains: #{invalid_domains.join(", ")}" }, status: :bad_request
      return false
    end

    unsuccessful_domains = []
    domains.each do |domain|
      unsuccessful_domains << domain unless @context.add_domain!(domain)
    end

    if unsuccessful_domains.empty?
      render json: { current_account_whitelist: @context.csp_domains.active.pluck(:domain).sort }
    else
      render json: { message: "failed adding some domains: #{unsuccessful_domains.join(", ")}" }, status: :bad_request
    end
  end

  # @API Retrieve reported CSP Violations for account
  #
  # Must be called on a root account.
  def csp_log
    return render status: :bad_request, json: { message: "must be called on a root account" } unless @context.root_account?
    return render status: :service_unavailable, json: { message: "CSP logging is not configured on the server" } unless (ss = @context.csp_logging_config["shared_secret"])

    render json: CanvasHttp.get("#{@context.csp_logging_config["host"]}report/#{@context.global_id}", { "Authorization" => "Bearer #{ss}" }).body
  end

  # @API Remove a domain from account
  #
  # Removes an allowed domain from the current account.
  #
  # @argument domain [Required, String]
  def remove_domain
    @context.remove_domain!(@domain)
    render json: { current_account_whitelist: @context.csp_domains.active.pluck(:domain).sort }
  end

  protected

  def require_read_permissions
    !!authorized_action(@context, @current_user, :read_as_admin)
  end

  def require_permissions
    account = @context.is_a?(Course) ? @context.account : @context
    !!authorized_action(account, @current_user, :manage_account_settings)
  end

  def get_domain
    @domain = params.require(:domain)
    unless @domain.is_a?(String) # could do stricter checking someday maybe
      render json: { message: "invalid domain" }, status: :bad_request
      return false
    end
    @domain
  end

  def csp_settings_json
    json = {
      enabled: @context.csp_enabled?,
      inherited: @context.csp_inherited?,
      settings_locked: @context.csp_locked?,
    }
    json[:effective_whitelist] = @context.csp_whitelisted_domains(request, include_files: false, include_tools: true) if @context.csp_enabled?
    if @context.is_a?(Account)
      tools_whitelist = {}
      @context.csp_tools_grouped_by_domain.each do |domain, tools|
        tools_whitelist[domain] = tools.map do |tool|
          { id: tool.id, name: tool.name, account_id: tool.context_id }
        end
      end
      json[:tools_whitelist] = tools_whitelist
      json[:current_account_whitelist] = @context.csp_domains.active.pluck(:domain).sort
    end
    json
  end
end
