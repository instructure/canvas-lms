# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

module DataFixup
  class RevertExternalToolsShowScopes < CanvasOperations::DataFixup
    SCOPE_CHANGES = {
      "url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id(/*full_path)" => "url:GET|/api/v1/accounts/:account_id/external_tools/:external_tool_id",
      "url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id(/*full_path)" => "url:GET|/api/v1/courses/:course_id/external_tools/:external_tool_id",
    }.freeze

    self.mode = :individual_record
    self.progress_tracking = false

    scope do
      # Find developer keys that have any of the old external_tools scopes
      query_conditions = SCOPE_CHANGES.keys.map do |old_scope|
        DeveloperKey.where("scopes LIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(old_scope)}%")
      end

      query_conditions.reduce(&:or)
    end

    def process_record(developer_key)
      original_scopes = developer_key.scopes
      updated_scopes = original_scopes.map { |scope| SCOPE_CHANGES[scope] || scope }

      if original_scopes != updated_scopes
        developer_key.scopes = updated_scopes
        begin
          developer_key.save!
        rescue ActiveRecord::RecordInvalid => e
          log_message("Developer key #{developer_key.global_id} scope fixup threw #{e}")
        end
      end
    end
  end
end
