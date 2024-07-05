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
    it { is_expected.to have_many(:lti_registration_account_bindings).class_name("Lti::RegistrationAccountBinding") }
  end

  describe "#lti_version" do
    subject { registration.lti_version }

    let(:registration) { lti_registration_model }

    it "returns 1.3" do
      expect(subject).to eq(Lti::V1P3)
    end
  end

  describe "#dynamic_registration?" do
    subject { registration.dynamic_registration? }

    let(:registration) { lti_registration_model }

    context "when ims_registration is present" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it { is_expected.to be_truthy }
    end

    context "when ims_registration is not present" do
      it { is_expected.to be_falsey }
    end
  end

  describe "#configuration" do
    subject { registration.configuration }

    let(:registration) { lti_registration_model }

    context "when ims_registration is present" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it "returns the registration_configuration" do
        expect(subject).to eq(ims_registration.registration_configuration)
      end
    end

    context "when ims_registration is not present" do
      # this will change when manual 1.3 and 1.1 registrations are supported
      it "is empty" do
        expect(subject).to eq({})
      end
    end
  end

  describe "#icon_url" do
    subject { registration.icon_url }

    let(:registration) { lti_registration_model }

    context "when ims_registration is present" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it "returns the logo_uri" do
        expect(subject).to eq(ims_registration.logo_uri)
      end
    end

    context "when ims_registration is not present" do
      it "is nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#account_binding_for" do
    subject { registration.account_binding_for(account) }

    let(:registration) { lti_registration_model(account:) }
    let(:account) { account_model }
    let(:account_binding) { lti_registration_account_binding_model(registration:, account:) }

    before do
      account_binding # instantiate before test runs
    end

    context "when account is nil" do
      it "returns the account_binding for the registration's account" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when account is not root account" do
      subject { registration.account_binding_for(subaccount) }

      let(:subaccount) { account_model(parent_account: account) }

      it "returns the binding for the nearest root account" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when account is the registration's account" do
      it "returns the correct account_binding" do
        expect(subject).to eq(account_binding)
      end
    end

    context "when there is no binding for account" do
      subject { registration.account_binding_for(account_model) }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "with site admin registration" do
      specs_require_sharding

      let(:registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin) } }
      let(:site_admin_binding) { Shard.default.activate { lti_registration_account_binding_model(registration:, workflow_state: "on", account: Account.site_admin) } }
      let(:account) { @shard2.activate { account_model } }

      before do
        site_admin_binding # instantiate before test runs
      end

      it "prefers site admin binding" do
        expect(@shard2.activate { subject }).to eq(site_admin_binding)
      end

      context "when site admin binding is allow" do
        before do
          site_admin_binding.update!(workflow_state: "allow")
        end

        it "ignores site admin binding" do
          expect(@shard2.activate { subject }).to be_nil
        end
      end
    end
  end

  describe ".preload_account_bindings" do
    subject { Lti::Registration.preload_account_bindings(registrations, account) }

    let(:account) { account_model }
    let(:registrations) { [] }

    context "when account is nil" do
      let(:account) { nil }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when account is not root account" do
      let(:root_account) { account_model }
      let(:account) { account_model(parent_account: root_account) }

      let(:registrations) { [lti_registration_model(account: root_account, bound: true)] }

      it "preloads bindings for nearest root account" do
        subject
        expect(registrations).to all(have_attributes(account_binding: be_present))
      end
    end

    context "with account-level registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, bound: true, name: "first"),
          lti_registration_model(account:, bound: true, name: "second")
        ]
      end

      it "preloads account_binding on registrations" do
        subject
        expect(registrations).to all(have_attributes(account_binding: be_present))
      end
    end

    context "with site admin registrations" do
      let(:registrations) do
        [
          lti_registration_model(account:, bound: true, name: "first"),
          lti_registration_model(account: Account.site_admin, bound: true, name: "second")
        ]
      end

      it "preloads bindings from site admin registrations" do
        subject
        expect(registrations).to all(have_attributes(account_binding: be_present))
      end

      context "with sharding" do
        specs_require_sharding

        let(:account_registration) { @shard2.activate { lti_registration_model(account:, bound: true, name: "account") } }
        let(:site_admin_registration) { Shard.default.activate { lti_registration_model(account: Account.site_admin, bound: true, name: "site admin") } }
        let(:registrations) { [account_registration, site_admin_registration] }

        it "preloads bindings from site admin registrations" do
          @shard2.activate { subject }
          expect(registrations).to all(have_attributes(account_binding: be_present))
        end
      end
    end
  end

  describe "#inherited?" do
    subject { registration.inherited_for?(account) }

    let(:registration) { lti_registration_model(account: context) }
    let(:context) { account_model }

    context "when account matches registration account" do
      let(:account) { context }

      it { is_expected.to be false }
    end

    context "when account does not match registration account" do
      let(:account) { account_model }

      it { is_expected.to be true }
    end
  end

  describe "#destroy" do
    subject { registration.destroy }

    let(:registration) { lti_registration_model }

    it "marks the registration as deleted" do
      subject
      expect(registration.reload.workflow_state).to eq("deleted")
    end

    context "with an ims_registration" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration # instantiate before test runs
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end

      it "marks the associated ims_registration as deleted" do
        subject
        expect(ims_registration.reload.workflow_state).to eq("deleted")
      end
    end

    context "with an account binding" do
      let(:account_binding) { lti_registration_account_binding_model(registration:) }

      before do
        account_binding # instantiate before test runs
      end

      it "marks the associated account_binding as deleted" do
        subject
        expect(account_binding.reload.workflow_state).to eq("deleted")
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end

      it "keeps the association" do
        subject
        expect(registration.reload.lti_registration_account_bindings).to include(account_binding)
      end
    end

    context "with a developer key" do
      let(:developer_key) { developer_key_model(lti_registration: registration, account: registration.account) }

      before do
        developer_key # instantiate before test runs
      end

      it "marks the associated developer_key as deleted" do
        subject
        expect(developer_key.reload.workflow_state).to eq("deleted")
      end

      it "marks the registration as deleted" do
        subject
        expect(registration.reload.workflow_state).to eq("deleted")
      end
    end
  end

  describe "#undestroy" do
    subject { registration.undestroy }

    let(:registration) { lti_registration_model }

    before do
      registration.destroy
    end

    it "marks the registration as active" do
      subject
      expect(registration.reload.workflow_state).to eq("active")
    end

    context "with an ims_registration" do
      let(:ims_registration) { lti_ims_registration_model(lti_registration: registration) }

      before do
        ims_registration.destroy
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end

      it "marks the associated ims_registration as active" do
        subject
        expect(ims_registration.reload.workflow_state).to eq("active")
      end
    end

    context "with an account binding" do
      let(:account_binding) { lti_registration_account_binding_model(registration:) }

      before do
        account_binding.destroy
        registration.reload
      end

      it "marks the associated account_binding as off" do
        subject
        expect(account_binding.reload.workflow_state).to eq("off")
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end
    end

    context "with a developer key" do
      let(:developer_key) { developer_key_model(lti_registration: registration, account: registration.account) }

      before do
        developer_key.destroy
      end

      it "marks the associated developer_key as active" do
        subject
        expect(developer_key.reload.workflow_state).to eq("active")
      end

      it "marks the registration as active" do
        subject
        expect(registration.reload.workflow_state).to eq("active")
      end
    end
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
