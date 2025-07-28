# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Lti::Overlay do
  let(:account) { account_model }
  let(:updated_by) { user_model }
  let(:data) { { "title" => "Hello World!" } }
  let(:registration) { lti_registration_model(account:, updated_by:) }

  describe "create_version callback" do
    let(:overlay) { Lti::Overlay.create!(account:, registration:, updated_by:, data:) }

    it "doesn't create a new version if data hasn't changed" do
      expect { overlay.update!(data:) }.not_to change { overlay.lti_overlay_versions.count }
      expect { overlay.update!(updated_by: user_model) }.not_to change { overlay.lti_overlay_versions.count }
    end

    it "creates a new version if data is modified" do
      expect { overlay.update!(data: { "description" => "a description" }) }.to change { overlay.lti_overlay_versions.count }.by(1)
    end

    it "stores a diff of the old and new data" do
      overlay.update!(data: { "description" => "a description" })

      expect(Lti::OverlayVersion.last.diff).to eq([
                                                    ["-", "title", "Hello World!"],
                                                    ["+", "description", "a description"]
                                                  ])
    end

    it "doesn't care about ordering in arrays" do
      expect do
        overlay.update!(data: overlay.data.merge({ "disabled_placements" => ["course_navigation", "account_navigation"] }))
      end.to change { overlay.lti_overlay_versions.count }.by(1)

      expect { overlay.update!(data: overlay.data.merge({ "disabled_placements" => ["account_navigation", "course_navigation"] })) }.not_to change { overlay.lti_overlay_versions.count }
    end

    it "doesn't create a new version if updated_by is updated but data isn't" do
      expect { overlay.update!(updated_by: user_model) }.not_to change { overlay.lti_overlay_versions.count }
    end
  end

  describe "create!" do
    context "without account" do
      it "fails" do
        expect { Lti::Overlay.create!(registration:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "without registration" do
      it "fails" do
        expect { Lti::Overlay.create!(account:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "with invalid data" do
      let(:data) do
        {
          disabled_placements: ["invalid_placement"]
        }.deep_stringify_keys
      end

      it "fails" do
        expect { Lti::Overlay.create!(registration:, account:, updated_by:, data:) }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it "returns the schema errors" do
        overlay = Lti::Overlay.build(registration:, account:, updated_by:, data:)
        overlay.save

        expect(JSON.parse(overlay.errors[:data].first).first).to include "is not one of"
      end
    end

    context "with a nil attribute" do
      let(:data) { { domain: nil } }

      it "succeeds" do
        expect { Lti::Overlay.create!(registration:, account:, updated_by:, data:) }.not_to raise_error
      end

      it "does not store it" do
        overlay = Lti::Overlay.create!(registration:, account:, updated_by:, data:)
        expect(overlay.data).not_to have_key("domain")
      end
    end

    context "with all valid attributes" do
      it "succeeds" do
        expect { Lti::Overlay.create!(registration:, account:, updated_by:, data:) }.not_to raise_error
      end
    end

    context "with cross-shard registration" do
      specs_require_sharding

      let(:account) { @shard2.activate { account_model } }
      let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
      let(:updated_by) { @shard2.activate { user_model } }

      it "succeeds" do
        expect { @shard2.activate { Lti::Overlay.create!(registration:, account:, updated_by:) } }.not_to raise_error
      end
    end
  end

  describe "self.apply_to" do
    subject { Lti::Overlay.apply_to(data, internal_config) }

    let(:developer_key) { lti_developer_key_model(account:) }
    let(:tool_configuration) { lti_tool_configuration_model(developer_key:, lti_registration: developer_key.lti_registration) }
    let(:internal_config) { tool_configuration.reload.internal_lti_configuration.with_indifferent_access }
    let(:data) do
      {
        title: "Hello world!",
        description: "a great description",
        custom_fields: { "foo" => "example" },
        target_link_uri: "https://example.com/launch",
        oidc_initiation_url: "https://example.com/initiate",
        domain: "example.com",
        privacy_level: "email_only",
        disabled_scopes: [TokenScopes::LTI_AGS_SCORE_SCOPE],
        disabled_placements: ["course_navigation"],
        placements: {
          module_index_menu: {
            icon_url: "https://example.com/module_index_menu.png"
          }
        }
      }
    end
    let(:root_keys) { Schemas::Lti::Overlay::ROOT_KEYS }

    it "overlays top-level keys properly" do
      expect(subject.slice(root_keys)).to eq(data.slice(root_keys).with_indifferent_access)
    end

    it "returns a valid InternalLtiConfiguration" do
      expect(Schemas::InternalLtiConfiguration.simple_validation_errors(subject)).to be_blank
    end

    it "returns a HashWithIndifferentAccess" do
      expect(subject).to be_a(ActiveSupport::HashWithIndifferentAccess)
    end

    context "overlaying disabled_scopes" do
      let(:scopes) { [TokenScopes::LTI_AGS_SHOW_PROGRESS_SCOPE, TokenScopes::LTI_ACCOUNT_LOOKUP_SCOPE] }
      let(:data) do
        {
          disabled_scopes: [TokenScopes::LTI_AGS_SHOW_PROGRESS_SCOPE]
        }
      end

      it "removes the scope from the list of scopes" do
        expect(subject[:scopes]).not_to include(TokenScopes::LTI_AGS_SHOW_PROGRESS_SCOPE)
      end
    end

    context "overlaying disabled_placements" do
      let(:data) do
        {
          disabled_placements: ["course_navigation"]
        }
      end

      it "marks the placement as disabled" do
        expect(subject[:placements].find { |p| p[:placement] == "course_navigation" }[:enabled]).to be(false)
      end

      context "the placement is also in the placements hash as enabled" do
        let(:data) do
          super().tap do |d|
            d[:placements] = { course_navigation: { icon_url: "https://example.com", enabled: true } }
          end
        end

        it "still marks the placement as disabled" do
          expect(subject[:placements].find { |p| p[:placement] == "course_navigation" }[:enabled]).to be(false)
        end
      end
    end

    context "overlaying launch_settings" do
      let(:data) do
        {
          # If we ever overlay more launch_settings, they should be added here for testing
          custom_fields: { "foo" => "totally rad" },
          target_link_uri: "https://example.com/neato"
        }
      end

      it "overlays properly" do
        expect(subject[:launch_settings]).to include(data)
      end
    end

    context "adding additional placements" do
      let(:data) do
        super().tap do |s|
          s[:placements] = { global_navigation: { enabled: true, icon_url: "https://example.com/global" } }
        end
      end

      it "should add the new placements" do
        expect(subject[:placements].pluck(:placement)).to include("global_navigation")
      end
    end

    context "overriding placement config options" do
      let(:data) do
        super().tap do |s|
          s[:placements] = { course_navigation: { default: "disabled", icon_url: "https://example.com/totally_different" } }
        end
      end

      it "uses the overlay to modify tool-configured placements" do
        course = subject[:placements].find { |p| p[:placement] == "course_navigation" }
        expect(course[:default]).to eq("disabled")
        expect(course[:icon_url]).to eq("https://example.com/totally_different")
      end

      it "doesn't modify the original placement config" do
        expect { subject }.not_to change { internal_config[:placements].find { |p| p[:placement] == "course_navigation" } }
      end
    end

    context "no data in the overlay" do
      let(:data) { nil }

      it "returns the internal config unchanged" do
        expect(subject).to eq(internal_config.with_indifferent_access)
      end

      it "returns a HashWithIndifferentAccess" do
        expect(subject).to be_a(ActiveSupport::HashWithIndifferentAccess)
      end
    end
  end
end
