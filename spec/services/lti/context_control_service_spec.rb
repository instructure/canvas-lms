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

require_relative "../../lti_1_3_tool_configuration_spec_helper"

describe Lti::ContextControlService do
  subject do
    described_class.create_or_update(control_params)
  end

  # brings in a valid internal lti configuration
  include_context "lti_1_3_tool_configuration_spec_helper"

  let_once(:registration) do
    lti_tool_configuration_model(account: root_account).lti_registration
  end
  let_once(:root_account) { account_model }
  let_once(:account) { root_account }
  let_once(:course) { nil }
  let_once(:creating_user) { user_model }
  let_once(:editing_user) { user_model }
  let(:available) { true }
  let(:context_type) { "Account" }
  let(:workflow_state) { "active" }

  let(:deployment) do
    registration.new_external_tool(
      root_account,
      current_user: creating_user
    )
  end

  let(:control_params) do
    {
      root_account_id: root_account.id,
      account_id: account&.id,
      course_id: course&.id,
      registration_id: registration.id,
      deployment_id: deployment.id,
      created_by_id: editing_user.id,
      updated_by_id: editing_user.id,
      workflow_state:,
      available:,
    }
  end

  before do
    # intialize a deployment with a default control
    deployment
  end

  it "updates a soft-deleted control instead of creating a new one" do
    # Soft-delete the existing control
    control = deployment.context_controls.first
    control.workflow_state = "deleted"
    control.save!

    expect { subject }
      .to change { Lti::ContextControl.count }.by(1 - 1)
      .and change { Lti::ContextControl.active.count }.by(1)
    expect(control.reload.created_by_id).to eq(creating_user.id)
    expect(control.updated_by_id).to eq(editing_user.id)
  end

  context "when the course_id is provided" do
    let(:course) { course_model }
    let(:account) { nil }

    it "creates a new control if no existing one is found" do
      expect { subject }.to change { Lti::ContextControl.active.count }.by(1)
    end
  end
end
