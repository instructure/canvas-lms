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

describe DataFixup::ApplyOverlaysToManualRegistrations do
  before do
    allow_any_instance_of(described_class).to receive(:wait_between_jobs)
    allow_any_instance_of(described_class).to receive(:wait_between_processing)
  end

  let(:account) { account_model }
  let(:user) { user_model }

  describe "#process_record" do
    context "with a manual registration with an overlay" do
      let(:registration) do
        lti_registration_with_tool(
          account:,
          created_by: user,
          configuration_params: {
            title: "Original Title",
            description: "Original Description",
            domain: "original.example.com",
            scopes: [
              "https://purl.imsglobal.org/spec/lti-ags/scope/lineitem",
              "https://purl.imsglobal.org/spec/lti-ags/scope/score"
            ],
            custom_fields: { original_field: "original_value" },
            placements: [
              {
                placement: "course_navigation",
                enabled: true,
                message_type: "LtiResourceLinkRequest",
                text: "Original Course Nav"
              },
              {
                placement: "account_navigation",
                enabled: true,
                message_type: "LtiResourceLinkRequest",
                text: "Original Account Nav"
              }
            ]
          }
        )
      end

      # Manually create the overlay since the helper now merges overlays immediately
      let(:overlay_data) do
        {
          title: "Overlaid Title",
          description: "Overlaid Description",
          domain: "overlay.example.com",
          disabled_scopes: ["https://purl.imsglobal.org/spec/lti-ags/scope/score"],
          custom_fields: { overlay_field: "overlay_value" },
          disabled_placements: ["account_navigation"],
          placements: {
            course_navigation: {
              text: "Overlaid Course Nav",
              icon_url: "https://example.com/overlay-icon.png"
            }
          }
        }
      end

      before do
        # Create the overlay manually for this test
        lti_overlay_model(
          registration:,
          account:,
          data: overlay_data,
          updated_by: user
        )
      end

      it "applies the overlay to the manual configuration" do
        expect(registration.manual_configuration).not_to be_nil

        described_class.new.process_record(registration)

        tool_config = registration.manual_configuration.reload

        # Verify overlay values were applied
        expect(tool_config.title).to eq("Overlaid Title")
        expect(tool_config.description).to eq("Overlaid Description")
        expect(tool_config.domain).to eq("overlay.example.com")

        # Verify custom fields were merged
        expect(tool_config.custom_fields).to eq("overlay_field" => "overlay_value")

        # Verify disabled scope was removed
        expect(tool_config.scopes).to eq(["https://purl.imsglobal.org/spec/lti-ags/scope/lineitem"])

        # Verify placement overlay was applied
        course_nav = tool_config.placements.find { |p| p["placement"] == "course_navigation" }
        expect(course_nav["text"]).to eq("Overlaid Course Nav")
        expect(course_nav["icon_url"]).to eq("https://example.com/overlay-icon.png")

        # Verify disabled placement was disabled
        account_nav = tool_config.placements.find { |p| p["placement"] == "account_navigation" }
        expect(account_nav["enabled"]).to be(false)
      end

      it "clears the overlay data" do
        overlay = registration.lti_overlays.first
        expect(overlay.data).not_to be_empty

        described_class.new.process_record(registration)

        overlay.reload
        expect(overlay.data).to eq({})
      end
    end

    context "with a manual registration without an overlay" do
      let(:registration) do
        lti_registration_with_tool(
          account:,
          created_by: user,
          overlay_params: {}
        )
      end

      it "does not modify the manual configuration" do
        expect(registration.manual_configuration).not_to be_nil

        original_title = registration.manual_configuration.title
        original_config = registration.manual_configuration.internal_lti_configuration

        described_class.new.process_record(registration)

        tool_config = registration.manual_configuration.reload
        expect(tool_config.title).to eq(original_title)
        expect(tool_config.internal_lti_configuration).to eq(original_config)
      end
    end

    context "with a manual registration with an empty overlay" do
      let(:registration) do
        lti_registration_with_tool(
          account:,
          created_by: user,
          overlay_params: {}
        )
      end

      before do
        # Manually create an empty overlay
        lti_overlay_model(
          registration:,
          account:,
          data: {},
          updated_by: user
        )
      end

      it "does not modify the manual configuration" do
        original_title = registration.manual_configuration.title

        described_class.new.process_record(registration)

        tool_config = registration.manual_configuration.reload
        expect(tool_config.title).to eq(original_title)
      end
    end

    context "with a dynamic registration with an overlay" do
      let(:ims_registration) { lti_ims_registration_model(account:) }
      let(:registration) do
        lti_registration_model(
          account:,
          ims_registration:,
          created_by: user,
          overlay: {
            title: "Overlaid Title for Dynamic",
            description: "Should not be applied"
          }
        )
      end

      it "does not modify the dynamic registration" do
        expect(registration.manual_configuration).to be_nil
        expect(registration.ims_registration).not_to be_nil

        # The scope filters out registrations without a manual_configuration,
        # so this should not be processed. But if it somehow gets through:
        expect { described_class.new.process_record(registration) }.not_to raise_error

        # Verify overlay was not cleared (dynamic registrations still use overlays)
        overlay = registration.lti_overlays.first
        expect(overlay.data).not_to be_empty
      end
    end

    context "with additive placements" do
      let(:registration) do
        lti_registration_with_tool(
          account:,
          created_by: user,
          configuration_params: {
            placements: [
              {
                placement: "course_navigation",
                enabled: true,
                message_type: "LtiResourceLinkRequest",
                text: "Course Nav"
              }
            ]
          }
        )
      end

      before do
        # Create the overlay manually for this test
        lti_overlay_model(
          registration:,
          account:,
          data: {
            placements: {
              course_navigation: {
                text: "Updated Course Nav"
              },
              account_navigation: {
                text: "New Account Nav",
                enabled: true,
                message_type: "LtiResourceLinkRequest"
              }
            }
          },
          updated_by: user
        )
      end

      it "adds new placements from overlay" do
        # Should start with just course_navigation
        expect(registration.manual_configuration.placements.count).to eq(1)

        described_class.new.process_record(registration)

        tool_config = registration.manual_configuration.reload

        # Should have both placements now (additive: true for manual configs)
        expect(tool_config.placements.count).to be >= 2

        course_nav = tool_config.placements.find { |p| p["placement"] == "course_navigation" }
        expect(course_nav["text"]).to eq("Updated Course Nav")

        account_nav = tool_config.placements.find { |p| p["placement"] == "account_navigation" }
        expect(account_nav).not_to be_nil
        expect(account_nav["text"]).to eq("New Account Nav")
      end
    end

    context "when tool configuration update fails" do
      let(:registration) do
        lti_registration_with_tool(
          account:,
          created_by: user
        )
      end

      before do
        # Create the overlay manually for this test
        lti_overlay_model(
          registration:,
          account:,
          data: { title: "New Title" },
          updated_by: user
        )
      end

      it "logs the error and continues" do
        allow_any_instance_of(Lti::ToolConfiguration).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(registration.manual_configuration))

        expect { described_class.new.process_record(registration) }.not_to raise_error

        # Overlay should not be cleared if update failed
        overlay = registration.lti_overlays.first
        expect(overlay.reload.data).not_to be_empty
      end
    end
  end

  describe ".run" do
    before do
      # Create multiple types of registrations
      @manual_with_overlay = lti_registration_with_tool(
        account:,
        created_by: user
      )

      # Manually create the overlay for the manual registration
      lti_overlay_model(
        registration: @manual_with_overlay,
        account:,
        data: { title: "Overlay Title 1" },
        updated_by: user
      )

      @manual_without_overlay = lti_registration_with_tool(
        account:,
        created_by: user
      )

      # Dynamic registration (should be skipped by scope)
      ims_reg = lti_ims_registration_model(account:)
      @dynamic_with_overlay = lti_registration_model(
        account:,
        ims_registration: ims_reg,
        created_by: user
      )

      # Manually create the overlay for the dynamic registration
      lti_overlay_model(
        registration: @dynamic_with_overlay,
        account:,
        data: { title: "Dynamic Overlay" },
        updated_by: user
      )
    end

    it "processes only manual registrations with overlays" do
      described_class.new.run

      # Manual with overlay should have overlay applied and cleared
      @manual_with_overlay.reload
      overlay1 = @manual_with_overlay.lti_overlays.first
      expect(@manual_with_overlay.manual_configuration.title).to eq("Overlay Title 1")
      expect(overlay1.data).to eq({})

      # Manual without overlay should be unchanged
      @manual_without_overlay.reload
      expect(@manual_without_overlay.lti_overlays).to be_empty

      # Dynamic registration should be unchanged (not processed by scope)
      @dynamic_with_overlay.reload
      overlay3 = @dynamic_with_overlay.lti_overlays.first
      expect(overlay3.data).not_to be_empty
    end
  end
end
