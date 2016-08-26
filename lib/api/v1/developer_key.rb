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

module Api::V1::DeveloperKey
  include Api::V1::Json

  DEVELOPER_KEY_JSON_ATTRS = %w(
    name created_at email user_id user_name icon_url workflow_state
  ).freeze

  def developer_keys_json(keys, user, session, context=nil)
    keys.map{|k| developer_key_json(k, user, session, context) }
  end

  def developer_key_json(key, user, session, context=nil)
    context ||= Account.site_admin
    api_json(key, user, session, :only => DEVELOPER_KEY_JSON_ATTRS).tap do |hash|
      if context.grants_right?(user, session, :manage_developer_keys) || user.try(:id) == key.user_id
        hash['api_key'] = key.api_key
        hash['redirect_uri'] = key.redirect_uri
        hash['redirect_uris'] = key.redirect_uris.join("\n")
      end
      hash['account_name'] = key.account_name
      hash['id'] = key.global_id
    end
  end
end
