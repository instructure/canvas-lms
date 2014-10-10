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

module Lti
  describe ToolProxyService do

    describe '#process_tool_proxy_json' do

      let(:tool_proxy_fixture){File.read(File.join(Rails.root, 'spec', 'fixtures', 'lti', 'tool_proxy.json'))}
      let(:tool_proxy_guid){'guid'}
      let(:account){Account.new}


      it "creates the product_family if it doesn't exist" do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        pf = tool_proxy.product_family
        expect(pf.vendor_code).to eq 'acme.com'
        expect(pf.product_code).to eq 'assessment-tool'
        expect(pf.vendor_name).to eq 'Acme'
        expect(pf.website).to eq 'http://acme.example.com'
        expect(pf.vendor_description).to eq 'Acme is a leading provider of interactive tools for education'
        expect(pf.vendor_email).to eq 'info@example.com'
        expect(pf.root_account).to eq account
      end

      it "uses an exisiting product family if it can" do
        pf = ProductFamily.new
        pf.vendor_code = 'acme.com'
        pf.product_code = 'assessment-tool'
        pf.vendor_name = 'Acme'
        pf.root_account = account.root_account
        pf.save!
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        expect(tool_proxy.product_family.id).to eq pf.id
      end

      it "creates the resource handlers" do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
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
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        resource_handler = tool_proxy.resources.find{|r| r.resource_type_code == 'asmt'}
        mh = resource_handler.message_handlers.first
        expect(mh.message_type).to eq 'basic-lti-launch-request'
        expect(mh.launch_path).to eq 'https://acme.example.com/handler/launchRequest'
        expect(mh.capabilities).to eq [ "Result.autocreate" ]
        expect(mh.parameters).to eq [{'name' => 'result_url', 'variable' => 'Result.url'}, {'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it "creates default message handlers" do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        resource_handler = tool_proxy.resources.find{|r| r.resource_type_code == 'instructure.com:default'}

        expect(resource_handler.name).to eq 'Acme Assessments'
        expect(resource_handler.message_handlers.size).to eq 1
        mh = resource_handler.message_handlers.first
        expect(mh.message_type).to eq 'basic-lti-launch-request'
        expect(mh.launch_path).to eq 'https://acme.example.com/handler/launchRequest'
        expect(mh.capabilities).to eq [ "Result.autocreate" ]
        expect(mh.parameters).to eq [{'name' => 'result_url', 'variable' => 'Result.url'}, {'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it 'creates a tool proxy biding' do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        expect(tool_proxy.bindings.count).to eq 1
        binding = tool_proxy.bindings.first
        expect(binding.context).to eq account
      end

      it 'creates a tool_proxy' do
        SecureRandom.stubs(:uuid).returns('my_uuid')
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        expect(tool_proxy.shared_secret).to eq 'ThisIsASecret!'
        expect(tool_proxy.guid).to eq tool_proxy_guid
        expect(tool_proxy.product_version).to eq '10.3'
        expect(tool_proxy.lti_version).to eq 'LTI-2p0'
        expect(tool_proxy.context).to eq account
        expect(tool_proxy.workflow_state).to eq 'disabled'
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
          tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
          rh = tool_proxy.resources.first
          expect(rh.placements).to include_placements %w(assignment_selection link_selection)
        end

        it "doesn't include defaults placements when one is provided" do
          tp_json = JSON.parse(tool_proxy_fixture)
          tp_json["tool_profile"]["resource_handler"][0]["ext_placements"] = ['Canvas.placements.courseNavigation']
          tool_proxy = subject.process_tool_proxy_json(tp_json.to_json, account, tool_proxy_guid)
          rh = tool_proxy.resources.first
          expect(rh.placements).to only_include_placement "course_navigation"
        end

        it "handles non-valid placements" do
          tp_json = JSON.parse(tool_proxy_fixture)
          tp_json["tool_profile"]["resource_handler"][0]["ext_placements"] = ['Canvas.placements.invalid']
          tool_proxy = subject.process_tool_proxy_json(tp_json.to_json, account, tool_proxy_guid)
          expect(tool_proxy.resources.first.placements.size).to eq 0
        end

      end


    end

  end
end