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

describe DataFixup::SyncLtiRegistrationCreatedAtFromDeveloperKey do
  describe "#execute" do
    subject { described_class.new.run }

    let(:account) { account_model }

    it "syncs created_at from developer key to lti registration when more than one hour different" do
      registration = lti_registration_with_tool(account:)

      dev_key_time = 2.days.ago
      developer_key = registration.developer_key
      developer_key.update_column(:created_at, dev_key_time)

      # make sure the dates are different before the fixup
      expect(registration.reload.created_at).not_to eq(developer_key.reload.created_at)

      subject

      # verify the dates now match
      expect(registration.reload.created_at).to eq(developer_key.reload.created_at)
    end

    it "does not update registrations whose created_at dates already match" do
      registration = lti_registration_with_tool(account:)

      original_created_at = registration.created_at

      subject

      # verify nothing changed
      expect(registration.reload.created_at).to eq(original_created_at)
    end

    it "does not update registrations whose created_at is within one hour" do
      registration = lti_registration_with_tool(account:)

      dev_key_time = 30.minutes.ago
      developer_key = registration.developer_key
      developer_key.update_column(:created_at, dev_key_time)

      original_created_at = registration.created_at

      # make sure the dates are different before the fixup
      expect(registration.reload.created_at).not_to eq(developer_key.reload.created_at)

      subject

      # verify the registration was not updated (dates are within tolerance)
      expect(registration.reload.created_at).to eq(original_created_at)
    end

    it "handles registrations without developer keys" do
      # create a registration without a developer key
      lti_reg = Lti::Registration.create!(
        name: "a registration with no dev key",
        account:
      )

      original_created_at = lti_reg.created_at

      # Run the fixup - should not fail and should not update
      expect { subject }.not_to raise_error
      expect(lti_reg.reload.created_at).to eq(original_created_at)
    end
  end
end
