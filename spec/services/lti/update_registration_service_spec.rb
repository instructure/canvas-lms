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

describe Lti::UpdateRegistrationService do
  # see also spec/controllers/lti/registrations_controller_spec.rb "PUT update"
  subject do
    described_class.call(
      id: registration.id,
      account:,
      updated_by:,
      registration_params:,
      configuration_params:,
      overlay_params:,
      binding_params:
    )
  end

  let(:account) { account_model }
  let(:registration) { developer_key.lti_registration }
  let(:developer_key) do
    lti_developer_key_model(account:).tap do |dk|
      lti_tool_configuration_model(developer_key: dk, lti_registration: dk.lti_registration)
    end
  end
  let(:updated_by) { user_model }
  let(:registration_params) { {} }
  let(:configuration_params) { {} }
  let(:overlay_params) { {} }
  let(:binding_params) { {} }

  context "with valid registration_params" do
    let(:registration_params) do
      {
        name: "new name",
        admin_nickname: "new nickname",
        vendor: "new vendor",
      }
    end

    it "updates the registration" do
      subject
      expect(registration.reload.name).to eq("new name")
      expect(registration.admin_nickname).to eq("new nickname")
      expect(registration.vendor).to eq("new vendor")
      expect(registration.updated_by).to eq(updated_by)
    end

    it "updates the DeveloperKey" do
      subject
      expect(developer_key.reload.name).to eq("new name")
    end
  end

  context "with invalid registration_params" do
    let(:registration_params) { { uh: :oh } }

    it "raises an error" do
      expect { subject }.to raise_error(ActiveModel::UnknownAttributeError)
    end
  end

  context "with no previous overlay" do
    context "and overlay_params" do
      let(:overlay_params) { { some: "data" }.with_indifferent_access }

      it "creates an overlay with provided params" do
        expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
        subject
        overlay = Lti::Overlay.find_by(registration:, account:)
        expect(overlay.data).to eq(overlay_params)
        expect(overlay.updated_by).to eq(updated_by)
      end
    end

    it "does not create an overlay" do
      expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
      subject
      expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
    end
  end

  context "with previous overlay" do
    let(:overlay) { lti_overlay_model(registration:, account:, data: { hello: :there }) }
    let(:overlay_params) { { some: "data" }.with_indifferent_access }

    before { overlay }

    it "updates the overlay with provided params" do
      subject
      expect(overlay.reload.data).to eq(overlay_params)
      expect(overlay.updated_by).to eq(updated_by)
    end
  end

  context "with invalid configuration_params" do
    let(:configuration_params) { { uh: :oh } }

    it "raises an error" do
      expect { subject }.to raise_error(ActiveModel::UnknownAttributeError)
    end
  end

  context "with valid configuration_params" do
    let(:configuration_params) do
      {
        title: "new title",
        description: "new description",
        launch_settings: { icon_url: "http://example.com/icon" },
        placements: [{ placement: "course_navigation" }],
        redirect_uris: ["http://example.com/redirect"],
      }
    end

    it "updates the ToolConfiguration" do
      subject
      expect(registration.manual_configuration.reload.title).to eq("new title")
      expect(registration.manual_configuration.description).to eq("new description")
      expect(registration.manual_configuration.launch_settings).to eq("icon_url" => "http://example.com/icon")
      expect(registration.manual_configuration.placements).to eq([{ "placement" => "course_navigation" }])
      expect(registration.manual_configuration.redirect_uris).to eq(["http://example.com/redirect"])
    end

    it "updates the DeveloperKey" do
      subject
      expect(developer_key.reload.icon_url).to eq("http://example.com/icon")
      expect(developer_key.redirect_uris).to eq(["http://example.com/redirect"])
    end

    it "sends updates to all deployments" do
      expect_any_instance_of(DeveloperKey).to receive(:update_external_tools!).once

      subject
    end
  end

  context "with invalid binding_params" do
    let(:binding_params) { { uh: :oh } }

    it "does not error" do
      expect { subject }.not_to raise_error
    end
  end

  context "with valid binding_params" do
    let(:binding_params) { { workflow_state: "on" } }

    it "updates the account binding" do
      subject
      account_binding = Lti::RegistrationAccountBinding.find_by(registration:, account:)
      expect(account_binding.workflow_state).to eq("on")
      expect(account_binding.updated_by).to eq(updated_by)
      expect(account_binding.created_by).to eq(updated_by)
    end
  end

  context "scopes" do
    let(:scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] }

    before do
      developer_key.update!(scopes:)
      registration.manual_configuration.update!(scopes:)
    end

    context "in configuration_params" do
      let(:new_scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"] }
      let(:configuration_params) { { scopes: new_scopes } }

      it "updates the scopes" do
        subject
        expect(developer_key.reload.scopes).to match_array(new_scopes)
        expect(registration.manual_configuration.reload.scopes).to match_array(new_scopes)
      end
    end

    context "in overlay_params" do
      let(:overlay_params) { { disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] } }

      it "stores overlaid scopes on developer key" do
        subject
        expect(developer_key.reload.scopes).to eq []
      end
    end

    context "in both" do
      let(:new_scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"] }
      let(:configuration_params) { { scopes: scopes + new_scopes } }
      let(:overlay_params) { { disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] } }

      it "stores overlaid scopes on developer key" do
        subject
        expect(developer_key.reload.scopes).to match_array(new_scopes)
      end

      it "stores scopes without overlay on tool configuration" do
        subject
        expect(registration.manual_configuration.reload.scopes).to match_array(scopes + new_scopes)
      end
    end

    context "left unchanged" do
      it "does not change scopes" do
        expect { subject }.not_to change { developer_key.reload.scopes }
      end
    end
  end
end
