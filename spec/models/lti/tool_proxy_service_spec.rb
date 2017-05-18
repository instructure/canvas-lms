#
# Copyright (C) 2014 - present Instructure, Inc.
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
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')

require_dependency "lti/tool_proxy_service"

module Lti
  describe ToolProxyService do
    include_context 'lti2_spec_helper'

    let(:tool_proxy_service) { ToolProxyService.new }

    describe '#process_tool_proxy_json' do

      let(:tool_proxy_fixture){File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))}
      let(:tool_proxy_guid){'guid'}
      let(:account){Account.new}


      it "creates the product_family if it doesn't exist" do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        pf = tool_proxy.product_family
        expect(pf.vendor_code).to eq 'acme.com'
        expect(pf.product_code).to eq 'assessment-tool'
        expect(pf.vendor_name).to eq 'Acme'
        expect(pf.website).to eq 'http://acme.example.com'
        expect(pf.vendor_description).to eq 'Acme is a leading provider of interactive tools for education'
        expect(pf.vendor_email).to eq 'info@example.com'
        expect(pf.root_account).to eq account
      end

      it "associates the DeveloperKey with the product_family when creating" do
        dev_key = DeveloperKey.create(api_key:'testapikey')
        tool_proxy = tool_proxy_service.process_tool_proxy_json(
          json: tool_proxy_fixture,
          context: account,
          guid: tool_proxy_guid,
          developer_key: dev_key)
        pf = tool_proxy.product_family
        expect(pf.vendor_code).to eq 'acme.com'
        expect(pf.product_code).to eq 'assessment-tool'
        expect(pf.vendor_name).to eq 'Acme'
        expect(pf.website).to eq 'http://acme.example.com'
        expect(pf.vendor_description).to eq 'Acme is a leading provider of interactive tools for education'
        expect(pf.vendor_email).to eq 'info@example.com'
        expect(pf.root_account).to eq account
        expect(pf.developer_key).to eq dev_key
      end

      it "uses an exisiting product family if it can" do
        pf = ProductFamily.new
        pf.vendor_code = 'acme.com'
        pf.product_code = 'assessment-tool'
        pf.vendor_name = 'Acme'
        pf.root_account = account.root_account
        pf.save!
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        expect(tool_proxy.product_family.id).to eq pf.id
      end

      it "matches DeveloperKeys when looking for matching product family" do
        dev_key = DeveloperKey.create(api_key:'testapikey')
        pf = ProductFamily.new
        pf.vendor_code = 'acme.com'
        pf.product_code = 'assessment-tool-no-dev-key'
        pf.vendor_name = 'Acme'
        pf.root_account = account.root_account
        pf.save!
        tool_proxy = tool_proxy_service.process_tool_proxy_json(
          json: tool_proxy_fixture,
          context: account,
          guid: tool_proxy_guid,
          developer_key: dev_key)
        expect(tool_proxy.product_family.id).not_to eq pf.id
      end

      it "creates the resource handlers" do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        rh = tool_proxy.resources.find{|r| r.resource_type_code == 'asmt'}
        expect(rh.name).to eq 'Acme Assessment'
        expect(rh.description).to eq 'An interactive assessment using the Acme scale.'
        expect(rh.icon_info).to eq [
          {
            'default_location' => {'path' => 'images/bb/en/icon.png'},
            'key' => 'iconStyle.default.path'
          },
          {
            'icon_style' => ['BbListElementIcon'],
            'default_location' => {'path' => 'images/bb/en/listElement.png'},
            'key' => 'iconStyle.bb.listElement.path'
          },
          {
            'icon_style' => ['BbPushButtonIcon'],
            'default_location' => {'path' => 'images/bb/en/pushButton.png'},
            'key' => 'iconStyle.bb.pushButton.path'
          }
        ]
      end

      it "creates the message_handlers" do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        resource_handler = tool_proxy.resources.find{|r| r.resource_type_code == 'asmt'}
        mh = resource_handler.message_handlers.first
        expect(mh.message_type).to eq 'basic-lti-launch-request'
        expect(mh.launch_path).to eq 'https://acme.example.com/handler/launchRequest'
        expect(mh.capabilities).to eq [ ]
        expect(mh.parameters).to eq [{'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it "associates the message handlers with the tool proxy" do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        expected_message_handlers = tool_proxy.resources.map(&:message_handlers).flatten
        expect(tool_proxy.message_handlers).to match_array expected_message_handlers
      end

      it "creates default message handlers" do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        resource_handler = tool_proxy.resources.find{|r| r.resource_type_code == 'instructure.com:default'}

        expect(resource_handler.name).to eq 'Acme Assessments'
        expect(resource_handler.message_handlers.size).to eq 1
        mh = resource_handler.message_handlers.first
        expect(mh.message_type).to eq 'basic-lti-launch-request'
        expect(mh.launch_path).to eq 'https://acme.example.com/handler/launchRequest'
        expect(mh.capabilities).to eq [ ]
        expect(mh.parameters).to eq [{'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it 'creates a tool proxy biding' do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        expect(tool_proxy.bindings.count).to eq 1
        binding = tool_proxy.bindings.first
        expect(binding.context).to eq account
      end

      it 'creates a tool setting for the tool proxy if custom is defined' do
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        expect(tool_proxy.tool_settings.count).to eq 1
        expect(tool_proxy.tool_settings.first.custom).to eq({"customerId"=>"394892759526"})
      end

      it 'does not create a tool setting for the tool proxy if custom is not defined' do
        tool_proxy = JSON.parse(tool_proxy_fixture)
        tool_proxy.delete('custom')
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy.to_json, context: account, guid: tool_proxy_guid)
        expect(tool_proxy.tool_settings.count).to eq 0
      end

      it 'creates a tool_proxy' do
        SecureRandom.stubs(:uuid).returns('my_uuid')
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
        expect(tool_proxy.shared_secret).to eq 'ThisIsASecret!'
        expect(tool_proxy.guid).to eq tool_proxy_guid
        expect(tool_proxy.product_version).to eq '10.3'
        expect(tool_proxy.lti_version).to eq 'LTI-2p0'
        expect(tool_proxy.context).to eq account
        expect(tool_proxy.workflow_state).to eq 'disabled'
        expect(tool_proxy.name).to eq 'Acme Assessments'
        expect(tool_proxy.description).to eq 'Acme Assessments provide an interactive test format.'
      end

      context 'placements' do

        RSpec::Matchers.define :include_placement do |placement|
          match do |resource_placements|
            (resource_placements.select { |p| p.placement == placement}).size > 0
          end
        end

        RSpec::Matchers.define :include_placements do |included_placements|
          match do |resource_placements|
            (included_placements - resource_placements.map(&:placement) ).empty?
          end
        end

        RSpec::Matchers.define :only_include_placement do |placement|
          match do |resource_placements|
            resource_placements.size == 1 && resource_placements[0].placement == placement
          end
        end

        it 'creates default placements when none are specified' do
          tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tool_proxy_fixture, context: account, guid: tool_proxy_guid)
          rh = tool_proxy.resources.first
          expect(rh.message_handlers.first.placements).to include_placements %w(assignment_selection link_selection)
        end

        it "doesn't include defaults placements when one is provided" do
          tp_json = JSON.parse(tool_proxy_fixture)
          tp_json['tool_profile']['resource_handler'][0]['message'][0]['enabled_capability'] = ['Canvas.placements.courseNavigation']
          tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tp_json.to_json, context: account, guid: tool_proxy_guid)
          rh = tool_proxy.resources.first
          expect(rh.message_handlers.first.placements).to only_include_placement "course_navigation"
        end

        it "adds placements from message_handler enabled_capabilities to message_hanlder" do
          tp_json = JSON.parse(tool_proxy_fixture)
          tp_json['tool_profile']['resource_handler'][0]['message'][0]['enabled_capability'] = ['Canvas.placements.courseNavigation']
          tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tp_json.to_json, context: account, guid: tool_proxy_guid)
          rh = tool_proxy.resources.first
          expect(rh.message_handlers.count).to eq 1
          expect(rh.message_handlers.first.placements).to only_include_placement "course_navigation"
        end

        it "handles non-valid placements" do
          tp_json = JSON.parse(tool_proxy_fixture)
          tp_json['tool_profile']['resource_handler'][0]['message'][0]['enabled_capability'] = ['Canvas.placements.invalid']
          begin
            tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tp_json.to_json, context: account, guid: tool_proxy_guid)
          rescue Lti::ToolProxyService::InvalidToolProxyError => proxy_error
            puts proxy_error.message
          end
          expect(tool_proxy).to eq nil
        end

      end


      it 'rejects tool proxies that have extra capabilities' do
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.tool_profile.resource_handlers.first.messages.first.enabled_capability = ['extra_capability']
        expect { tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid) }.to raise_error(ToolProxyService::InvalidToolProxyError, 'Invalid Capabilities') do |exception|
          expect(JSON.parse(exception.to_json)).to eq({"invalid_capabilities"=>["extra_capability"], "error"=>"Invalid Capabilities"})
        end

      end

      it 'rejects tool proxies that have extra services' do
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.security_contract.services.first.action = ['DELETE']
        expect { tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid) }.to raise_error(ToolProxyService::InvalidToolProxyError, 'Invalid Services') do |exception|
          expect(JSON.parse(exception.to_json)).to eq({"invalid_services"=>[{"id"=>"ToolProxy.collection", "actions"=>["DELETE"]}], "error"=>"Invalid Services"})
        end
      end

      it 'rejects tool proxies that have extra variables' do
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.tool_profile.resource_handlers.first.messages.first.parameter = [IMS::LTI::Models::Parameter.new(name:'extra_test', variable: 'Custom.Variable')]
        expect { tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid) }.to raise_error(ToolProxyService::InvalidToolProxyError, 'Invalid Capabilities')do |exception|
          expect(JSON.parse(exception.to_json)).to eq({"invalid_capabilities"=>["Custom.Variable"], "error"=>"Invalid Capabilities"})
        end
      end

      it 'rejects tool proxies that are missing a shared secret' do
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.security_contract.shared_secret = nil
        expect { tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid) }.to raise_error(ToolProxyService::InvalidToolProxyError, 'Invalid SecurityContract')do |exception|
          expect(JSON.parse(exception.to_json)).to eq({"invalid_security_contract"=>["shared_secret"], "error"=>"Invalid SecurityContract"})
        end
      end

      it 'creates a split secret whith the depricated Oauth.splitSecret' do
        tp_half_secret = SecureRandom.hex(64)
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.enabled_capability = ['OAuth.splitSecret']
        tp.security_contract.shared_secret = nil
        tp.security_contract.tp_half_shared_secret = tp_half_secret
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid)
        expect(tool_proxy_service.tc_half_secret).to_not be_nil
        expect(tool_proxy.shared_secret).to eq(tool_proxy_service.tc_half_secret + tp_half_secret)
      end

      it 'creates a split secret whith Security.splitSecret' do
        tp_half_secret = SecureRandom.hex(64)
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.enabled_capability = ['Security.splitSecret']
        tp.security_contract.shared_secret = nil
        tp.security_contract.tp_half_shared_secret = tp_half_secret
        tool_proxy = tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid)
        expect(tool_proxy_service.tc_half_secret).to_not be_nil
        expect(tool_proxy.shared_secret).to eq(tool_proxy_service.tc_half_secret + tp_half_secret)
      end

      it 'requires the "OAuth.splitSecret" capability for split secret' do
        tp_half_secret = SecureRandom.hex(64)
        tp = IMS::LTI::Models::ToolProxy.new.from_json(tool_proxy_fixture)
        tp.enabled_capability = []
        tp.security_contract.shared_secret = nil
        tp.security_contract.tp_half_shared_secret = tp_half_secret
        expect { tool_proxy_service.process_tool_proxy_json(json: tp.as_json, context: account, guid: tool_proxy_guid) }
          .to raise_error(ToolProxyService::InvalidToolProxyError, 'Invalid SecurityContract') do |exception|
          expect(JSON.parse(exception.to_json)).to eq({
                                                        "invalid_security_contract" => [
                                                          "shared_secret",
                                                          "tp_half_shared_secret"
                                                        ],
                                                        "error"=>"Invalid SecurityContract"
                                                      })
        end
      end
    end

    describe '#delete_subscriptions' do
      let(:course) do
        course_with_student_submissions(active_all: true)
        @course
      end
      let(:assignment) { course.assignments.first }
      let(:assignment_two) do
        assignment_two = assignment.dup
        assignment_two.update_attributes(lti_context_id: SecureRandom.uuid)
        assignment_two
      end
      let(:subscription_id) { SecureRandom.uuid }
      let(:stub_response) { double(code: 200, body: '{}', parsed_response: {'Id' => subscription_id}, ok?: true) }
      let(:sub_service_double) { class_double(Services::LiveEventsSubscriptionService).as_stubbed_const }

      before(:each) do
        allow(sub_service_double).to receive_messages(create_tool_proxy_subscription: stub_response)
        allow(sub_service_double).to receive_messages(available?: true)
        assignment.tool_settings_tool = message_handler
        assignment_two.tool_settings_tool = message_handler
        assignment.save!
        assignment_two.save!
      end

      it 'deletes all subscriptions for the spcified tool proxy' do
        expect(sub_service_double).to receive(:destroy_tool_proxy_subscription).twice
        tool_proxy_service.delete_subscriptions_for(tool_proxy)
        run_jobs
      end

      it 'deletes the correct subscriptions for the specified tool proxy' do
        expect(sub_service_double).to receive(:destroy_tool_proxy_subscription).twice.with(tool_proxy, subscription_id)
        tool_proxy_service.delete_subscriptions_for(tool_proxy)
        run_jobs
      end
    end
  end
end
