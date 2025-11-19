# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Api::V1::Lti::RegistrationHistoryEntry
  include Api::V1::Json
  include Api::V1::User

  JSON_ATTRS = %w[
    id
    root_account_id
    lti_registration_id
    created_at
    updated_at
    diff
    update_type
    comment
    old_configuration
    new_configuration
    old_context_controls
    new_context_controls
  ].freeze

  def lti_registration_history_entry_json(history_entry, user, session, context)
    api_json(history_entry, user, session, only: JSON_ATTRS).tap do |json|
      if history_entry.created_by.present?
        json["created_by"] = if Account.site_admin.grants_right?(history_entry.created_by, session, :read)
                               "Instructure"
                             else
                               user_json(history_entry.created_by, user, session, [], context, nil, ["pseudonym"])
                             end
      end
    end
  end

  def lti_registration_history_entries_json(history_entries, user, session, context)
    history_entries.map { |entry| lti_registration_history_entry_json(entry, user, session, context) }
  end
end
