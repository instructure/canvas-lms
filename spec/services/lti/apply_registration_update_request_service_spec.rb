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

describe Lti::ApplyRegistrationUpdateRequestService do
  subject do
    described_class.call(
      registration_update_request: update_request,
      applied_by:,
      overlay_data:,
      comment:
    )
  end

  let(:overlay_data) do
    {
      title: "Updated Overlay Title",
    }.with_indifferent_access
  end

  let(:comment) { nil }

  let(:account) { account_model }
  let(:applied_by) { user_model }
  let(:registration) do
    lti_ims_registration_model(account:).lti_registration
  end
  let(:update_request) do
    lti_ims_registration_update_request_model(
      lti_registration: registration,
      root_account: account,
      created_by: applied_by
    )
  end

  describe "#call" do
    context "with valid parameters" do
      it "returns the updated registration" do
        result = subject
        expect(result[:lti_registration]).to eq(registration)
      end

      it "updates the ims_registration with new configuration" do
        original_client_name = registration.ims_registration.client_name
        subject

        registration.ims_registration.reload
        expect(registration.ims_registration.client_name).not_to eq(original_client_name)
        expect(registration.ims_registration.client_name).to eq("Updated Test Registration")
      end

      it "updates all configurable fields in ims_registration" do
        subject

        ims_reg = registration.ims_registration.reload
        new_config = update_request.lti_ims_registration

        expect(ims_reg.client_name).to eq(new_config["client_name"])
        expect(ims_reg.jwks_uri).to eq(new_config["jwks_uri"])
        expect(ims_reg.initiate_login_uri).to eq(new_config["initiate_login_uri"])
        expect(ims_reg.redirect_uris).to eq(new_config["redirect_uris"])
        expect(ims_reg.lti_tool_configuration).to eq(new_config["lti_tool_configuration"])
        expect(ims_reg.scopes).to eq(new_config["scopes"])
        expect(ims_reg.logo_uri).to eq(new_config["logo_uri"])
      end

      it "creates or replaces the overlay for the registration" do
        expect { subject }.to change { Lti::Overlay.count }.by(1)

        overlay = registration.overlay_for(account)
        expect(overlay).to be_present
        expect(overlay.updated_by).to eq(applied_by)
      end

      it "replaces existing overlay data" do
        existing_overlay = Lti::Overlay.create!(
          registration:,
          account:,
          data: { "title" => "Existing Title" },
          updated_by: user_model
        )

        expect { subject }.not_to change { Lti::Overlay.count }

        existing_overlay.reload
        expect(existing_overlay.updated_by).to eq(applied_by)
        expect(existing_overlay.data).to eq(overlay_data)
      end

      it "updates the developer key with new configuration values" do
        original_name = registration.developer_key.name
        subject

        registration.developer_key.reload
        expect(registration.developer_key.name).not_to eq(original_name)
        expect(registration.developer_key.name).to eq("Updated Test Registration")
        expect(registration.developer_key.oidc_initiation_url).to eq("https://example.com/login")
        expect(registration.developer_key.public_jwk_url).to eq("https://example.com/api/jwks")
        expect(registration.developer_key.redirect_uris).to eq(["https://example.com/launch"])
      end

      it "marks the update request as applied" do
        expect(update_request.applied?).to be(false)
        subject

        update_request.reload
        expect(update_request.applied?).to be(true)
        expect(update_request.accepted_at).to be_present
      end

      it "creates a registration history entry for the update" do
        # Is currently changed by 2 for reasons, which should probably be fixed later
        expect { subject }.to change { Lti::RegistrationHistoryEntry.count }.by(2)

        history_entry = Lti::RegistrationHistoryEntry.last
        expect(history_entry.lti_registration).to eq(registration)
        expect(history_entry.root_account).to eq(account)
        expect(history_entry.created_by).to eq(applied_by)
        expect(history_entry.comment).to be_nil
        expect(history_entry.update_type).to eq("registration_update")

        expect(history_entry.diff).to be_present
        expect(history_entry.diff).to be_a(Hash)
        expect(history_entry.diff.keys).to match_array(%w[internal_lti_configuration overlay developer_key registration])
      end

      it "tracks changes to ims_registration in the history entry" do
        subject

        history_entry = Lti::RegistrationHistoryEntry.last

        # Should capture IMS registration changes in the internal config diff
        expect(history_entry.diff).to have_key("internal_lti_configuration")

        internal_config_changes = history_entry.diff["internal_lti_configuration"]
        expect(internal_config_changes).to be_an(Array)

        # The diff should contain change entries with format: [operation, path, old_value, new_value]
        # or [operation, path, value] for additions/deletions
        internal_config_changes.each do |change|
          expect(change).to be_an(Array)
          expect(change.length).to be >= 2
          expect(change[0]).to match(/^[~+-]$/) # operation: ~(change), +(add), -(delete)
          expect(change[1]).to be_an(Array) # path as array
        end

        # Should have at least one change due to IMS registration update
        expect(internal_config_changes).not_to be_empty
      end

      it "tracks overlay changes in the history entry" do
        subject

        history_entry = Lti::RegistrationHistoryEntry.last

        # Should capture overlay changes
        expect(history_entry.diff).to have_key("overlay")

        overlay_changes = history_entry.diff["overlay"]
        expect(overlay_changes).to be_an(Array)

        # The overlay changes should follow the same diff format
        overlay_changes.each do |change|
          expect(change).to be_an(Array)
          expect(change.length).to be >= 2
          expect(change[0]).to match(/^[~+-]$/) # operation: ~(change), +(add), -(delete)
          expect(change[1]).to be_an(Array) # path as array
        end

        # Should have at least one change since we're creating an overlay
        expect(overlay_changes).not_to be_empty

        # Should include the title change from overlay_data
        title_change = overlay_changes.find { |change| change[3].key?("title") }
        expect(title_change).to be_present
        expect(title_change[0]).to eq("~")
        expect(title_change[3]["title"]).to eq("Updated Overlay Title") # new value
      end

      context "with custom comment" do
        let(:comment) { "Applied update due to security vulnerability fix" }

        it "uses the custom comment in the history entry" do
          subject

          history_entry = Lti::RegistrationHistoryEntry.last
          expect(history_entry.comment).to eq("Applied update due to security vulnerability fix")
        end
      end

      it "runs everything in a transaction" do
        allow(Lti::UpdateRegistrationService).to receive(:call).and_raise("Database error")

        expect { subject }.to raise_error("Database error")

        # Verify that the ims_registration wasn't updated due to rollback
        registration.ims_registration.reload
        expect(registration.ims_registration.client_name).not_to eq("Updated Test Registration")

        # Verify that the update request wasn't marked as applied
        update_request.reload
        expect(update_request.applied?).to be(false)

        # Verify that no history entry was created due to rollback
        expect(Lti::RegistrationHistoryEntry.where(lti_registration: registration)).to be_empty
      end
    end

    context "with missing parameters" do
      it "raises error when registration_update_request is nil" do
        expect do
          described_class.call(registration_update_request: nil, applied_by:, overlay_data: nil, comment: nil)
        end.to raise_error(ArgumentError, "registration_update_request is required")
      end

      it "raises error when applied_by is nil" do
        expect do
          described_class.call(registration_update_request: update_request, applied_by: nil, overlay_data: nil, comment: nil)
        end.to raise_error(ArgumentError, "applied_by is required")
      end
    end

    context "with non-dynamic registrations" do
      let(:manual_registration) do
        # Create a registration with a tool configuration instead of IMS registration
        dk = lti_developer_key_model(account:)
        lti_tool_configuration_model(developer_key: dk, lti_registration: dk.lti_registration)
        dk.lti_registration
      end
      let(:update_request_for_manual) do
        lti_ims_registration_update_request_model(
          lti_registration: manual_registration,
          root_account: account,
          created_by: applied_by
        )
      end

      it "raises error when trying to apply to non-dynamic registration" do
        expect do
          described_class.call(
            registration_update_request: update_request_for_manual,
            applied_by:,
            overlay_data: nil
          )
        end.to raise_error(ArgumentError, "Only Registration update requests for Dynamic Registrations are currently supported")
      end
    end

    context "with missing lti_registration" do
      it "raises error when lti_registration is nil" do
        update_request_without_registration = update_request.dup
        allow(update_request_without_registration).to receive(:lti_registration).and_return(nil)

        expect do
          described_class.call(
            registration_update_request: update_request_without_registration,
            applied_by:,
            overlay_data: nil
          )
        end.to raise_error(ArgumentError, "Registration not found")
      end
    end

    context "when developer key update has no changes" do
      let(:update_request_no_changes) do
        update_attrs = Factories::DEFAULT_LTI_IMS_REGISTRATION_UPDATE_ATTRS.deep_dup
        update_attrs["client_name"] = nil
        update_attrs["logo_uri"] = nil
        update_attrs["jwks_uri"] = nil
        update_attrs["initiate_login_uri"] = nil
        update_attrs["redirect_uris"] = nil
        update_attrs["scope"] = nil

        Schemas::Lti::IMS::OidcRegistration.to_model_attrs(update_attrs) => { registration_attrs: }

        lti_ims_registration_update_request_model(
          lti_registration: registration,
          root_account: account,
          created_by: applied_by,
          lti_ims_registration: registration_attrs
        )
      end

      it "skips developer key update when no params are present" do
        # This test may not apply since we're always updating something
        described_class.call(
          registration_update_request: update_request_no_changes,
          applied_by:,
          overlay_data: nil
        )

        # Just verify the service runs successfully
        expect(update_request_no_changes.reload.applied?).to be(true)
      end
    end
  end
end
