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

describe DataFixup::PopulateSamlMetadata do
  before do
    skip("requires SAML extension") unless AuthenticationProvider::SAML.enabled?
  end

  it "scopes to SAML providers without metadata in settings" do
    account = Account.create!(name: "test")
    with_metadata = account.authentication_providers.create!(auth_type: "saml")
    without_metadata = account.authentication_providers.create!(auth_type: "saml")
    settings = without_metadata.settings.except("metadata")
    without_metadata.update_column(:settings, settings)

    scope = described_class.new.send(:scope)
    expect(scope).to include(without_metadata)
    expect(scope).not_to include(with_metadata)
  end

  it "populates metadata on a SAML provider that has none" do
    account = Account.create!(name: "test")
    aac = account.authentication_providers.create!(auth_type: "saml", idp_entity_id: "https://idp.example.com")
    # Clear metadata to simulate a pre-existing record
    settings = aac.settings.except("metadata")
    aac.update_column(:settings, settings)

    expect(aac.reload.settings["metadata"]).to be_blank

    described_class.new.process_record(aac)
    aac.reload

    expect(aac.settings["metadata"]).to be_present
    expect(aac.settings["metadata_source"]).to eq("generated")
    expect(aac.settings["metadata"]).to include("https://idp.example.com")
  end
end
