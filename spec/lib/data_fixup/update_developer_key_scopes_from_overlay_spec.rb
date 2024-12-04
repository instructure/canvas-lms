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

RSpec.describe DataFixup::UpdateDeveloperKeyScopesFromOverlay do
  subject { DataFixup::UpdateDeveloperKeyScopesFromOverlay.run }

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

  it "should update the Developer Key's scopes" do
    before_scopes = ims_registration.developer_key.scopes

    subject
    expect(ims_registration.developer_key.scopes).to eq(
      before_scopes - registration_overlay["disabledScopes"]
    )
  end

  it "should set a context when an exception is raised" do
    ims_registration.developer_key.scopes
    ims_registration.scopes << "invalid_scope"
    ims_registration.save!(validate: false)
    fake_scope = double(Sentry::Scope)

    expect(fake_scope).to receive(:set_tags).with(registration_global_id: ims_registration.global_id)
    expect(fake_scope).to receive(:set_context).with("exception", anything)
    expect(Sentry).to receive(:with_scope).and_yield(fake_scope)
    ims_registration
    expect { subject }.not_to raise_error
  end

  it "should finish other registrations if one exception is raised" do
    before_scopes = ims_registration.developer_key.scopes
    ims_registration.scopes << "invalid_scope"
    ims_registration.save!(validate: false)

    second_ims_registration = lti_ims_registration_model(account:, registration_overlay:)
    second_before_scopes = second_ims_registration.developer_key.scopes

    subject
    # ims_registration's dev key's scopes should not have changed
    expect(ims_registration.developer_key.scopes).to eq(before_scopes)
    # second_ims_registration's dev key should have updated scopes
    expect(second_ims_registration.developer_key.scopes).to eq(
      second_before_scopes - registration_overlay["disabledScopes"]
    )
  end
end
