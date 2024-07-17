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
    let(:account) { account_model }
    let(:user) { user_model }
    let(:registration) { lti_registration_model(account:) }
    let(:account_binding) { Lti::RegistrationAccountBinding.new(account:, registration:) }

    describe "workflow_state" do
      context "with site admin registration" do
        let(:registration) { lti_registration_model(account: Account.site_admin) }

        it "rejects 'allow'" do
          account_binding.workflow_state = "allow"
          account_binding.save
          expect(account_binding).not_to be_valid
        end

        context "with site admin" do
          let(:account) { Account.site_admin }

          it "accepts 'allow'" do
            account_binding.workflow_state = "allow"
            account_binding.save
            expect(account_binding).to be_valid
          end
        end
      end

      it "rejects 'allow'" do
        account_binding.workflow_state = "allow"
        account_binding.save
        expect(account_binding).not_to be_valid
      end
    end

    # these specs live in MRA, along with the concept of a federated consortium:
    # describe "#restrict_federated_child_accounts"

    context "with a root account" do
      it "is valid" do
        account_binding.save
        expect(account_binding).to be_valid
      end
    end

    context "with a non-root account" do
      let(:account) { account_model(parent_account: account_model) }

      it "is invalid" do
        account_binding.save
        expect(account_binding).not_to be_valid
      end
    end

    context "when registration is for a different account" do
      context "and account is site admin" do
        let(:registration) { lti_registration_model(account: Account.site_admin) }

        it "is valid" do
          account_binding.save
          expect(account_binding).to be_valid
        end
      end

      context "and account is unrelated" do
        let(:registration) { lti_registration_model(account: account_model) }

        it "is invalid" do
          account_binding.save
          expect(account_binding).not_to be_valid
        end
      end
    end
  end

  describe "after_save hooks" do
    let(:lrab) do
      account = account_model
      user = user_model
      registration = Lti::Registration.create!(
        name: "an lti registration",
        account:,
        created_by: user,
        updated_by: user,
        developer_key: developer_key_model
      )
      Lti::RegistrationAccountBinding.create!(
        workflow_state: :off,
        account:,
        registration:
      )
    end

    it "creates a corresponding developer key account binding" do
      dkab = lrab.developer_key_account_binding
      expect(dkab).to be_persisted
      expect(dkab.workflow_state).to eq("off")
    end

    it "updates the corresponding developer key account binding" do
      lrab.update!(workflow_state: :on)
      expect(lrab.developer_key_account_binding.workflow_state).to eq("on")
    end

    context "when dev key binding already exists and isn't linked" do
      let(:dkab) { DeveloperKeyAccountBinding.create!(account: lrab.account, developer_key: lrab.registration.developer_key, skip_lime_sync: true) }

      before do
        old_dkab = lrab.developer_key_account_binding
        lrab.developer_key_account_binding = nil
        lrab.skip_lime_sync = true
        lrab.save!
        old_dkab.delete
        dkab # instantiate before test runs
      end

      it "doesn't error" do
        expect { lrab.save! }.not_to raise_error
      end

      it "links bindings" do
        lrab.save!
        expect(lrab.developer_key_account_binding).to eq(dkab)
      end
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

  describe "for cross-shard registration" do
    specs_require_sharding

    let(:account) { @shard2.activate { account_model } }
    let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
    let(:account_binding) { @shard2.activate { lti_registration_account_binding_model(account:, registration:) } }

    it "saves" do
      expect { @shard2.activate { account_binding.save! } }.not_to raise_error
    end
  end

  describe ".find_in_site_admin" do
    subject { Lti::RegistrationAccountBinding.find_in_site_admin(registration) }

    let(:registration) { lti_registration_model(account: Account.site_admin) }
    let(:account_binding) { lti_registration_account_binding_model(registration:, workflow_state:) }
    let(:workflow_state) { "on" }

    before do
      account_binding
    end

    context "when binding is allow" do
      let(:workflow_state) { "allow" }

      it "ignores binding" do
        expect(subject).to be_nil
      end
    end

    it "returns on binding" do
      expect(subject).to eq(account_binding)
    end

    context "with caching" do
      specs_require_cache(:redis_cache_store)

      it "caches the result" do
        allow(GuardRail).to receive(:activate).and_call_original
        subject
        # call it again
        Lti::RegistrationAccountBinding.find_in_site_admin(registration)
        expect(GuardRail).to have_received(:activate).once
      end
    end
  end

  describe ".find_all_in_site_admin" do
    subject { Lti::RegistrationAccountBinding.find_all_in_site_admin(registrations) }

    let(:registrations) { [registration1, registration2] }
    let(:registration1) { lti_registration_model(account: Account.site_admin, name: "first") }
    let(:registration2) { lti_registration_model(account: Account.site_admin, name: "second") }
    let(:binding1) { lti_registration_account_binding_model(registration: registration1, workflow_state: "on") }
    let(:binding2) { lti_registration_account_binding_model(registration: registration2, workflow_state: "on") }

    context "with no registrations" do
      let(:registrations) { [] }

      it "returns empty array" do
        expect(subject).to eq([])
      end
    end

    context "with non-site admin registrations" do
      let(:registrations) { [lti_registration_model(account: account_model, bound: true)] }

      it "filters them out" do
        expect(subject).to eq([])
      end
    end

    context "with on bindings" do
      it "returns all bindings for all registrations" do
        expect(subject).to include(binding1, binding2)
      end
    end

    context "with allow bindings" do
      before do
        registrations
        binding2.update!(workflow_state: "allow")
      end

      it "returns only on bindings" do
        expect(subject).to include(binding1)
      end
    end
  end

  describe "#clear_cache_if_site_admin" do
    subject { account_binding.update!(workflow_state: "on") }

    let(:account_binding) { lti_registration_account_binding_model(account:) }
    let(:cache_key) { Lti::RegistrationAccountBinding.site_admin_cache_key(account_binding.registration) }
    let(:all_cache_key) { Lti::RegistrationAccountBinding.site_admin_all_cache_key(account_binding.registration) }

    before do
      allow(MultiCache).to receive(:delete).and_return(true)
    end

    context "when account is site admin" do
      let(:account) { Account.site_admin }

      it "clears the cache" do
        subject
        expect(MultiCache).to have_received(:delete).with(cache_key)
        expect(MultiCache).to have_received(:delete).with(all_cache_key)
      end
    end

    context "when account is not site admin" do
      let(:account) { account_model }

      it "does not clear the cache" do
        subject
        expect(MultiCache).not_to have_received(:delete).with(cache_key)
        expect(MultiCache).not_to have_received(:delete).with(all_cache_key)
      end
    end
  end
end
