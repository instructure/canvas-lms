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

RSpec.describe DataFixup::Lti::BackfillLtiRegistrationAccountBindings do
  let(:dev_key) do
    dev_key = lti_developer_key_model(account:)
    dev_key
  end
  let(:account) { account_model }

  it "backfills the lti_registration_account_bindings table" do
    # Asserts that we skip any syncing to avoid extraneous updates to the dev key on
    # reg account binding creation
    expect(DeveloperKeyAccountBinding).not_to receive(:update)
    dev_key
    expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(1)
    expect(Lti::RegistrationAccountBinding.last.account).to eq(account)
    expect(Lti::RegistrationAccountBinding.last.registration).to eq(dev_key.lti_registration)
  end

  it "copies the workflow state of the dev key account binding" do
    dev_key.account_binding_for(account).update_column(:workflow_state, "off")
    expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(1)
    expect(Lti::RegistrationAccountBinding.last.workflow_state).to eq(dev_key.account_binding_for(account).workflow_state)
  end

  context "an error occurs while saving a new account binding" do
    let(:scope) { double("scope") }

    it "captures the error using Sentry" do
      expect(Sentry).to receive(:with_scope).and_yield(scope)
      expect(Sentry).to receive(:capture_message)
        .with("DataFixup#backfill_lti_registration_account_bindings", { level: :warning })
      expect(scope).to receive(:set_tags).with(developer_key_account_binding_id: dev_key.account_binding_for(account).global_id)
      expect(scope).to receive(:set_context)
        .with("exception", { name: "StandardError", message: "whoops!" })

      allow(Lti::RegistrationAccountBinding).to receive(:create!).and_raise(StandardError.new("whoops!"))

      dev_key

      expect { described_class.run }.not_to raise_error
    end
  end

  context "the dev key doesn't have an lti registration" do
    before do
      dev_key.update!(lti_registration: nil, skip_lti_sync: true)
    end

    it "doesn't create a binding" do
      expect { described_class.run }.not_to change { Lti::RegistrationAccountBinding.count }
      expect(dev_key.reload.lti_registration).to be_nil
    end
  end

  context "when there are also API keys" do
    let(:api_key) { dev_key_model(account:) }

    it "backfills the lti_registration_account_bindings table" do
      dev_key
      api_key
      expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(1)
      expect(Lti::RegistrationAccountBinding.last.account).to eq(account)
      expect(Lti::RegistrationAccountBinding.last.registration).to eq(dev_key.lti_registration)
      expect(api_key.reload.lti_registration).to be_nil
    end
  end

  context "when there are some LTI keys that already have a registration account binding" do
    let(:other_key) { lti_developer_key_model(account:) }

    it "doesn't create any new bindings and runs successfully" do
      expect { described_class.run }.not_to change { Lti::RegistrationAccountBinding.count }
    end
  end

  context "when the developer key is for a non-root account" do
    let(:subaccount) { account_model(parent_account: account) }
    let!(:binding) { DeveloperKeyAccountBinding.create!(account: subaccount, developer_key: dev_key, workflow_state: "on") }

    it "skips the account binding" do
      # should just move on to the next account binding and not log an error
      expect(Sentry).not_to receive(:with_scope)
      # should create one LRAB for the dev key created at the top of this spec file,
      # but not two. should skip the subaccount one created in this context block.
      expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(1)
      expect(binding.lti_registration_account_binding).to be_nil
    end
  end

  context "when dealing with inherited account bindings" do
    let(:site_admin_key) do
      key = lti_developer_key_model(account: Account.site_admin)
      key.update!(account: nil)
      key
    end

    it "backfills successfully" do
      site_admin_key
      expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(1)
      expect(site_admin_key.reload.lti_registration.account_binding_for(Account.site_admin)).to eq(Lti::RegistrationAccountBinding.last)
    end

    context "and there's a site admin and root account level binding" do
      let(:root_account_binding) { DeveloperKeyAccountBinding.create!(account:, developer_key: site_admin_key, workflow_state: "on") }

      before do
        site_admin_key.account_binding_for(Account.site_admin).update!(workflow_state: "allow")
        root_account_binding
      end

      it "backfills successfully" do
        expect { described_class.run }.to change { Lti::RegistrationAccountBinding.count }.by(2)
      end
    end
  end
end
