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

describe Lti::InstallTemplateRegistrationService do
  let(:account) { account_model }
  let(:user) { user_model }
  let(:template) do
    lti_registration_with_tool(
      account: Account.site_admin,
      created_by: user,
      registration_params: { name: "Template Registration" },
      overlay_params: { course_navigation: { text: "override" } }
    )
  end

  describe "invalid parameters" do
    it "raises an error if template is nil" do
      expect do
        Lti::InstallTemplateRegistrationService.new(
          account:,
          user:,
          template: nil
        )
      end.to raise_error(ArgumentError, "template registration must be provided")
    end

    it "raises an error if account is nil" do
      expect do
        Lti::InstallTemplateRegistrationService.new(
          account: nil,
          user:,
          template:
        )
      end.to raise_error(ArgumentError, "root account must be provided")
    end

    it "raises an error if account is not a root account" do
      child_account = account_model(parent_account: account)
      expect do
        Lti::InstallTemplateRegistrationService.new(
          account: child_account,
          user:,
          template:
        )
      end.to raise_error(ArgumentError, "root account must be provided")
    end

    it "raises an error if user is nil" do
      expect do
        Lti::InstallTemplateRegistrationService.new(
          account:,
          user: nil,
          template:
        )
      end.to raise_error(ArgumentError, "user must be provided")
    end

    it "raises an error if registration is a dynamic registration" do
      lti_ims_registration_model(lti_registration: template)

      expect do
        Lti::InstallTemplateRegistrationService.new(
          account:,
          user:,
          template:
        )
      end.to raise_error(ArgumentError, "Dynamic Registrations cannot be used as templates")
    end
  end

  it "creates a local copy of the template registration" do
    local_copy = Lti::InstallTemplateRegistrationService.call(
      account:,
      user:,
      template:
    )

    expect(local_copy).to be_persisted
    expect(local_copy.id).not_to eq(template.id)
    expect(local_copy.template_registration).to eq(template)
    expect(local_copy.account).to eq(account)
    expect(local_copy.name).to eq("Template Registration")
    expect(local_copy.created_by).to eq(user)
    expect(local_copy.updated_by).to eq(user)

    tool_configuration = local_copy.manual_configuration
    expect(tool_configuration).to be_present
    expect(tool_configuration.lti_registration).to eq(local_copy)
    expect(tool_configuration.internal_lti_configuration.with_indifferent_access).to eq(
      template.internal_lti_configuration(include_overlay: true)
    )

    overlay = local_copy.overlay_for(account)
    expect(overlay).to be_present
    expect(overlay.account).to eq(account)
    expect(overlay.registration).to eq(local_copy)
    expect(overlay.data).to eq({})

    deployment = local_copy.deployments.find_by(account:)
    expect(deployment).to be_present
    expect(deployment.context_controls.find_by(account:).available).to be(false)
    expect(deployment.workflow_state).not_to eq("disabled")
  end

  it "only creates one local copy per account" do
    first_copy = Lti::InstallTemplateRegistrationService.call(
      account:,
      user:,
      template:
    )

    second_copy = Lti::InstallTemplateRegistrationService.call(
      account:,
      user:,
      template:
    )

    expect(second_copy).to eq(first_copy)
    expect(template.local_copies.where(account:).count).to eq(1)
  end

  it "uses an existing local copy without creating another one" do
    existing_copy = Lti::Registration.create!(
      account:,
      name: template.name,
      template_registration: template,
      created_by: user,
      updated_by: user
    )

    expect do
      result = Lti::InstallTemplateRegistrationService.call(
        account:,
        user:,
        template:
      )

      expect(result).to eq(existing_copy)
    end.not_to change { Lti::Registration.count }
  end

  it "does not use a deleted local copy" do
    deleted_copy = Lti::Registration.create!(
      account:,
      name: template.name,
      template_registration: template,
      created_by: user,
      updated_by: user,
      workflow_state: "deleted"
    )

    new_copy = Lti::InstallTemplateRegistrationService.call(
      account:,
      user:,
      template:
    )

    expect(new_copy).not_to eq(deleted_copy)
    expect(new_copy.workflow_state).to eq("active")
    expect(template.local_copies.where(account:).active.count).to eq(1)
  end

  it "does not create an account binding" do
    local_copy = Lti::InstallTemplateRegistrationService.call(
      account:,
      user:,
      template:
    )

    rab = Lti::RegistrationAccountBinding.find_by(account:, registration: local_copy)
    expect(rab).to be_nil
  end

  context "when create_binding is true" do
    it "creates an account binding with the specified workflow state" do
      local_copy = Lti::InstallTemplateRegistrationService.call(
        account:,
        user:,
        template:,
        create_binding: true
      )

      rab = Lti::RegistrationAccountBinding.find_by(account:, registration: local_copy)
      expect(rab).to be_present
      expect(rab.workflow_state).to eq("on")

      dkab = DeveloperKeyAccountBinding.find_by(account:, developer_key: local_copy.developer_key)
      expect(dkab).to be_present
      expect(dkab.workflow_state).to eq("on")
    end
  end

  context "with cross-shard account" do
    specs_require_sharding

    it "creates a local copy of the template registration for a cross-shard account" do
      template

      @shard2.activate do
        account2 = account_model
        user2 = user_model

        local_copy = Lti::InstallTemplateRegistrationService.call(
          account: account2,
          user: user2,
          template:
        )

        expect(local_copy.template_registration).to eq(template)
        expect(local_copy.account).to eq(account2)
        expect(local_copy.created_by).to eq(user2)
        expect(local_copy.updated_by).to eq(user2)
      end
    end
  end
end
