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
  attr_reader :account, :user, :template, :binding_state, :local_copy, :create_tool

  def initialize(account:, template:, user: nil, binding_state: :on, create_tool: true)
    raise ArgumentError, "template registration must be provided" if template.nil?
    raise ArgumentError, "template registration is off" if template.workflow_state != "active"
    raise ArgumentError, "root account must be provided" if account.nil? || !account.root_account?
    raise ArgumentError, "Dynamic Registrations cannot be used as templates" if template.dynamic_registration?

    super()

    @account = account
    @template = template
    @create_tool = create_tool
    @user = user
    @binding_state = binding_state.to_sym
  end

  def call
    Lti::Registration.transaction do
      @local_copy = Lti::Registration.active.find_by(template_registration: template, account:)

      create_local_copy unless local_copy.present?

      bindings = update_state

      { local_copy:, bindings: }
    end
  end

  private

  # keep account bindings in sync with the local copy's workflow_state
  def update_state
    mapping = {
      on: :active,
      off: :inactive
    }
    workflow_state = mapping[binding_state]
    if local_copy.workflow_state.to_sym != workflow_state
      local_copy.update!(workflow_state:)
    end

    # keeps backwards compatibility before template
    # flag is on, and if it is ever turned off
    Lti::AccountBindingService.call(
      registration: template,
      account:,
      user:,
      workflow_state: binding_state
    )
  end

  def create_local_copy
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

    # deploy tool to root account
    local_copy.new_external_tool(account, current_user: user, available: false) if create_tool

    @local_copy = local_copy
  end
end
