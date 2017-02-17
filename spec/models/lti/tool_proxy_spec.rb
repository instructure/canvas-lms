#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require_dependency "lti/tool_proxy"

module Lti
  describe ToolProxy do
    let(:account) { Account.create }
    let(:product_family) do
      ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account)
    end
    let(:resource_handler) { ResourceHandler.new }

    describe 'validations' do

      before(:each) do
        subject.shared_secret = 'shared_secret'
        subject.guid = 'guid'
        subject.product_version = '1.0beta'
        subject.lti_version = 'LTI-2p0'
        subject.product_family = product_family
        subject.context = account
        subject.workflow_state = 'active'
        subject.raw_data = 'some raw data'
      end

      it 'requires a shared_secret' do
        subject.shared_secret = nil
        subject.save
        error = subject.errors.find { |e| e == [:shared_secret, "can't be blank"] }
        expect(error).not_to eq nil
      end

      it 'requires a guid' do
        subject.guid = nil
        subject.save
        error = subject.errors.find { |e| e == [:guid, "can't be blank"] }
        expect(error).not_to eq nil
      end

      it 'must have a unique guid' do
        tool_proxy = described_class.new
        tool_proxy.shared_secret = 'foo'
        tool_proxy.guid = 'guid'
        tool_proxy.product_version = '2.0_beta'
        tool_proxy.lti_version = 'LTI-2p0'
        tool_proxy.product_family = product_family
        tool_proxy.context = account
        tool_proxy.workflow_state = 'active'
        tool_proxy.raw_data = 'raw_data'
        tool_proxy.save
        subject.save
        expect(subject.errors[:guid]).to include("has already been taken")
      end

      it 'requires a product_version' do
        subject.product_version = nil
        subject.save
        expect(subject.errors[:product_version]).to include("can't be blank")
      end

      it 'requires a lti_version' do
        subject.lti_version = nil
        subject.save
        expect(subject.errors[:lti_version]).to include("can't be blank")
      end

      it 'requires a product_family' do
        subject.product_family = nil
        subject.save
        expect(subject.errors[:product_family_id]).to include("can't be blank")
      end

      it 'requires a context' do
        subject.context = nil
        subject.save
        expect(subject.errors[:context]).to include("can't be blank")
      end

      it 'require a workflow_state' do
        subject.workflow_state = nil
        subject.save
        expect(subject.errors[:workflow_state]).to include("can't be blank")
      end

      it 'requires raw_data' do
        subject.raw_data = nil
        subject.save
        expect(subject.errors[:raw_data]).to include("can't be blank")
      end

      describe "#find_proxies_for_context" do
        let(:root_account) { Account.create }
        let(:sub_account_1_1) { Account.create(parent_account: root_account) }
        let(:sub_account_1_2) { Account.create(parent_account: root_account) }
        let(:sub_account_2_1) { Account.create(parent_account: sub_account_1_1) }


        it 'finds a tool_proxy' do
          tool_proxy = create_tool_proxy(context: sub_account_2_1)
          tool_proxy.bindings.create!(context: sub_account_2_1)
          proxies = described_class.find_all_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 1
          expect(proxies.first).to eq tool_proxy
        end

        it 'finds a tool_proxy for a parent account' do
          tool_proxy = create_tool_proxy(context: sub_account_1_1)
          tool_proxy.bindings.create!(context: sub_account_1_1)
          proxies = described_class.find_all_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 1
          expect(proxies.first).to eq tool_proxy
        end

        it 'finds a tool_proxy for a course binding' do
          course = Course.create!(account: sub_account_2_1)
          tool_proxy = create_tool_proxy(context: course)
          tool_proxy.bindings.create!(context: course)
          proxies = described_class.find_all_proxies_for_context(course)
          expect(proxies.count).to eq 1
          expect(proxies.first).to eq tool_proxy
        end

        it "doesn't return tool_proxies when closest ancestor is disabled" do
          tool_proxy = create_tool_proxy(context: sub_account_2_1)
          tool_proxy.bindings.create!(context: sub_account_2_1, enabled: false)
          tool_proxy.bindings.create!(context: sub_account_1_1)
          proxies = described_class.find_all_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 0
        end

        it 'handles multiple tool_proxies' do
          tool_proxy1 = create_tool_proxy(context: sub_account_2_1)
          tool_proxy1.bindings.create!(context: sub_account_2_1)
          tool_proxy2 = create_tool_proxy(context: sub_account_1_1)
          tool_proxy2.bindings.create!(context: sub_account_1_1)
          proxies = described_class.find_all_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 2
          expect(proxies).to include(tool_proxy1)
          expect(proxies).to include(tool_proxy2)
        end

        it 'handles multiple bindings' do
          tool_proxy = create_tool_proxy(context: sub_account_1_1)
          tool_proxy.bindings.create!(context: sub_account_1_1)
          tool_proxy.bindings.create!(context: sub_account_2_1)
          proxies = described_class.find_all_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 1
          expect(proxies.first).to eq tool_proxy
        end

        describe "#find_active_proxies_for_context" do
          it "doesn't return tool_proxies that are disabled" do
            tool_proxy = create_tool_proxy(context: sub_account_2_1, workflow_state: 'disabled')
            tool_proxy.bindings.create!(context: sub_account_2_1)
            proxies = described_class.find_active_proxies_for_context(sub_account_2_1)
            expect(proxies.count).to eq 0
          end

          it "doesn't return tool_proxies that are deleted" do
            tool_proxy = create_tool_proxy(context: sub_account_2_1, workflow_state: 'deleted')
            tool_proxy.bindings.create!(context: sub_account_2_1)
            proxies = described_class.find_active_proxies_for_context(sub_account_2_1)
            expect(proxies.count).to eq 0
          end
        end

        describe "#find_installed_proxies_for_context" do
          it "doesn't return tool_proxies that are deleted" do
            tool_proxy = create_tool_proxy(context: sub_account_2_1, workflow_state: 'deleted')
            tool_proxy.bindings.create!(context: sub_account_2_1)
            proxies = described_class.find_installed_proxies_for_context(sub_account_2_1)
            expect(proxies.count).to eq 0
          end
        end

        it "doesn't return tool proxies that are enabled at a higher binding and disabled at a lower binding" do
          tool_proxy = create_tool_proxy(context: sub_account_1_1)
          tool_proxy.bindings.create!(context: sub_account_1_1)
          tool_proxy.bindings.create!(context: sub_account_2_1, enabled: false)
          proxies = described_class.find_active_proxies_for_context(sub_account_2_1)
          expect(proxies.count).to eq 0
        end

      end

    end

    def create_tool_proxy(opts = {})
      default_opts = {
          shared_secret: 'shared_secret',
          guid: SecureRandom.uuid,
          product_version: '1.0beta',
          lti_version: 'LTI-2p0',
          product_family: product_family,
          workflow_state: 'active',
          raw_data: 'some raw data'
      }
      ToolProxy.create(default_opts.merge(opts))
    end

    context "singleton message handlers" do

      subject do
        described_class.create!(
          shared_secret: 'shared_secret',
          guid: 'guid',
          product_version: '1.0beta',
          lti_version: 'LTI-2p0',
          product_family: product_family,
          context: account,
          workflow_state: 'active',
          raw_data: 'some raw data'
        )
      end
      let(:product_family) do
        ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account)
      end
      let(:default_resource_handler) do
        ResourceHandler.create!(
          resource_type_code: 'instructure.com:default',
          name: 'resource name',
          tool_proxy: subject)
      end
      let(:reregistration_message_handler) do
        MessageHandler.create!(
          message_type: IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE,
          launch_path: 'https://samplelaunch/rereg',
          resource_handler: default_resource_handler
        )
      end

      describe "#reregistration_handler" do

        it "returns the reregistration handler" do
          reregistration_message_handler
          expect(subject.reregistration_message_handler).to eq reregistration_message_handler
        end

      end

      describe "#default_resource_handler" do

        it "returns the default resource handler" do
          default_resource_handler
          expect(subject.default_resource_handler).to eq default_resource_handler
        end

      end

    end

  end
end
