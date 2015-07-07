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

def account_model(opts={})
  @account = factory_with_protected_attributes(Account, valid_account_attributes.merge(opts))
end

def valid_account_attributes
  {
    :name => "value for name"
  }
end

def account_with_cas(opts={})
  @account = opts[:account]
  @account ||= Account.create!
  config = AccountAuthorizationConfig::CAS.new
  cas_url = opts[:cas_url] || "https://localhost/cas"
  config.auth_type = "cas"
  config.auth_base = cas_url
  config.log_in_url = opts[:cas_log_in_url] if opts[:cas_log_in_url]
  @account.authentication_providers << config
  @account
end

def account_with_saml(opts={})
  @account = opts[:account]
  @account ||= Account.create!
  config = AccountAuthorizationConfig::SAML.new
  config.idp_entity_id = "saml_entity"
  config.auth_type = "saml"
  config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
  config.log_out_url = opts[:saml_log_out_url] if opts[:saml_log_out_url]
  @account.authentication_providers << config
  @account
end

def account_with_role_changes(opts={})
  account = opts[:account] || Account.default
  if opts[:role_changes]
    opts[:role_changes].each_pair do |permission, enabled|
      role = opts[:role] || admin_role
      if ro = account.role_overrides.where(:permission => permission.to_s, :role_id => role.id).first
        ro.update_attribute(:enabled, enabled)
      else
        account.role_overrides.create(:permission => permission.to_s, :enabled => enabled, :role => role)
      end
    end
  end
  RoleOverride.clear_cached_contexts
end
