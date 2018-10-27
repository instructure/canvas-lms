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

settings = {
  'title' => 'LTI 1.3 Tool',
  'description' => '1.3 Tool',
  'launch_url' => 'http://lti13testtool.docker/blti_launch',
  'custom_fields' => {'has_expansion' => '$Canvas.user.id', 'no_expansion' => 'foo'},
  'public_jwk' => {
    "kty" => "RSA",
    "e" => "AQAB",
    "n" => "2YGluUtCi62Ww_TWB38OE6wTaN...",
    "kid" => "2018-09-18T21:55:18Z",
    "alg" => "RS256",
    "use" => "sig"
  },
  'extensions' =>  [
    {
      'platform' => 'canvas.instructure.com',
      'privacy_level' => 'public',
      'tool_id' => 'LTI 1.3 Test Tool',
      'domain' => 'http://lti13testtool.docker',
      'settings' =>  {
        'icon_url' => 'https://static.thenounproject.com/png/131630-200.png',
        'selection_height' => 500,
        'selection_width' => 500,
        'text' => 'LTI 1.3 Test Tool Extension text',
        'course_navigation' =>  {
          'message_type' => 'LtiResourceLinkRequest',
          'canvas_icon_class' => 'icon-lti',
          'icon_url' => 'https://static.thenounproject.com/png/131630-211.png',
          'text' => 'LTI 1.3 Test Tool Course Navigation',
          'url' =>
          'http://lti13testtool.docker/launch?placement=course_navigation',
          'enabled' => true
        }
      }
    }
  ]
}

RSpec.describe DeveloperKeyAccountBinding, type: :model do
  let(:account) { account_model }
  let(:developer_key) { DeveloperKey.create! }
  let(:dev_key_binding) do
    DeveloperKeyAccountBinding.new(
      account: account,
      developer_key: developer_key
    )
  end
  let(:params) { {} }
  let(:root_account_key) { DeveloperKey.create!(account: account, **params) }
  let(:root_account_binding) { root_account_key.developer_key_account_bindings.first }

  describe '#lti_1_3_tools' do
    subject do
      expect(DeveloperKey.count > 1).to be true
      described_class.lti_1_3_tools(account)
    end
    let(:params) { { visible: true } }
    let(:workflow_state) { described_class::ON_STATE }

    before do
      dev_keys = []
      3.times { dev_keys << DeveloperKey.create!(account: account, **params) }
      dev_keys.each do |dk|
        dk.developer_key_account_bindings.first.update! workflow_state: workflow_state
      end
    end

    context 'with no visible dev keys' do
      let(:params) { { visible: false } }

      it { is_expected.to be_empty }
    end

    context 'with visible dev keys but no ON_STATE keys' do
      let(:workflow_state) { described_class::ALLOW_STATE }

      it { is_expected.to be_empty }
    end

    context 'with visible dev keys in ON_STATE but no tool_configurations' do
      it { is_expected.to be_empty }
    end

    context 'with visible dev keys in ON_STATE and tool_configurations' do
      let(:first_key) { DeveloperKey.first }
      before do
        first_key.create_tool_configuration! settings: settings
      end

      it { is_expected.not_to be_empty }

      it 'returns only the visible, turned on, with tool configuration key' do
        expect(first_key).to eq subject.first.developer_key
      end
    end
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
