# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

RSpec.describe DataFixup::Lti::BackfillLtiOverlaysFromIMSRegistrations do
  subject { DataFixup::Lti::BackfillLtiOverlaysFromIMSRegistrations.run }

  let(:ims_registration) { lti_ims_registration_model(account:, registration_overlay:) }
  let(:account) { account_model }
  let(:registration_overlay) do
    {
      "title" => "foobarbaz",
      "disabledScopes" => [TokenScopes::LTI_AGS_SCORE_SCOPE, TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE],
      "disabledPlacements" => ["course_navigation"],
      "icon_url" => "https://example.com/root_level.png",
      "placements" => [
        {
          "type" => "account_navigation",
          "launch_height" => "400",
          "launch_width" => "300",
          "icon_url" => "https://www.example.com/icon.png",
        },
        {
          "type" => "course_navigation",
          "default" => "disabled"
        }
      ]
    }
  end

  it "should create an Lti::Overlay" do
    ims_registration
    expect { subject }.to change { Lti::Overlay.count }.by(1)
  end

  it "should convert the overlay properly" do
    ims_registration
    subject
    expect(Lti::Overlay.last.data).to eq(
      {
        "disabled_scopes" => [
          TokenScopes::LTI_AGS_SCORE_SCOPE,
          TokenScopes::LTI_AGS_RESULT_READ_ONLY_SCOPE
        ].sort,
        "disabled_placements" => ["course_navigation"],
        "title" => "foobarbaz",
        "placements" => {
          "account_navigation" => {
            "launch_height" => 400,
            "launch_width" => 300,
            "icon_url" => "https://www.example.com/icon.png"
          },
          "course_navigation" => {
            "default" => "disabled",
            "icon_url" => "https://example.com/root_level.png"
          }
        }
      }
    )
    expect(Lti::Overlay.last.account).to eq(account)
    expect(Lti::Overlay.last.registration).to eq(ims_registration.lti_registration)
  end

  it "should set a context when an exception is raised" do
    fake_scope = double(Sentry::Scope)

    expect(fake_scope).to receive(:set_tags).with(ims_registration_global_id: ims_registration.global_id)
    expect(fake_scope).to receive(:set_context).with("exception", { name: "ArgumentError", message: "ArgumentError" })
    expect(Sentry).to receive(:with_scope).and_yield(fake_scope)
    expect(Schemas::Lti::IMS::RegistrationOverlay).to receive(:to_lti_overlay).and_raise(ArgumentError)
    ims_registration
    expect { subject }.not_to raise_error
  end

  it "should finish other registrations if one exception is raised" do
    ims_registration.registration_overlay["disabledPlacements"] << "invalid_placement"
    ims_registration.save!(validate: false)
    second_ims_registration = lti_ims_registration_model(account:, registration_overlay:)

    subject
    # ims_registration has the invalid placement; overlay shouldn't have been created
    expect(ims_registration.lti_registration.lti_overlays.count).to eq(0)
    # second_ims_registration should have had an overlay created
    expect(second_ims_registration.lti_registration.lti_overlays.count).to eq(1)
  end
end
