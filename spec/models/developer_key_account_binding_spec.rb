# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

require_relative "../lti_1_3_spec_helper"

RSpec.describe DeveloperKeyAccountBinding do
  include_context "lti_1_3_spec_helper"

  let(:account) { account_model }
  let(:developer_key) { DeveloperKey.create! }
  let(:dev_key_binding) do
    DeveloperKeyAccountBinding.new(
      account:,
      developer_key:
    )
  end
  let(:params) { {} }
  let(:root_account_key) { DeveloperKey.create!(account:, **params) }
  let(:root_account_binding) { root_account_key.developer_key_account_bindings.first }

  describe "validations and callbacks" do
    it "requires an account" do
      dev_key_binding.account = nil
      dev_key_binding.validate
      expect(dev_key_binding.errors.keys).to match_array(
        [:account]
      )
    end

    it "requires a developer key" do
      dev_key_binding.developer_key = nil
      dev_key_binding.validate
      expect(dev_key_binding.errors.keys).to match_array(
        [:developer_key]
      )
    end

    describe "workflow state" do
      it 'allows "off"' do
        dev_key_binding.workflow_state = "off"
        expect(dev_key_binding.valid?).to be true
      end

      it 'allows "allow"' do
        dev_key_binding.workflow_state = "allow"
        expect(dev_key_binding.valid?).to be true
      end

      it 'allows "on"' do
        dev_key_binding.workflow_state = "on"
        expect(dev_key_binding.valid?).to be true
      end

      it "does not allow invalid workflow states" do
        dev_key_binding.workflow_state = "invalid_state"
        dev_key_binding.validate
        # it automatically flips it to the default state
        expect(dev_key_binding.workflow_state).to eq "off"
      end

      it 'defaults to "off"' do
        binding = DeveloperKeyAccountBinding.create!(
          account:,
          developer_key:
        )
        expect(binding.workflow_state).to eq "off"
      end
    end

    describe "after update" do
      subject { site_admin_binding.update!(update_parameters) }

      let(:update_parameters) { { workflow_state: } }
      let(:site_admin_key) { DeveloperKey.create! }
      let(:site_admin_binding) { site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin) }

      it "clears the site admin binding cache if the account is site admin" do
        allow(MultiCache).to receive(:delete).and_return(true)
        expect(MultiCache).to receive(:delete).with(DeveloperKeyAccountBinding.site_admin_cache_key(site_admin_key))
        site_admin_binding.update!(workflow_state: "on")
      end

      it "does not clear the site admin binding cache if the account is not site admin" do
        allow(MultiCache).to receive(:delete).and_return(true)
        expect(MultiCache).not_to receive(:delete).with(DeveloperKeyAccountBinding.site_admin_cache_key(root_account_key))
        root_account_binding.update!(workflow_state: "on")
      end

      context "when the starting workflow_state is on" do
        before { site_admin_binding.update!(workflow_state: "on") }

        context 'when the new workflow state is "off"' do
          let(:workflow_state) { "off" }

          it "disables associated external tools" do
            expect(site_admin_key).to receive(:disable_external_tools!)
            subject
          end
        end

        context 'when the new workflow state is "on"' do
          let(:workflow_state) { "on" }

          it "does not disable associated external tools" do
            expect(site_admin_key).not_to receive(:disable_external_tools!)
            subject
          end
        end

        context 'when the new workflow state is "allow"' do
          let(:workflow_state) { "allow" }

          it "restores associated external tools" do
            expect(site_admin_key).to receive(:restore_external_tools!)
            subject
          end
        end
      end

      context "when the starting workflow_state is off" do
        before { site_admin_binding.update!(workflow_state: "off") }

        context 'when the new workflow state is "on"' do
          let(:workflow_state) { "on" }

          it "enables external tools" do
            expect(site_admin_key).not_to receive(:disable_external_tools!)
            subject
          end
        end

        context 'when the new workflow state is "allow"' do
          let(:workflow_state) { "allow" }

          it "restores associated external tools" do
            expect(site_admin_key).to receive(:restore_external_tools!)
            subject
          end
        end
      end
    end

    describe "after save" do
      describe "set root account" do
        context "when account is root account" do
          let(:account) { account_model }

          it "sets root account equal to account" do
            dev_key_binding.account = account
            dev_key_binding.save!
            expect(dev_key_binding.root_account).to eq account
          end
        end

        context "when account is not root account" do
          let(:account) { account_model(root_account: Account.create!) }

          it "sets root account equal to account's root account" do
            dev_key_binding.account = account
            dev_key_binding.save!
            expect(dev_key_binding.root_account).to eq account.root_account
          end
        end
      end
    end
  end

  describe "find_site_admin_cached" do
    specs_require_sharding

    let(:root_account_shard) { @shard1 }
    let(:root_account) { root_account_shard.activate { account_model } }
    let(:site_admin_key) { Account.site_admin.shard.activate { DeveloperKey.create! } }
    let(:root_account_key) { root_account_shard.activate { DeveloperKey.create!(account: root_account) } }
    let(:site_admin_binding) { site_admin_key.developer_key_account_bindings.first }

    it "finds the site admin binding for the specified key" do
      expect(DeveloperKeyAccountBinding.find_site_admin_cached(site_admin_key)).to eq site_admin_binding
    end

    it "returns nil if the devleoper key is a non-site admin key" do
      expect(DeveloperKeyAccountBinding.find_site_admin_cached(root_account_key)).to be_nil
    end
  end

  describe "find_in_account_priority" do
    let(:root_account) { account_model }
    let(:sub_account) { account_model(parent_account: root_account) }
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }

    let(:root_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: root_account, workflow_state: "allow"
      )
    end
    let(:sub_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: sub_account, workflow_state: "allow"
      )
    end
    let(:accounts) { [sub_account, root_account, Account.site_admin] }

    before do
      root_account_binding
      sub_account_binding
    end

    it "returns the first binding found in order of accounts" do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(accounts, site_admin_key, explicitly_set: false)
      expect(found_binding.account).to eq accounts.first
    end

    it 'does not return "allow" bindings if explicitly_set is true' do
      root_account_binding.update!(workflow_state: "on")
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(accounts, site_admin_key)
      expect(found_binding.account).to eq accounts.second
    end

    it 'does return "allow" bindings if explicitly_set is false' do
      root_account_binding.update!(workflow_state: "on")
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(accounts, site_admin_key, explicitly_set: false)
      expect(found_binding.account).to eq accounts.first
    end

    it "does not return bindings from accounts not in the list" do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(accounts[1..2], site_admin_key, explicitly_set: false)
      expect(found_binding.account).to eq accounts.second
    end
  end

  context "sharding" do
    specs_require_sharding

    let(:root_account_shard) { @shard1 }
    let(:root_account) { root_account_shard.activate { account_model } }

    context "when account chain includes cross-shard accounts" do
      let(:account_s0) { account_model }
      let(:account_s1) { @shard1.activate { account_model } }
      let(:account_s2) { @shard2.activate { account_model } }
      let(:another_account_s0) { account_model }
      let!(:dk_s1) do
        account_s1.shard.activate { DeveloperKey.create!(account: account_s1, workflow_state: "off") }
      end

      before do
        DeveloperKeyAccountBinding.create!(account: account_s0, developer_key: dk_s1, workflow_state: "on")
        DeveloperKeyAccountBinding.create!(account: another_account_s0, developer_key: dk_s1, workflow_state: "on")
      end

      def expect_binding_on_each_shard(account, state)
        [Shard.current, @shard1, @shard2].each do |shard|
          shard.activate do
            b = DeveloperKeyAccountBinding.find_in_account_priority(account_chain, dk_s1)
            expect(b.account).to eq(account)
            expect(b.state).to eq(state)
          end
        end
      end

      context "when the first matching binding is on the DK's shard" do
        let!(:account_chain) { [account_s1, account_s0, account_s2, another_account_s0] }

        it "finds the first matching binding no matter the current shard" do
          expect_binding_on_each_shard(account_s1, :off)
        end
      end

      context "when the first matching binding is not on the DK's shard" do
        let!(:account_chain) { [account_s0, account_s1, account_s2, another_account_s0] }

        it "finds the first matching binding no matter the current shard" do
          expect_binding_on_each_shard(account_s0, :on)
        end
      end

      context "when there is a matching binding on the first account's shard but it is not the first matching binding" do
        let!(:account_chain) { [account_model, account_s1, account_s2, account_s0] }

        it "finds the first matching binding no matter the current shard" do
          expect_binding_on_each_shard(account_s1, :off)
        end
      end
    end
  end
end
