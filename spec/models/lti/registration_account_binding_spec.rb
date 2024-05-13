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

RSpec.describe Lti::RegistrationAccountBinding do
  describe "validations" do
    it { is_expected.to belong_to(:registration).class_name("Lti::Registration").optional(false).inverse_of(:lti_registration_account_bindings) }
    it { is_expected.to belong_to(:account).class_name("Account").optional(false).inverse_of(:lti_registration_account_bindings) }
    it { is_expected.to belong_to(:created_by).class_name("User").inverse_of(:created_lti_registration_account_bindings) }
    it { is_expected.to belong_to(:updated_by).class_name("User").inverse_of(:updated_lti_registration_account_bindings) }
    it { is_expected.to belong_to(:developer_key_account_binding).class_name("DeveloperKeyAccountBinding") }
  end

  describe "after_save hooks" do
    let(:lrab) do
      account = account_model
      user = user_model
      registration = Lti::Registration.create!(
        name: "an lti registration",
        account:,
        created_by: user,
        updated_by: user
      )
      Lti::RegistrationAccountBinding.create!(
        workflow_state: :off,
        account:,
        registration:
      )
    end

    it "updates the corresponding developer key account binding" do
      dev_key_account_binding = DeveloperKeyAccountBinding.create!(
        workflow_state: lrab.workflow_state,
        developer_key: developer_key_model,
        account: lrab.account,
        lti_registration_account_binding: lrab
      )

      lrab.update!(workflow_state: :on)
      expect(dev_key_account_binding.reload.workflow_state).to eq("on")
    end
  end

  describe "#destroy" do
    subject { account_binding.destroy }

    let(:account_binding) { lti_registration_account_binding_model }

    it "sets workflow_state to deleted" do
      subject
      expect(account_binding.workflow_state).to eq("deleted")
    end
  end

  describe "#undestroy" do
    subject { account_binding.undestroy }

    let(:account_binding) { lti_registration_account_binding_model }

    it "sets workflow_state to off" do
      subject
      expect(account_binding.workflow_state).to eq("off")
    end

    context "when active_state is provided" do
      subject { account_binding.undestroy(active_state: "on") }

      it "sets workflow_state to the provided state" do
        subject
        expect(account_binding.workflow_state).to eq("on")
      end
    end
  end

  describe "#destroy_permanently!" do
    subject { account_binding.destroy_permanently! }

    let(:account_binding) { lti_registration_account_binding_model }

    it "hard deletes binding" do
      subject
      expect(Lti::RegistrationAccountBinding.find_by(id: account_binding.id)).to be_nil
    end
  end
end
