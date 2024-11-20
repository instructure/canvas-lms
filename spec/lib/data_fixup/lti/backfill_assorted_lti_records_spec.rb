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

RSpec.describe DataFixup::Lti::BackfillAssortedLtiRecords do
  subject { DataFixup::Lti::BackfillAssortedLtiRecords.run }

  let(:developer_key) do
    key = dev_key_model_1_3(account:)
    key.update!(workflow_state: "deleted")
    reg = key.lti_registration
    key.update(lti_registration: nil, skip_lti_sync: true)
    key.tool_configuration.update(lti_registration: nil)
    reg.delete
    key.developer_key_account_bindings.first.lti_registration_account_binding.delete
    key
  end
  let(:ims_registration) do
    r = lti_ims_registration_model(registration_overlay:, developer_key:)
    r.update_column(:lti_registration_id, nil)
    r
  end
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

  it "does not error with deleted DeveloperKey and unlinked IMS Registration" do
    expect(developer_key).to be_deleted
    expect(ims_registration.lti_registration_id).to be_nil
    expect(Sentry).not_to receive(:capture_message)

    # expect { subject }.not_to raise_error
    subject

    expect(developer_key.reload).to be_deleted
    expect(ims_registration.reload.lti_registration).to be_present
    expect(developer_key.lti_registration).to be_present
    expect(developer_key.tool_configuration.lti_registration).to be_present
    expect(developer_key.lti_registration.ims_registration).to eq(ims_registration)
    expect(developer_key.lti_registration.lti_overlays).not_to be_empty
    expect(developer_key.lti_registration.lti_registration_account_bindings).not_to be_empty
  end
end
