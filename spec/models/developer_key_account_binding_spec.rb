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

  describe 'validations' do
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
  end

  describe 'find_in_account_priority' do
    let(:root_account) { account_model }
    let(:sub_account) { account_model(parent_account: root_account) }
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }
    let(:root_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: root_account, workflow_state: DeveloperKeyAccountBinding::ALLOW_STATE
      )
    end
    let(:sub_account_binding) do
      site_admin_key.developer_key_account_bindings.create!(
        account: sub_account, workflow_state: DeveloperKeyAccountBinding::ALLOW_STATE
      )
    end
    let(:account_ids) { [sub_account.global_id, root_account.global_id, Account.site_admin.global_id] }

    before do
      root_account_binding
      sub_account_binding
    end

    it 'returns the first binding found in order of account_ids' do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.global_id, false)
      expect(found_binding.account.id).to eq account_ids.first
    end

    it 'does not return "allow" bindings if explicitly_set is true' do
      root_account_binding.update!(workflow_state: 'on')
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.global_id)
      expect(found_binding.account.id).to eq account_ids.second
    end

    it 'does return "allow" bindings if explicitly_set is false' do
      root_account_binding.update!(workflow_state: 'on')
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids, site_admin_key.global_id, false)
      expect(found_binding.account.id).to eq account_ids.first
    end

    it 'does not return bindings from accounts not in the list' do
      found_binding = DeveloperKeyAccountBinding.find_in_account_priority(account_ids[1..2], site_admin_key.global_id, false)
      expect(found_binding.account.id).to eq account_ids.second
    end
  end
end
