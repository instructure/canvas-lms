# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class Login::OAuthBaseController < ApplicationController
  include Login::Shared

  before_action :forbid_on_files_domain
  before_action :run_login_hooks, :fix_ms_office_redirects, only: :new

  def new
    # a subclass might explicitly set the AAC, so that we don't need to infer
    # it from the URL
    return if @aac

    auth_type = params[:controller].sub(%r{^login/}, "")
    # ActionController::TestCase can't deal with aliased controllers, so we have to
    # explicitly specify this
    auth_type = params[:auth_type] if Rails.env.test?
    scope = @domain_root_account.authentication_providers.active.where(auth_type:)
    @aac = if params[:id]
             scope.find(params[:id])
           else
             scope.first!
           end
  end

  protected

  def timeout_protection
    timeout_options = { raise_on_timeout: true, fallback_timeout_length: 10.seconds }

    Canvas.timeout_protection("oauth:#{@aac.global_id}", timeout_options) do
      yield
      true
    end
  rescue => e
    Canvas::Errors.capture(e,
                           type: :oauth_consumer,
                           aac_id: @aac.global_id,
                           account_id: @aac.global_account_id)
    flash[:delegated_message] = t("There was a problem logging in at %{institution}",
                                  institution: @domain_root_account.display_name)
    redirect_to login_url
    false
  end

  def find_pseudonym(unique_ids, provider_attributes = {})
    unique_ids = unique_ids.first if unique_ids.is_a?(Array)

    unique_id = unique_ids.is_a?(Hash) ? unique_ids[@aac.login_attribute] : unique_ids
    if unique_id.nil?
      unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
      logger.warn "Received OAuth2 login with no unique_id"
      flash[:delegated_message] =
        t("Authentication with %{provider} was successful, but no unique ID for logging in to Canvas was provided.",
          provider: @aac.class.display_name)
      return redirect_to unknown_user_url
    end

    pseudonym = @domain_root_account.pseudonyms.for_auth_configuration(unique_ids, @aac)
    unless pseudonym
      return if need_email_verification?(unique_ids, @aac)
    end

    if pseudonym
      @aac.apply_federated_attributes(pseudonym, provider_attributes)
    elsif @aac.jit_provisioning?
      pseudonym = @aac.provision_user(unique_ids, provider_attributes)
    end

    if pseudonym && (user = pseudonym.login_assertions_for_user)
      # Successful login and we have a user
      @domain_root_account.pseudonyms.scoping do
        PseudonymSession.create!(pseudonym, false)
      end
      session[:login_aac] = @aac.global_id

      successful_login(user, pseudonym)
    else
      unknown_user_url = @domain_root_account.unknown_user_url.presence || login_url
      logger.warn "Received OAuth2 login for unknown user: #{unique_ids.inspect}, redirecting to: #{unknown_user_url}."
      flash[:delegated_message] = t "Canvas doesn't have an account for user: %{user}", user: unique_id
      redirect_to unknown_user_url
    end
  end
end
