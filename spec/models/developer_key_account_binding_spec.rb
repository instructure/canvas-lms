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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

RSpec.describe DeveloperKeyAccountBinding, type: :model do
  let(:account) { account_model }
  let(:developer_key) { DeveloperKey.create! }

  let(:dev_key_binding) do
    DeveloperKeyAccountBinding.new(
      account: account,
      developer_key: developer_key
    )
  end

  describe 'validations and callbacks' do
    it 'requires an account' do
      dev_key_binding.account = nil
      dev_key_binding.validate
      expect(dev_key_binding.errors.keys).to match_array(
        [:account]
      )
    end

    it 'requires a developer key' do
      dev_key_binding.developer_key = nil
      dev_key_binding.validate
      expect(dev_key_binding.errors.keys).to match_array(
        [:developer_key]
      )
    end

    describe 'workflow state' do
      it 'allows "off"' do
        dev_key_binding.workflow_state = 'off'
        expect(dev_key_binding.valid?).to eq true
      end

      it 'allows "allow"' do
        dev_key_binding.workflow_state = 'allow'
        expect(dev_key_binding.valid?).to eq true
      end

      it 'allows "on"' do
        dev_key_binding.workflow_state = 'on'
        expect(dev_key_binding.valid?).to eq true
      end

      it 'does not allow invalid workflow states' do
        dev_key_binding.workflow_state = 'invalid_state'
        dev_key_binding.validate
        expect(dev_key_binding.errors.keys).to match_array(
          [:workflow_state]
        )
      end

      it 'defaults to "off"' do
        binding = DeveloperKeyAccountBinding.create!(
          account: account,
          developer_key: developer_key
        )
        expect(binding.workflow_state).to eq 'off'
      end
    end

    describe 'after_save' do
      let(:site_admin_key) { DeveloperKey.create! }
      let(:site_admin_binding) { site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin) }
      let(:root_account_key) { DeveloperKey.create!(account: account_model) }
      let(:root_account_binding) { root_account_key.developer_key_account_bindings.first }

      it 'clears the site admin binding cache if the account is site admin' do
        allow(MultiCache).to receive(:delete).and_return(true)
        expect(MultiCache).to receive(:delete).with(DeveloperKeyAccountBinding.site_admin_cache_key(site_admin_key))
        site_admin_binding.update!(workflow_state: 'on')
      end

      it 'does not clear the site admin binding cache if the account is not site admin' do
        allow(MultiCache).to receive(:delete).and_return(true)
        expect(MultiCache).not_to receive(:delete).with(DeveloperKeyAccountBinding.site_admin_cache_key(root_account_key))
        root_account_binding.update!(workflow_state: 'on')
      end
    end
  end

  describe 'find_site_admin_cached' do
    specs_require_sharding

    let(:root_account_shard) { Shard.create! }
    let(:root_account) { root_account_shard.activate { account_model } }
    let(:site_admin_key) { Account.site_admin.shard.activate { DeveloperKey.create! } }
    let(:root_account_key) { root_account_shard.activate { DeveloperKey.create!(account: root_account) } }
    let(:site_admin_binding) { site_admin_key.developer_key_account_bindings.first }

    it 'finds the site admin binding for the specified key' do
      expect(DeveloperKeyAccountBinding.find_site_admin_cached(site_admin_key)).to eq site_admin_binding
    end

    it 'returns nil if the devleoper key is a non-site admin key' do
      expect(DeveloperKeyAccountBinding.find_site_admin_cached(root_account_key)).to eq nil
    end
  end

  describe 'find_in_account_priority' do
    let(:root_account) { account_model }
    let(:sub_account) { account_model(parent_account: root_account) }
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }

    let(:root_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: root_account, workflow_state: 'allow'
      )
    end
    let(:sub_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: sub_account, workflow_state: 'allow'
      )
    end
    let(:account_ids) { [sub_account.id, root_account.id, Account.site_admin.id] }

    before do
      root_account_binding
      sub_account_binding
    end

    it 'returns the first binding found in order of account_ids' do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.id, false)
      expect(found_binding.account.id).to eq account_ids.first
    end

    it 'does not return "allow" bindings if explicitly_set is true' do
      root_account_binding.update!(workflow_state: 'on')
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.id)
      expect(found_binding.account.id).to eq account_ids.second
    end

    it 'does return "allow" bindings if explicitly_set is false' do
      root_account_binding.update!(workflow_state: 'on')
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.id, false)
      expect(found_binding.account.id).to eq account_ids.first
    end

    it 'does not return bindings from accounts not in the list' do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids[1..2], site_admin_key.id, false)
      expect(found_binding.account.id).to eq account_ids.second
    end
  end

  context 'sharding' do
    specs_require_sharding

    let(:root_account_shard) { Shard.create! }
    let(:root_account) { root_account_shard.activate { account_model } }
    let(:sa_developer_key) { Account.site_admin.shard.activate { DeveloperKey.create!(name: 'SA Key') } }
    let(:root_account_binding) do
      root_account_shard.activate do
        DeveloperKeyAccountBinding.create!(
          account_id: root_account.id,
          developer_key_id: sa_developer_key.global_id
        )
      end
    end
    let(:sa_account_binding) { sa_developer_key.developer_key_account_bindings.find_by(account: Account.site_admin) }

    context 'when on a root account shard' do
      it 'finds root account binding when it is set to "on"' do
        root_account_binding.update!(workflow_state: 'on')
        sa_account_binding.update!(workflow_state: 'off')

        found_binding = root_account_shard.activate do
          DeveloperKeyAccountBinding.find_in_account_priority([Account.site_admin.id, root_account.id], sa_developer_key.id)
        end

        expect(found_binding.account).to eq root_account
      end

      it 'finds root account binding when it is set to "off"' do
        root_account_binding.update!(workflow_state: 'off')
        sa_account_binding.update!(workflow_state: 'on')

        found_binding = root_account_shard.activate do
          DeveloperKeyAccountBinding.find_in_account_priority([Account.site_admin.id, root_account.id], sa_developer_key.id)
        end

        expect(found_binding.account).to eq root_account
      end
    end

    context 'when on the site admin shard' do
      it 'finds site admin binding when it is set to "on"' do
        root_account_binding.update!(workflow_state: 'off')
        sa_account_binding.update!(workflow_state: 'on')

        found_binding = Account.site_admin.shard.activate do
          DeveloperKeyAccountBinding.find_in_account_priority([Account.site_admin.id, root_account.id], sa_developer_key.id)
        end

        expect(found_binding.account).to eq Account.site_admin
      end

      it 'finds site admin binding when it is set to "off"' do
        root_account_binding.update!(workflow_state: 'on')
        sa_account_binding.update!(workflow_state: 'off')

        found_binding = Account.site_admin.shard.activate do
          DeveloperKeyAccountBinding.find_in_account_priority([Account.site_admin.id, root_account.id], sa_developer_key.id)
        end

        expect(found_binding.account).to eq Account.site_admin
      end
    end
  end
end
