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

  protected

  def aac
    return @aac if @aac

    auth_type = params[:controller].sub(%r{^login/}, "")
    # ActionController::TestCase can't deal with aliased controllers, so we have to
    # explicitly specify this
    auth_type = params[:auth_type] if Rails.env.test? && params[:auth_type]
    scope = @domain_root_account.authentication_providers.active.where(auth_type:)
    @aac = if params[:id]
             scope.find(params[:id])
           else
             scope.first!
           end
  end

  def timeout_protection
    timeout_options = { raise_on_timeout: true, fallback_timeout_length: 10.seconds }

    Canvas.timeout_protection("oauth:#{@aac.global_id}", timeout_options) do
      yield
      true
    end
  rescue RetriableOAuthValidationError => e
    redirect_to aac.try(:validation_error_retry_url, e, controller: self, target_auth_provider: try(:target_auth_provider)) || login_url

    increment_statsd(:failure, reason: :retriable_oauth_validation_error)

    false
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

  def find_pseudonym(unique_ids, provider_attributes = {}, token = nil)
    unique_ids = unique_ids.first if unique_ids.is_a?(Array)

    unique_id = unique_ids.is_a?(Hash) ? unique_ids[@aac.login_attribute] : unique_ids
    if unique_id.nil?
      logger.warn "Received OAuth2 login with no unique_id"
      return redirect_to_unknown_user_url(
        t("Authentication with %{provider} was successful, but no unique ID for logging in to Canvas was provided.",
          provider: @aac.class.display_name)
      )
    end

    pseudonym = @aac.account.pseudonyms.for_auth_configuration(unique_ids, @aac)
    if !pseudonym && need_email_verification?(unique_ids, @aac)
      increment_statsd(:failure, reason: :need_email_verification)
      return
    end

    # Apply any authentication-provider-specific validations on the found pseudonym. This validation needs to happen
    # before we apply any federated attributes so that we do not update the user and pseudonym if the validation
    # would fail. Since we don't have a pseudonym yet when jit provisioning a user, we can only run the validation
    # after the user has been created.
    #
    # See AuthenticationProvider::OAuth2#validate_found_pseudonym!
    if pseudonym
      @aac.try(:validate_found_pseudonym!, pseudonym:, session:, token:, target_auth_provider: try(:target_auth_provider))
      @aac.apply_federated_attributes(pseudonym, provider_attributes)
    elsif @aac.jit_provisioning?
      pseudonym = @aac.provision_user(unique_ids, provider_attributes)
      @aac.try(:validate_found_pseudonym!, pseudonym:, session:, token:, target_auth_provider: try(:target_auth_provider))
    end

    if pseudonym && (user = pseudonym.login_assertions_for_user)
      # Successful login and we have a user
      @domain_root_account.pseudonyms.scoping do
        PseudonymSession.create!(pseudonym, false)
      end
      session[:login_aac] = @aac.global_id
      @aac.try(:persist_to_session, request, session, pseudonym, @domain_root_account, token) if token

      successful_login(user, pseudonym, @aac.try(:mfa_passed?, token))
    else
      logger.warn "Received OAuth2 login for unknown user: #{unique_ids.inspect}"
      redirect_to_unknown_user_url(t("Canvas doesn't have an account for user: %{user}", user: unique_id))
      increment_statsd(:failure, reason: :unknown_user)
    end
  end
end
