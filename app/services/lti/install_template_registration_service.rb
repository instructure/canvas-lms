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

class Lti::InstallTemplateRegistrationService < ApplicationService
  attr_reader :account, :user, :template, :create_binding

  def initialize(account:, user:, template:, create_binding: false)
    raise ArgumentError, "template registration must be provided" if template.nil?
    raise ArgumentError, "root account must be provided" if account.nil? || !account.root_account?
    raise ArgumentError, "user must be provided" if user.nil?
    raise ArgumentError, "Dynamic Registrations cannot be used as templates" if template.dynamic_registration?

    super()

    @account = account
    @template = template
    @create_binding = create_binding
    @user = user
  end

  def call
    existing_copy = Lti::Registration.active.find_by(template_registration: template, account:)
    return existing_copy if existing_copy.present?

    Lti::Registration.transaction do
      local_copy = Lti::Registration.create!(
        template_registration: template,
        account:,
        created_by: user,
        updated_by: user,
        **template.slice(
          :internal_service,
          :admin_nickname,
          :description,
          :vendor,
          :name
        )
      )

      Lti::ToolConfiguration.create!(
        lti_registration: local_copy,
        unified_tool_id: local_copy.developer_key.unified_tool_id,
        # use the overlaid template configuration as the base for the local copy
        **template.internal_lti_configuration(include_overlay: true)
      )

      # blank so that local copy can make its own changes
      Lti::Overlay.create!(
        account:,
        registration: local_copy,
        updated_by: user,
        data: {}
      )

      # TODO: backwards compatibility for now, remove once
      # binding responsibility respects the template flag
      if create_binding
        Lti::AccountBindingService.call(
          registration: local_copy,
          account:,
          user:,
          workflow_state: :on
        )
      end

      local_copy.new_external_tool(account, current_user: user, available: false)

      local_copy
    end
  end
end
