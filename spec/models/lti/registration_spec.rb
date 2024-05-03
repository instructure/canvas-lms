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

RSpec.describe Lti::Registration do
  let(:user) { user_model }
  let(:account) { Account.create! }

  describe "validations" do
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
    it { is_expected.to validate_length_of(:admin_nickname).is_at_most(255) }
    it { is_expected.to validate_length_of(:vendor).is_at_most(255) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to have_one(:ims_registration).class_name("Lti::IMS::Registration").with_foreign_key(:lti_registration_id) }
    it { is_expected.to have_one(:developer_key).class_name("DeveloperKey").inverse_of(:lti_registration).with_foreign_key(:lti_registration_id) }
    it { is_expected.to belong_to(:created_by).class_name("User").optional(true) }
    it { is_expected.to belong_to(:updated_by).class_name("User").optional(true) }
    it { is_expected.to have_many(:lti_registration_account_bindings).class_name("Lti::RegistrationAccountBinding").dependent(:destroy) }
  end

  describe "after_update" do
    let(:developer_key) do
      DeveloperKey.create!(
        name: "test devkey",
        email: "test@test.com",
        redirect_uri: "http://test.com",
        account_id: account.id,
        skip_lti_sync: false
      )
    end
    let(:lti_registration) do
      Lti::Registration.create!(
        developer_key:,
        name: "test registration",
        admin_nickname: "test reg",
        vendor: "test vendor",
        account_id: account.id,
        created_by: user,
        updated_by: user
      )
    end

    it "updates the developer key after updating lti_registration" do
      lti_registration.update!(admin_nickname: "new test name")
      expect(lti_registration.developer_key.name).to eq("new test name")
    end

    it "does not update the developer key if skip_lti_sync is true" do
      expect(Lti::Registration.where(developer_key:).first).to be_nil
    end
  end
end
