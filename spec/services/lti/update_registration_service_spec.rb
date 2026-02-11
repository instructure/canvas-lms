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
      binding_params:,
      comment:
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
  let(:comment) { nil }

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

    it "tracks the changes" do
      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

      entry = Lti::RegistrationHistoryEntry.last

      expect(entry.diff["registration"])
        .to match_array([
                          ["~", ["name"], registration.name, registration_params[:name]],
                          ["~", ["admin_nickname"], registration.admin_nickname, registration_params[:admin_nickname]],
                          ["~", ["vendor"], registration.vendor, registration_params[:vendor]]
                        ])
      expect(entry.diff["developer_key"])
        .to match_array([["~", ["name"], developer_key.name, registration_params[:name]]])
    end
  end

  context "with invalid registration_params" do
    let(:registration_params) { { uh: :oh } }

    it "raises an error" do
      expect { subject }.to raise_error(ActiveModel::UnknownAttributeError)
    end
  end

  # TEMPORARY: These tests now only apply to dynamic registrations.
  # Manual registrations merge overlays into configuration instead.
  context "with no previous overlay (dynamic registration)" do
    let(:ims_registration) { lti_ims_registration_model(account:) }
    let(:dynamic_developer_key) do
      DeveloperKey.create!(
        account:,
        is_lti_key: true,
        scopes: [],
        public_jwk_url: "https://example.com/jwk",
        lti_registration: dynamic_registration
      )
    end
    let(:dynamic_registration) do
      Lti::Registration.create!(
        account:,
        ims_registration:,
        name: "Dynamic Registration",
        workflow_state: "active",
        created_by: updated_by,
        updated_by:
      )
    end
    let(:registration) { dynamic_registration }

    before do
      dynamic_developer_key # Ensure developer key exists
    end

    context "and overlay_params" do
      let(:overlay_params) { { some: "data" }.with_indifferent_access }

      it "creates an overlay with provided params" do
        expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
        subject
        overlay = Lti::Overlay.find_by(registration:, account:)
        expect(overlay.data).to eq(overlay_params)
        expect(overlay.updated_by).to eq(updated_by)
      end

      it "tracks the changes" do
        expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

        expect(Lti::RegistrationHistoryEntry.last.diff["overlay"])
          .to match_array([["~", [], nil, { "some" => "data" }]])
      end
    end

    it "does not create an overlay without overlay_params" do
      expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
      subject
      expect(Lti::Overlay.find_by(registration:, account:)).to be_nil
    end
  end

  context "with previous overlay (dynamic registration)" do
    let(:ims_registration) { lti_ims_registration_model(account:) }
    let(:dynamic_developer_key) do
      DeveloperKey.create!(
        account:,
        is_lti_key: true,
        scopes: [],
        public_jwk_url: "https://example.com/jwk",
        lti_registration: dynamic_registration
      )
    end
    let(:dynamic_registration) do
      Lti::Registration.create!(
        account:,
        ims_registration:,
        name: "Dynamic Registration",
        workflow_state: "active",
        created_by: updated_by,
        updated_by:
      )
    end
    let(:registration) { dynamic_registration }
    let(:overlay) { lti_overlay_model(registration:, account:, data: { hello: :there }) }
    let(:overlay_params) { { some: "data" }.with_indifferent_access }

    before do
      dynamic_developer_key # Ensure developer key exists
      overlay
    end

    it "updates the overlay with provided params" do
      subject
      expect(overlay.reload.data).to eq(overlay_params)
      expect(overlay.updated_by).to eq(updated_by)
    end

    it "tracks the changes" do
      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

      expect(Lti::RegistrationHistoryEntry.last.diff["overlay"])
        .to match_array([["-", ["hello"], "there"], ["+", ["some"], "data"]])
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

    it "tracks the changes" do
      registration.internal_lti_configuration(include_overlay: false)
      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

      diff = Lti::RegistrationHistoryEntry.last.diff

      expect(diff["internal_lti_configuration"])
        .to match_array(
          [
            ["~", ["description"], "1.3 Tool", "new description"],
            ["-", ["launch_settings", "selection_height"], 500],
            ["-", ["launch_settings", "selection_width"], 500],
            ["-", ["launch_settings", "text"], "LTI 1.3 Test Tool Extension text"],
            ["~",
             ["launch_settings", "icon_url"],
             "https://static.thenounproject.com/png/131630-200.png",
             "http://example.com/icon"],
            ["-",
             ["placements", 1],
             { "text" => "LTI 1.3 Test Tool Course Navigation",
               "enabled" => true,
               "icon_url" => "https://static.thenounproject.com/png/131630-211.png",
               "placement" => "course_navigation",
               "message_type" => "LtiResourceLinkRequest",
               "target_link_uri" =>
               "http://lti13testtool.docker/launch?placement=course_navigation",
               "canvas_icon_class" => "icon-pdf" }],
            ["-",
             ["placements", 0],
             { "text" => "LTI 1.3 Test Tool Course Navigation",
               "enabled" => true,
               "icon_url" => "https://static.thenounproject.com/png/131630-211.png",
               "placement" => "account_navigation",
               "message_type" => "LtiResourceLinkRequest",
               "target_link_uri" =>
               "http://lti13testtool.docker/launch?placement=account_navigation",
               "canvas_icon_class" => "icon-lti" }],
            ["+", ["placements", 0], { "placement" => "course_navigation" }],
            ["-", ["redirect_uris", 0], "http://lti13testtool.docker/launch"],
            ["+", ["redirect_uris", 0], "http://example.com/redirect"],
            ["~", ["title"], "LTI 1.3 Tool", "new title"]
          ]
        )
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

    # TEMPORARY: Manual registrations merge overlays into configuration now
    context "in overlay_params" do
      let(:overlay_params) { { disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] } }

      it "merges overlay into configuration (removes disabled scope)" do
        subject
        expect(registration.manual_configuration.reload.scopes).to eq []
        expect(developer_key.reload.scopes).to eq []
      end

      it "does not create an overlay" do
        expect { subject }.not_to change { Lti::Overlay.count }
      end
    end

    # TEMPORARY: Manual registrations merge overlays into configuration now
    context "in both" do
      let(:new_scopes) { ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly"] }
      let(:configuration_params) { { scopes: scopes + new_scopes } }
      let(:overlay_params) { { disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"] } }

      it "stores merged scopes on developer key (overlay applied)" do
        subject
        expect(developer_key.reload.scopes).to match_array(new_scopes)
      end

      it "stores merged scopes on tool configuration (overlay applied)" do
        subject
        expect(registration.manual_configuration.reload.scopes).to match_array(new_scopes)
      end

      it "does not create an overlay" do
        expect { subject }.not_to change { Lti::Overlay.count }
      end
    end

    context "left unchanged" do
      it "does not change scopes" do
        expect { subject }.not_to change { developer_key.reload.scopes }
      end
    end
  end

  # TEMPORARY: This test verifies temporary behavior. Remove this when we revert the temporary changes.
  context "with manual registration and overlay" do
    before do
      # Set up the base configuration on the manual configuration
      registration.manual_configuration.update!(
        title: "Base Title",
        description: "Base Description",
        scopes: [
          "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
          "https://purl.imsglobal.org/spec/lti-ags/scope/score"
        ],
        placements: [
          { placement: "course_navigation", text: "Base Course Nav", enabled: true },
          { placement: "account_navigation", text: "Base Account Nav", enabled: true }
        ],
        custom_fields: { base_field: "base_value" }
      )
    end

    let(:configuration_params) do
      # Send the base configuration (this simulates what the frontend sends)
      registration.manual_configuration.internal_lti_configuration
    end

    let(:overlay_params) do
      {
        title: "Overlaid Title",
        description: "Overlaid Description",
        disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/score"],
        disabled_placements: ["account_navigation"],
        placements: {
          course_navigation: {
            text: "Overlaid Course Nav"
          }
        },
        custom_fields: { overlay_field: "overlay_value" }
      }
    end

    it "merges overlay into configuration and does not create an overlay" do
      expect { subject }.not_to change { Lti::Overlay.count }

      # Verify overlay was applied to configuration
      config = registration.manual_configuration.reload
      expect(config.title).to eq("Overlaid Title")
      expect(config.description).to eq("Overlaid Description")
      expect(config.custom_fields).to eq("overlay_field" => "overlay_value")

      # Verify disabled scope was removed
      expect(config.scopes).to eq(["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"])

      # Verify disabled placement was disabled
      account_nav = config.placements.find { |p| p["placement"] == "account_navigation" }
      expect(account_nav["enabled"]).to be(false)

      # Verify placement overlay was applied
      course_nav = config.placements.find { |p| p["placement"] == "course_navigation" }
      expect(course_nav["text"]).to eq("Overlaid Course Nav")
    end

    it "tracks the merged configuration in history" do
      expect { subject }.to change(Lti::RegistrationHistoryEntry, :count).by(1)

      diff = Lti::RegistrationHistoryEntry.last.diff
      expect(diff["internal_lti_configuration"]).to be_present
    end
  end

  context "with dynamic registration and overlay" do
    let(:ims_registration) { lti_ims_registration_model(account:) }
    let(:dynamic_developer_key) do
      DeveloperKey.create!(
        account:,
        is_lti_key: true,
        scopes: [],
        public_jwk_url: "https://example.com/jwk",
        lti_registration: dynamic_registration
      )
    end
    let(:dynamic_registration) do
      Lti::Registration.create!(
        account:,
        ims_registration:,
        name: "Dynamic Registration",
        workflow_state: "active",
        created_by: updated_by,
        updated_by:
      )
    end
    let(:registration) { dynamic_registration }

    before do
      dynamic_developer_key # Ensure developer key is created
    end

    let(:overlay_params) do
      {
        title: "Overlaid Title for Dynamic"
      }
    end

    it "creates an overlay for dynamic registrations" do
      expect { subject }.to change { Lti::Overlay.count }.by(1)

      overlay = Lti::Overlay.find_by(registration:, account:)
      expect(overlay.data).to eq("title" => "Overlaid Title for Dynamic")
    end

    it "does not modify the IMS registration configuration" do
      original_config = ims_registration.internal_lti_configuration
      subject
      expect(ims_registration.reload.internal_lti_configuration).to eq(original_config)
    end
  end
end
