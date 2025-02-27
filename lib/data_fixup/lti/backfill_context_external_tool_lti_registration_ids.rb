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

module DataFixup::Lti::BackfillContextExternalToolLtiRegistrationIds
  def self.run
    # Find all ContextExternalTools that have a developer key that have an lti registration
    # Set the CET.lti_registration_id equal to the dev_key.lti_registration_id
    ContextExternalTool.preload(:developer_key)
                       .where.not("developer_key_id" => nil)
                       .find_each do |tool|
      next unless tool&.developer_key&.lti_registration_id

      tool.update_column(:lti_registration_id, tool.developer_key.lti_registration_id)
    rescue => e
      Sentry.with_scope do |scope|
        scope.set_tags(tool_id: tool.global_id)
        scope.set_context("exception", { name: e.class.name, message: e.message })
        Sentry.capture_message("DataFixup::Lti#backfill_context_external_tool_lti_registration_ids", level: :warning)
      end
    end
  end
end
