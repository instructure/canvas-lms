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

class AuthenticationProvidersPresenter
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::FormOptionsHelper

  attr_reader :account

  def initialize(acc)
    @account = acc
  end

  def configs
    @configs ||= account.authentication_providers.active.to_a
  end

  def new_auth_types
    AuthenticationProvider.valid_auth_types.filter_map do |auth_type|
      klass = AuthenticationProvider.find_sti_class(auth_type)
      next unless klass.enabled?(account)
      next if klass.singleton? && configs.any?(klass)

      klass
    end
  end

  def needs_unknown_user_url?
    configs.any?(AuthenticationProvider::Delegated)
  end

  def login_url_options(aac)
    options = { controller: "login/#{aac.auth_type}", action: :new }
    if !aac.is_a?(AuthenticationProvider::LDAP) &&
       configs.many? { |other| other.auth_type == aac.auth_type }
      options[:id] = aac
    end
    options
  end

  def auth?
    configs.any?
  end

  def ldap_config?
    !ldap_configs.empty?
  end

  def ldap_ips
    ldap_configs.map(&:ldap_ip).to_sentence
  end

  def ldap_configs
    configs.select { |c| c.is_a?(AuthenticationProvider::LDAP) }
  end

  def saml_configs
    configs.select { |c| c.is_a?(AuthenticationProvider::SAML) }
  end

  def cas_configs
    configs.select { |c| c.is_a?(AuthenticationProvider::CAS) }
  end

  def sso_options
    new_auth_types.map do |auth_type|
      {
        name: auth_type.display_name,
        value: auth_type.sti_name
      }
    end
  end

  def position_options(config)
    position_options = (1..configs.length).map { |i| [i, i] }
    config.new_record? ? [["Last", nil]] + position_options : position_options
  end

  def saml_identifiers
    return [] unless saml_enabled?

    AuthenticationProvider::SAML.name_id_formats
  end

  def login_attribute_for(config)
    saml_login_attributes.invert[config.login_attribute]
  end

  def saml_authn_contexts(base = SAML2::AuthnStatement::Classes.constants.map { |const| SAML2::AuthnStatement::Classes.const_get(const, false) })
    return [] unless saml_enabled?

    [["No Value", nil]] + base.sort
  end

  def saml_enabled?
    AuthenticationProvider::SAML.enabled?
  end

  def login_placeholder
    AuthenticationProvider.default_delegated_login_handle_name
  end

  def login_name
    account.login_handle_name_with_inference
  end

  def new_config(auth_type)
    AuthenticationProvider.new(auth_type:, account:)
  end

  def parent_reg_selected
    account.parent_registration?
  end

  def available_federated_attributes(aac)
    AuthenticationProvider::CANVAS_ALLOWED_FEDERATED_ATTRIBUTES - aac.federated_attributes.keys
  end

  def federated_provider_attribute(aac, canvas_attribute = nil, selected = nil)
    name = "authentication_provider[federated_attributes][#{canvas_attribute}][attribute]" if selected
    id = "aacfa_#{canvas_attribute}_attribute_#{id_suffix(aac)}"
    if aac.class.recognized_federated_attributes.nil?
      if selected
        text_field_tag(name, selected, id:)
      else
        text_field_tag(nil)
      end
    else
      select_tag(name, options_for_select(aac.class.recognized_federated_attributes, selected), class: "ic-Input", id:)
    end
  end

  def id_suffix(aac)
    suf = aac.class.sti_name
    suf += "_#{aac.id}" unless aac.new_record?
    suf
  end
end
