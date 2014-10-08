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
        pf.vendor_code.should == 'acme.com'
        pf.product_code.should == 'assessment-tool'
        pf.vendor_name.should == 'Acme'
        pf.website.should == 'http://acme.example.com'
        pf.vendor_description.should == 'Acme is a leading provider of interactive tools for education'
        pf.vendor_email.should == 'info@example.com'
        pf.root_account.should == account
      end

      it "uses an exisiting product family if it can" do
        pf = ProductFamily.new
        pf.vendor_code = 'acme.com'
        pf.product_code = 'assessment-tool'
        pf.vendor_name = 'Acme'
        pf.root_account = account.root_account
        pf.save!
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        tool_proxy.product_family.id.should == pf.id
      end

      it "creates the resource handlers" do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        rh = tool_proxy.resources.find{|r| r.resource_type_code == 'asmt'}
        rh.name.should == 'Acme Assessment'
        rh.description.should == 'An interactive assessment using the Acme scale.'
        rh.icon_info.should == [
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
        mh.message_type.should == 'basic-lti-launch-request'
        mh.launch_path.should == 'https://acme.example.com/handler/launchRequest'
        mh.capabilities.should == [ "Result.autocreate" ]
        mh.parameters.should == [{'name' => 'result_url', 'variable' => 'Result.url'}, {'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it "creates default message handlers" do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        resource_handler = tool_proxy.resources.find{|r| r.resource_type_code == 'instructure.com:default'}

        resource_handler.name.should == 'Acme Assessments'
        resource_handler.message_handlers.size.should == 1
        mh = resource_handler.message_handlers.first
        mh.message_type.should == 'basic-lti-launch-request'
        mh.launch_path.should == 'https://acme.example.com/handler/launchRequest'
        mh.capabilities.should == [ "Result.autocreate" ]
        mh.parameters.should == [{'name' => 'result_url', 'variable' => 'Result.url'}, {'name' => 'discipline', 'fixed' => 'chemistry'}]
      end

      it 'creates a tool proxy biding' do
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        tool_proxy.bindings.count.should == 1
        binding = tool_proxy.bindings.first
        binding.context.should == account
      end

      it 'creates a tool_proxy' do
        SecureRandom.stubs(:uuid).returns('my_uuid')
        tool_proxy = subject.process_tool_proxy_json(tool_proxy_fixture, account, tool_proxy_guid)
        tool_proxy.shared_secret.should == 'ThisIsASecret!'
        tool_proxy.guid.should == tool_proxy_guid
        tool_proxy.product_version.should == '10.3'
        tool_proxy.lti_version.should == 'LTI-2p0'
        tool_proxy.context.should == account
        tool_proxy.workflow_state.should == 'disabled'
      end

    end

  end
end