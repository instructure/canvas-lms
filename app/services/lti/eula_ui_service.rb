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

module Lti
  module EulaUiService
    module_function

    # Returns EULA launch urls of all eligible asset processors attached to the assignment.
    # Eligible asset processors are:
    # - active
    # - asset processer has not opted out of EULA service (by EULA deployment configuration / eulaRequired flag)
    # - has eula service scope (be able to report if user has accepted the EULA)
    # - user has not yet accepted the EULA of the asset processor
    # If the returned array is empty, it means that the user has accepted all EULAs, the UI does not need to do anything.
    def eula_launch_urls(user:, assignment:)
      return [] unless assignment.root_account.feature_enabled?(:lti_asset_processor)

      Lti::AssetProcessor.for_assignment_id(assignment.id)
                         .map(&:context_external_tool)
                         .uniq
                         .select do |tool|
        next if tool.asset_processor_eula_required == false
        next unless tool.developer_key.scopes.include?(TokenScopes::LTI_EULA_USER_SCOPE)
        next if user.lti_asset_processor_eula_acceptances.active.find_by(context_external_tool_id: tool.id)&.accepted == true

        true
      end.map { |tool| launch_url(tool) }
    end

    def launch_url(tool)
      case tool.context_type
      when "Course"
        { name: tool.name,
          url:
        Rails.application.routes.url_helpers.course_tool_eula_launch_url(
          host: tool.root_account.environment_specific_domain,
          course_id: tool.context_id,
          context_external_tool_id: tool.id
        ) }
      when "Account"
        { name: tool.name,
          url:
        Rails.application.routes.url_helpers.account_tool_eula_launch_url(
          host: tool.root_account.environment_specific_domain,
          account_id: tool.context_id,
          context_external_tool_id: tool.id
        ) }
      end
    end
  end
end
