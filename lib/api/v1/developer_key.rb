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

  DEVELOPER_KEY_JSON_ATTRS = %w(
    name created_at email user_id user_name icon_url notes workflow_state
  ).freeze

  def developer_keys_json(keys, user, session, context, show_bindings=false)
    keys.map{|k| developer_key_json(k, user, session, context, show_bindings) }
  end

  def developer_key_json(key, user, session, context, show_bindings=false)
    context ||= Account.site_admin
    account_binding = key.account_binding_for(context)

    api_json(key, user, session, :only => DEVELOPER_KEY_JSON_ATTRS).tap do |hash|
      if context.grants_right?(user, session, :manage_developer_keys) || user.try(:id) == key.user_id
        hash['api_key'] = key.api_key
        hash['redirect_uri'] = key.redirect_uri
        hash['redirect_uris'] = key.redirect_uris.join("\n")
        hash['notes'] = key.notes
        hash['access_token_count'] = key.access_token_count
        hash['last_used_at'] = key.last_used_at
        hash['vendor_code'] = key.vendor_code
      end

      if account_binding.present? && show_bindings
        hash['developer_key_account_binding'] = DeveloperKeyAccountBindingSerializer.new(account_binding)
      end
      hash['account_owns_binding'] = account_binding&.account == context && show_bindings

      hash['account_name'] = key.account_name
      hash['visible'] = key.visible
      hash['id'] = key.global_id
    end
  end
end
