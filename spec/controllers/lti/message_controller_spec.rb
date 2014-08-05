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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

module Lti
  describe MessageController do

    describe "GET #registration" do
      context 'course' do
        it 'initiates a tool proxy registration request' do
          course_with_teacher_logged_in(:active_all => true)
          get 'registration', course_id: @course.id, tool_consumer_url: 'http://tool.consumer.url'
          lti_launch = assigns[:lti_launch]
          lti_launch.resource_url.should == 'http://tool.consumer.url'
          launch_params = lti_launch.params
          launch_params['lti_message_type'].should == 'ToolProxyRegistrationRequest'
          launch_params['lti_version'].should == 'LTI-2p0'
          launch_params['launch_presentation_document_target'].should == 'iframe'
          launch_params['reg_key'].should_not be_empty
          launch_params['reg_password'].should_not be_empty

          account_tp_url_stub = course_tool_consumer_profile_url(@course, 'abc123').gsub('abc123', '')
          launch_params['tc_profile_url'].should include(account_tp_url_stub)
        end
      end

      context 'account' do
        it 'initiates a tool proxy registration request' do
          course_with_teacher_logged_in(:active_all => true)
          get 'registration', account_id: @course.root_account.id, tool_consumer_url: 'http://tool.consumer.url'
          lti_launch = assigns[:lti_launch]
          lti_launch.resource_url.should == 'http://tool.consumer.url'
          launch_params = lti_launch.params
          launch_params['lti_message_type'].should == 'ToolProxyRegistrationRequest'
          launch_params['lti_version'].should == 'LTI-2p0'
          launch_params['launch_presentation_document_target'].should == 'iframe'
          launch_params['reg_key'].should_not be_empty
          launch_params['reg_password'].should_not be_empty
          account_tp_url_stub = account_tool_consumer_profile_url(@course.root_account, 'abc123').gsub('abc123', '')
          launch_params['tc_profile_url'].should include(account_tp_url_stub)
        end
      end

    end

    describe "GET #basic_lti_launch_reuqest" do

      let (:account) { Account.create }
      let (:product_family) { ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account) }
      let (:resource_handler) { ResourceHandler.create(resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy) }
      let (:message_handler) { MessageHandler.create(message_type: 'message_type', launch_path:'https://samplelaunch/blti', resource: resource_handler)}
      let (:tool_proxy) { ToolProxy.create(
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        context: account,
        workflow_state: 'active',
        raw_data: 'some raw data'
      ) }

      context 'account' do
        before :each do
          @tool_proxy_binding = ToolProxyBinding.create(context: account, tool_proxy: tool_proxy)
        end

        it 'returns the signed params' do
          get 'basic_lti_launch_request', account_id: account.id, lti_message_handler_id: message_handler.id
          response.code.should == "200"

          lti_launch = assigns[:lti_launch]
          lti_launch.resource_url.should == 'https://samplelaunch/blti'
          params = lti_launch.params.with_indifferent_access
          params[:oauth_consumer_key].should == 'guid'
          params[:context_id].should_not be_empty
          params[:resource_link_id].should_not be_empty
          params[:tool_consumer_instance_guid].should_not be_empty
          params[:launch_presentation_document_target].should == 'iframe'
          params[:oauth_signature].should_not be_empty
        end

        it 'returns a 404 when when no handler is found' do
          get 'basic_lti_launch_request', account_id: account.id, lti_message_handler_id: 0
          response.code.should == "404"
        end

      end
    end
  end
end
