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
require_dependency "lti/message_controller"

module Lti
  describe MessageController do

    let(:account) { Account.create }
    let(:product_family) do
      ProductFamily.create(vendor_code: '123', product_code: 'abc', vendor_name: 'acme', root_account: account)
    end
    let(:resource_handler) do
      ResourceHandler.create(resource_type_code: 'code', name: 'resource name', tool_proxy: tool_proxy)
    end
    let(:message_handler) do
      MessageHandler.create(
        message_type: 'basic-lti-launch-request',
        launch_path: 'https://samplelaunch/blti',
        resource_handler: resource_handler
      )
    end
    let(:enabled_capability) {
      %w(ToolConsumerInstance.guid
         Message.documentTarget
         Message.locale
         Membership.role
         Context.id)
    }
    let(:tool_proxy) do
      ToolProxy.create(
        shared_secret: 'shared_secret',
        guid: 'guid',
        product_version: '1.0beta',
        lti_version: 'LTI-2p0',
        product_family: product_family,
        context: account,
        workflow_state: 'active',
        raw_data: {enabled_capability: enabled_capability}
      )
    end
    let(:default_resource_handler) do
      ResourceHandler.create!(
        resource_type_code: 'instructure.com:default',
        name: 'resource name',
        tool_proxy: tool_proxy
      )
    end

    describe "GET #registration" do
      context 'course' do
        it 'initiates a tool proxy registration request' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'registration', course_id: course.id, tool_consumer_url: 'http://tool.consumer.url'
          expect(response).to be_success
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'http://tool.consumer.url'
          launch_params = lti_launch.params
          expect(launch_params['lti_message_type'])
            .to eq IMS::LTI::Models::Messages::RegistrationRequest::MESSAGE_TYPE
          expect(launch_params['lti_version']).to eq 'LTI-2p0'
          expect(launch_params['launch_presentation_document_target']).to eq 'iframe'
          expect(launch_params['reg_key']).not_to be_empty
          expect(launch_params['reg_password']).not_to be_empty
          expect(launch_params['launch_presentation_return_url'])
            .to include "courses/#{course.id}/lti/registration_return"
          expect(launch_params['ext_tool_consumer_instance_guid']).to eq @course.root_account.lti_guid
          expect(launch_params['ext_api_domain']).to eq HostUrl.context_host(course, request.host)
          account_tp_url_stub = course_tool_consumer_profile_url(course, 'abc123').gsub('abc123', '')
          expect(launch_params['tc_profile_url']).to include(account_tp_url_stub)
        end

        it "doesn't allow student to register an app" do
          course_with_student_logged_in(active_all:true)
          get 'registration', course_id: @course.id, tool_consumer_url: 'http://tool.consumer.url'
          expect(response.code).to eq '401'
        end

      end

      context 'account' do
        it 'initiates a tool proxy registration request' do
          user_session(account_admin_user)
          get 'registration', account_id: Account.default, tool_consumer_url: 'http://tool.consumer.url'
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'http://tool.consumer.url'
          launch_params = lti_launch.params
          expect(launch_params['lti_message_type'])
            .to eq IMS::LTI::Models::Messages::RegistrationRequest::MESSAGE_TYPE
          expect(launch_params['lti_version']).to eq 'LTI-2p0'
          expect(launch_params['launch_presentation_document_target']).to eq 'iframe'
          expect(launch_params['reg_key']).not_to be_empty
          expect(launch_params['reg_password']).not_to be_empty
          account_tp_url_stub = account_tool_consumer_profile_url(Account.default, 'abc123').gsub('abc123', '')
          expect(launch_params['tc_profile_url']).to include(account_tp_url_stub)
        end

        it "doesn't allow non admin to register an app" do
          get 'registration', account_id: Account.default, tool_consumer_url: 'http://tool.consumer.url'
          assert_unauthorized
        end

      end

    end

    describe "GET #reregistration" do
      before(:each) do
        MessageHandler.create!(
          message_type: IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE,
          launch_path: 'https://samplelaunch/rereg',
          resource_handler: default_resource_handler
        )
      end
      context 'course' do
        it 'initiates a tool proxy reregistration request' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          expect(response.code).to eq "200"
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          expect(launch_params['lti_message_type'])
            .to eq IMS::LTI::Models::Messages::ToolProxyReregistrationRequest::MESSAGE_TYPE
        end

        it 'sends the correct version' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          expect(launch_params['lti_version']).to eq 'LTI-2p1'
        end

        it 'sends the correct resource_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'https://samplelaunch/rereg'
        end

        it 'sends the correct oauth_consumer_key' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          lti_launch = assigns[:lti_launch]
          params = lti_launch.params.with_indifferent_access
          expect(params[:oauth_consumer_key]).to eq 'guid'
        end

        it 'sends the correct tc_profile_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          account_tp_url_stub = course_tool_consumer_profile_url(course, 'abc123').gsub('abc123', '')
          expect(launch_params['tc_profile_url']).to include(account_tp_url_stub)
        end

        it 'sends the correct tc_profile_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params

          expected_launch = "courses/#{course.id}/lti/registration_return"
          expect(launch_params['launch_presentation_return_url']).to include expected_launch
        end


         it 'returns an error if there is not a reregistration handler'do
           course_with_teacher_logged_in(:active_alll => true)
           course = @course
           default_resource_handler.message_handlers.first.destroy
           get 'reregistration', course_id: course.id, tool_proxy_id: tool_proxy.id
           expect(response.code).to eq "404"
         end

        it "doesn't allow a student to reregister an app" do
          course_with_student_logged_in(active_all:true)
          get 'reregistration', course_id: course_factory.id, tool_proxy_id: tool_proxy.id
          expect(response.code).to eq '404'
        end

      end
    end

    describe "GET #basic_lti_launch_request" do

      context 'account' do

        before do
          ToolProxyBinding.create(context: account, tool_proxy: tool_proxy)
        end

        it 'returns the signed params' do
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          expect(response.code).to eq "200"

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'https://samplelaunch/blti'
          params = lti_launch.params.with_indifferent_access
          expect(params[:oauth_consumer_key]).to eq 'guid'
          expect(params[:context_id]).not_to be_empty
          expect(params[:resource_link_id]).not_to be_empty
          expect(params[:tool_consumer_instance_guid]).not_to be_empty
          expect(params[:launch_presentation_document_target]).to eq 'iframe'
          expect(params[:oauth_signature]).not_to be_empty
        end

        it 'launches gracefully if it can not find the content_tag for the given module_item_id' do
          course = Course.create!
          tag = course.context_module_tags.create!(context: account, tag_type: 'context_module')
          tag.context_module = ContextModule.create!(context: course)
          tag.save!
          tag.delete
          get 'basic_lti_launch_request', course_id: course.id, message_handler_id: message_handler.id,
              module_item_id: tag.id, params: {tool_launch_context: 'my_custom_context' }
          expect(response.code).to eq "200"
        end

        it 'sets the active tab' do
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id
          expect(response.code).to eq "200"
          expect(assigns[:active_tab]).to eq message_handler.asset_string
        end

        it 'returns a 404 when when no handler is found' do
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: 0
          expect(response.code).to eq "404"
        end

        it 'does custom variable expansion for tool settings' do
          parameters = %w( LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url ).map do |key|
            IMS::LTI::Models::Parameter.new(name: key.underscore, variable: key )
          end
          message_handler.parameters = parameters.as_json
          message_handler.save

          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id
          expect(response.code).to eq "200"

          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_lti_link.custom.url']).to include('api/lti/tool_settings/')
          expect(params['custom_tool_proxy_binding.custom.url']).to include('api/lti/tool_settings/')
          expect(params['custom_tool_proxy.custom.url']).to include('api/lti/tool_settings/')
        end

        it 'returns the roles' do
          course_with_student(account: account, active_all: true)
          user_session(@student)
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['roles']).to eq "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"
        end

        it 'adds module item substitutions' do
          course = Course.create!
          parameters = %w( Canvas.module.id Canvas.moduleItem.id ).map do |key|
            IMS::LTI::Models::Parameter.new(name: key.underscore, variable: key )
          end
          message_handler.parameters = parameters.as_json
          message_handler.save

          tag = message_handler.context_module_tags.create!(context: course, tag_type: 'context_module')
          tag.context_module = ContextModule.create!(context: course)
          tag.save!

          get 'basic_lti_launch_request', course_id: course.id, message_handler_id: message_handler.id,
              module_item_id: tag.id, params: {tool_launch_context: 'my_custom_context' }
          expect(response.code).to eq "200"

          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_canvas.module.id']).to eq tag.context_module_id
          expect(params['custom_canvas.module_item.id']).to eq tag.id
        end

        it 'sets the launch to window' do
          course = Course.create!
          tag = message_handler.context_module_tags.create!(context: course, tag_type: 'context_module', new_tab: true)
          tag.context_module = ContextModule.create!(context: course)
          tag.save!
          get 'basic_lti_launch_request', course_id: course.id, message_handler_id: message_handler.id,
              module_item_id: tag.id, params: {tool_launch_context: 'my_custom_context' }
          expect(response.code).to eq "200"
          expect(assigns[:lti_launch].launch_type).to eq 'window'
        end

        it 'returns the locale' do
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['launch_presentation_locale']).to eq :en
        end

        it 'returns tool settings in the launch' do
          ToolSetting.create(tool_proxy: tool_proxy, context_id: nil, context_type: nil, resource_link_id: nil,
                             custom:{'default' => 42})
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_default']).to eq 42
        end

        it 'does not do variable substitutions for tool settings' do
          ToolSetting.create(tool_proxy: tool_proxy, context_id: nil, context_type: nil, resource_link_id: nil,
                             custom:{'default' => 'Canvas.api.baseUrl'})
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_default']).to eq 'Canvas.api.baseUrl'
        end

        it 'adds params from secure_params' do
          lti_assignment_id = SecureRandom.uuid
          jwt = Canvas::Security.create_jwt({lti_assignment_id: lti_assignment_id})
          get 'basic_lti_launch_request', account_id: account.id,
            message_handler_id: message_handler.id, secure_params: jwt
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['ext_lti_assignment_id']).to eq lti_assignment_id
        end

        it 'does only adds non-required params if they are present in enabled_capability' do
          allow_any_instance_of(IMS::LTI::Models::ToolProxy).to receive(:enabled_capability) { {} }

          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          expect(response.code).to eq "200"

          lti_launch = assigns[:lti_launch]
          params = lti_launch.params.with_indifferent_access

          expect(params[:launch_presentation_locale]).to be_nil
          expect(params[:tool_consumer_instance_guid]).to be_nil
          expect(params[:launch_presentation_document_target]).to be_nil
        end
      end

      describe "resource link" do
        it 'creates resource_links without a resource_link_fragment' do
          Timecop.freeze do
            get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
                params: {tool_launch_context: 'my_custom_context'}
            expect(response.code).to eq "200"

            lti_launch = assigns[:lti_launch]
            params = lti_launch.params.with_indifferent_access
            expected_id = Canvas::Security.hmac_sha1("Account_#{account.global_id},MessageHandler_#{message_handler.global_id}")
            expect(params[:resource_link_id]).to eq expected_id
          end
        end

        it 'creates with a resource_link_fragment' do
          Timecop.freeze do
            get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
                resource_link_fragment: 'my_custom_postfix'
            expect(response.code).to eq "200"

            lti_launch = assigns[:lti_launch]
            params = lti_launch.params.with_indifferent_access
            expected_id = Canvas::Security.hmac_sha1("Account_#{account.global_id},MessageHandler_#{message_handler.global_id},my_custom_postfix")
            expect(params[:resource_link_id]).to eq expected_id
          end
        end


      end

      context 'tool settings' do
        it 'creates the tool proxy setting object' do
          message_handler.parameters = [{ "name" => "tool_settings", "variable" => "ToolProxy.custom.url" }]
          message_handler.save!
          expect(ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: nil, resource_link_id: nil).size).to eq 0
          get 'basic_lti_launch_request', account_id: account.id, message_handler_id: message_handler.id,
              params: {tool_launch_context: 'my_custom_context'}
          expect(ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: nil, resource_link_id: nil).size).to eq 1
        end
      end

    end
  end
end
