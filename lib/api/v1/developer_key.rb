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

module Api::V1::DeveloperKey
  include Api::V1::Json

  DEVELOPER_KEY_JSON_ATTRS = %w[
    name created_at email user_id user_name icon_url notes workflow_state scopes require_scopes client_credentials_audience
  ].freeze
  INHERITED_DEVELOPER_KEY_JSON_ATTRS = %w[name created_at icon_url workflow_state].freeze

  def developer_keys_json(keys, user, session, context, inherited: false, include_tool_config: false)
    keys.map { |k| developer_key_json(k, user, session, context, inherited:, include_tool_config:) }
  end

  def developer_key_json(key, user, session, context, inherited: false, include_tool_config: false)
    context ||= Account.site_admin
    account_binding = key.account_binding_for(context)
    keys_to_show = if inherited
                     INHERITED_DEVELOPER_KEY_JSON_ATTRS
                   else
                     DEVELOPER_KEY_JSON_ATTRS
                   end

    keys_to_show += ["test_cluster_only"] if DeveloperKey.test_cluster_checks_enabled?

    api_json(key, user, session, only: keys_to_show).tap do |hash|
      if (context.grants_right?(user, session, :manage_developer_keys) || user.try(:id) == key.user_id) && !inherited
        hash["api_key"] = key.api_key
        hash["redirect_uri"] = key.redirect_uri
        hash["redirect_uris"] = key.redirect_uris.join("\n")
        hash["notes"] = key.notes
        hash["access_token_count"] = key.access_token_count
        hash["last_used_at"] = key.last_used_at
        hash["vendor_code"] = key.vendor_code
        hash["public_jwk"] = key.public_jwk
        hash["public_jwk_url"] = key.public_jwk_url
        hash["allow_includes"] = key.allow_includes
      end

      if account_binding.present?
        hash["developer_key_account_binding"] = DeveloperKeyAccountBindingSerializer.new(account_binding, context)
      end

      if inherited
        hash["inherited_from"] = key.account_id.present? ? "federated_parent" : "global"
        hash["inherited_to"] = "child_account" unless context.primary_settings_root_account?
      else
        hash["account_name"] = key.account_name
        hash["visible"] = key.visible
      end
      hash["tool_configuration"] = key.tool_configuration&.configuration if include_tool_config
      hash["lti_registration"] = key.lti_registration if include_tool_config
      hash["is_lti_key"] = (key.is_lti_key.nil? ? key.public_jwk.present? : key.is_lti_key)
      hash["is_lti_registration"] = key.lti_registration?
      hash["id"] = key.global_id
    end
  end
end
