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
#
module Factories
  def account_model(opts = {})
    @account = factory_with_protected_attributes(Account, valid_account_attributes.merge(opts))
  end

  def stub_rcs_config
    # make sure this is loaded first
    allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
    allow(DynamicSettings).to receive(:find).with("rich-content-service", default_ttl: 5.minutes).and_return(
      DynamicSettings::FallbackProxy.new({ "app-host": ENV["RCE_HOST"] || "http://localhost:3001" })
    )

    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :signing_secret).and_return("astringthatisactually32byteslong")
    allow(Rails.application.credentials).to receive(:dig).with(:canvas_security, :encryption_secret).and_return("astringthatisactually32byteslong")
  end

  def stub_common_cartridge_url
    allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
    allow(DynamicSettings).to receive(:find).with("common_cartridge_viewer", default_ttl: 5.minutes).and_return(
      ActiveSupport::HashWithIndifferentAccess.new({ "app-host": "http://common-cartridge-viewer.netlify.com/" })
    )
  end

  def account_rcs_model(opts = {})
    @account = factory_with_protected_attributes(Account, valid_account_attributes.merge(opts))
  end

  def provision_quizzes_next(account)
    # quizzes_next feature is turned on only if a root account is provisioned
    account.root_account.settings[:provision] = { "lti" => "lti url" }
    account.root_account.save!
  end

  def valid_account_attributes
    {
      name: "value for name"
    }
  end

  def account_with_cas(opts = {})
    @account = opts[:account]
    @account ||= Account.create!
    config = AuthenticationProvider::CAS.new
    cas_url = opts[:cas_url] || "https://localhost/cas"
    config.auth_type = "cas"
    config.auth_base = cas_url
    config.log_in_url = opts[:cas_log_in_url] if opts[:cas_log_in_url]
    @account.authentication_providers << config
    @account.authentication_providers.first.move_to_bottom
    @account
  end

  def account_with_saml(opts = {})
    @account = opts[:account]
    @account ||= Account.create!
    config = AuthenticationProvider::SAML.new
    config.idp_entity_id = "saml_entity"
    config.auth_type = "saml"
    config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
    config.log_out_url = opts[:saml_log_out_url] if opts[:saml_log_out_url]
    config.parent_registration = opts[:parent_registration] if opts[:parent_registration]
    @account.authentication_providers << config
    @account.authentication_providers.first.move_to_bottom
    @account
  end

  def account_with_role_changes(opts = {})
    account = opts[:account] || Account.default
    opts[:role_changes]&.each_pair do |permission, enabled|
      role = opts[:role] || admin_role
      if (ro = account.role_overrides.where(permission: permission.to_s, role_id: role.id).first)
        ro.update_attribute(:enabled, enabled)
      else
        account.role_overrides.create(permission: permission.to_s, enabled:, role:)
      end
    end
  end
end
