# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require 'spec_helper'
require 'lti2_spec_helper'

describe DataFixup::CreateSubscriptionsForPlagiarismTools do
  include_context 'lti2_spec_helper'
  let(:product_family) do
    Lti::ProductFamily.create!(
      vendor_code: 'turnitin.com',
      product_code: 'turnitin-lti',
      vendor_name: 'TurnItIn',
      root_account: account,
      developer_key: developer_key
    )
  end

  let(:tool_proxy) do
    test_tool_proxy
  end

  def test_tool_proxy
    psh = double('PlagiarismSubscriptionsHelper')
    allow(Lti::PlagiarismSubscriptionsHelper).to receive(:new).and_return(psh)
    allow(psh).to receive(:create_subscription).and_return(nil)
    tool = create_tool_proxy(account)
    tool.update(raw_data: {'tool_profile' => {'service_offered' => [{'endpoint' => 'endpoint', '@id' => '#vnd.Canvas.SubmissionEvent'}]}})
    tool
  end

  let(:placement) { Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2 }

  context '#create_subscriptions' do
    it 'should add a subscription to plagiarism tool proxies' do
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.save!

      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).to receive(:new).and_return(psh)
      expect(psh).to receive(:create_subscription).and_return('subscription_id')
      DataFixup::CreateSubscriptionsForPlagiarismTools.create_subscriptions
      expect(tool_proxy.reload.subscription_id).to eq 'subscription_id'
    end

    it 'should not add subscriptions to non-plagiarism tool proxies' do
      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).not_to receive(:new)
      expect(psh).not_to receive(:create_subscription)
      DataFixup::CreateSubscriptionsForPlagiarismTools.create_subscriptions
      expect(tool_proxy.reload.subscription_id).to be_nil
    end

    it 'should only create one subscription if there are 2 tools with the same product code, vendor code and SubmissionEvent endpoint' do
      tool_proxy2 = Lti::ToolProxy.create!(
        raw_data: {
          'enabled_capability' => [placement],
          'tool_profile' => {'service_offered' => [{'endpoint' => 'endpoint', '@id' => '#vnd.Canvas.SubmissionEvent'}]},
        },
        subscription_id: 'id',
        context: course_factory(account: account),
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        workflow_state: 'active'
      )
      tool_proxy2.update_columns(subscription_id: nil)
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.save!

      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).to receive(:new).and_return(psh)
      expect(psh).to receive(:create_subscription).once.and_return('id2')
      DataFixup::CreateSubscriptionsForPlagiarismTools.create_subscriptions
      expect(tool_proxy.reload.subscription_id).to eq('id2')
      expect(tool_proxy2.reload.subscription_id).to eq('id2')
    end

    it 'should not create a subscription if there are two tools and one tool already has a subscription' do
      tool_proxy2 = Lti::ToolProxy.create!(
        raw_data: {
          'enabled_capability' => [placement],
          'tool_profile' => {'service_offered' => [{'endpoint' => 'endpoint', '@id' => '#vnd.Canvas.SubmissionEvent'}]},
        },
        subscription_id: 'id3',
        context: course_factory(account: account),
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        workflow_state: 'active'
      )
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.save!

      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).not_to receive(:new)
      expect(psh).not_to receive(:create_subscription)
      DataFixup::CreateSubscriptionsForPlagiarismTools.create_subscriptions
      expect(tool_proxy.reload.subscription_id).to eq('id3')
      expect(tool_proxy2.reload.subscription_id).to eq('id3')
    end

    it 'should create a subscription if there are two tools, but one has a different SubmissionEvent endpoint' do
      tool_proxy2 = Lti::ToolProxy.create!(
        raw_data: {
          'enabled_capability' => [placement],
          'tool_profile' => {'service_offered' => [{'endpoint' => 'yoyo.ma', '@id' => '#vnd.Canvas.SubmissionEvent'}]},
        },
        subscription_id: 'id3',
        context: course_factory(account: account),
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        workflow_state: 'active'
      )
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.save!

      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).to receive(:new).and_return(psh)
      expect(psh).to receive(:create_subscription).and_return('id4')
      DataFixup::CreateSubscriptionsForPlagiarismTools.create_subscriptions
      expect(tool_proxy.reload.subscription_id).to eq('id4')
    end
  end

  context '#delete_subscriptions' do
    it 'should remove subscriptions from plagiarism tool proxies' do
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.subscription_id = 'subscription_id'
      tool_proxy.save!

      psh = double('PlagiarismSubscriptionsHelper')
      expect(Lti::PlagiarismSubscriptionsHelper).to receive(:new).and_return(psh)
      expect(psh).to receive(:destroy_subscription)
      DataFixup::CreateSubscriptionsForPlagiarismTools.delete_subscriptions
      expect(tool_proxy.reload.subscription_id).to be_nil
    end
  end

  context '#recreate_subscriptions' do
    it 'should delete and recreate subscriptions properly' do
      tool_proxy.raw_data['enabled_capability'] = [placement]
      tool_proxy.subscription_id = 'subscription_id'
      tool_proxy.save!

      tp2 = test_tool_proxy
      tp2.raw_data['enabled_capability'] = [placement]
      tp2.subscription_id = 'subscription_id'
      tp2.save!

      tp3 = test_tool_proxy
      tp3.raw_data['enabled_capability'] = [placement]
      tp3.subscription_id = 'subscription_id3'
      tp3.save!

      psh1 = double('PlagiarismSubscriptionsHelper1')
      psh2 = double('PlagiarismSubscriptionsHelper2')
      psh3 = double('PlagiarismSubscriptionsHelper3')
      allow(Lti::PlagiarismSubscriptionsHelper).to receive(:new).with(tool_proxy).and_return(psh1)
      allow(Lti::PlagiarismSubscriptionsHelper).to receive(:new).with(tp2).and_return(psh2)
      allow(Lti::PlagiarismSubscriptionsHelper).to receive(:new).with(tp3).and_return(psh3)
      expect(psh1).to receive(:create_subscription).once.and_return('id1')
      expect(psh2).to receive(:create_subscription).once.and_return('id2')
      expect(psh3).to receive(:create_subscription).once.and_return('id3')
      expect(psh1).to receive(:destroy_subscription).with('subscription_id').once
      expect(psh3).to receive(:destroy_subscription).with('subscription_id3').once
      DataFixup::CreateSubscriptionsForPlagiarismTools.recreate_subscriptions

      expect([tool_proxy.reload.subscription_id, tp2.reload.subscription_id, tp3.reload.subscription_id]).to eq(['id1', 'id2', 'id3'])
    end
  end
end
