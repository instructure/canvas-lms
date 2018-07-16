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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../lti2_spec_helper')
require_dependency "lti/message_controller"

module Lti
  describe MessageController do
    include_context 'lti2_spec_helper'
    let(:enabled_capability) {
      %w(ToolConsumerInstance.guid
         Message.documentTarget
         Message.locale
         Membership.role
         Context.id)
    }

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
          post 'registration', params: {course_id: course.id, tool_consumer_url: 'http://tool.consumer.url'}
          expect(response).to be_successful
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
          account_tp_url_stub = course_tool_consumer_profile_url(course)
          expect(launch_params['tc_profile_url']).to include(account_tp_url_stub)
          expect(launch_params['oauth2_access_token_url']).to eq "http://test.host/api/lti/courses/#{course.id}/authorize"
        end

        it "doesn't allow student to register an app" do
          course_with_student_logged_in(active_all: true)
          post 'registration', params: {course_id: @course.id, tool_consumer_url: 'http://tool.consumer.url'}
          expect(response.code).to eq '401'
        end

        it "includes the authorization URL when feature flag enabled" do
          allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(true)
          course_with_teacher_logged_in(active_all: true)
          post 'registration', params: {course_id: @course.id, tool_consumer_url: 'http://tool.consumer.url'}
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          expect(launch_params['oauth2_access_token_url']).to(
            eq controller.polymorphic_url([@course, :lti_oauth2_authorize])
          )
        end

        it 'only allows http and https protocols in the "tool_consumer_url"' do
          course_with_student_logged_in(active_all: true)
          user_session(@teacher)
          post 'registration', params: {course_id: @course.id, tool_consumer_url: 'javascript://tool.consumer.url'}
          expect(response).to be_bad_request
        end
      end

      context 'account' do
        it 'initiates a tool proxy registration request' do
          user_session(account_admin_user)
          post 'registration', params: {account_id: Account.default, tool_consumer_url: 'http://tool.consumer.url'}
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'http://tool.consumer.url'
          launch_params = lti_launch.params
          expect(launch_params['lti_message_type'])
            .to eq IMS::LTI::Models::Messages::RegistrationRequest::MESSAGE_TYPE
          expect(launch_params['lti_version']).to eq 'LTI-2p0'
          expect(launch_params['launch_presentation_document_target']).to eq 'iframe'
          expect(launch_params['reg_key']).not_to be_empty
          expect(launch_params['reg_password']).not_to be_empty
          account_tp_url_stub = account_tool_consumer_profile_url(Account.default)
          expect(launch_params['tc_profile_url']).to include(account_tp_url_stub)
        end

        it "doesn't allow non admin to register an app" do
          post 'registration', params: {account_id: Account.default, tool_consumer_url: 'http://tool.consumer.url'}
          assert_unauthorized
        end

      end

    end

    describe 'GET #registration_return' do
      before {user_session(account_admin_user)}

      it 'does not 500 if tool registration fails' do
        get 'registration_return', params: {course_id: course.id, status: 'failure'}
        expect(response).to be_succes
      end
    end

    describe "GET #reregistration" do
      before(:each) do
        MessageHandler.create!(
          message_type: IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE,
          launch_path: 'https://samplelaunch/rereg',
          resource_handler: default_resource_handler
        )
      end
      context 'course' do
        it 'initiates a tool proxy reregistration request' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          expect(response.code).to eq "200"
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          expect(launch_params[:lti_message_type])
            .to eq IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE
        end

        it 'sends the correct version' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          expect(launch_params[:lti_version]).to eq 'LTI-2p0'
        end

        it 'sends the correct resource_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'https://samplelaunch/rereg'
        end

        it 'sends the correct oauth_consumer_key' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          lti_launch = assigns[:lti_launch]
          params = lti_launch.params.with_indifferent_access
          expect(params[:oauth_consumer_key]).to eq tool_proxy.guid
        end

        it 'sends the correct tc_profile_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params
          account_tp_url_stub = course_tool_consumer_profile_url(course)
          expect(launch_params[:tc_profile_url]).to include(account_tp_url_stub)
        end

        it 'sends the correct launch_presentation_return_url' do
          course_with_teacher_logged_in(:active_all => true)
          course = @course
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          lti_launch = assigns[:lti_launch]
          launch_params = lti_launch.params

          expected_launch = "courses/#{course.id}/lti/registration_return"
          expect(launch_params[:launch_presentation_return_url]).to include expected_launch
        end


        it 'returns an error if there is not a reregistration handler' do
          course_with_teacher_logged_in(:active_alll => true)
          course = @course
          default_resource_handler.message_handlers.first.destroy
          get 'reregistration', params: {course_id: course.id, tool_proxy_id: tool_proxy.id}
          expect(response.code).to eq "404"
        end

        it "doesn't allow a student to reregister an app" do
          course_with_student_logged_in(active_all: true)
          get 'reregistration', params: {course_id: course_factory.id, tool_proxy_id: tool_proxy.id}
          expect(response.code).to eq '404'
        end

      end
    end

    describe "GET #resource_link_id" do
      include_context 'lti2_spec_helper'

      let(:link_id) {SecureRandom.uuid}

      let(:lti_link) do
        Link.new(resource_link_id: link_id,
                 vendor_code: product_family.vendor_code,
                 product_code: product_family.product_code,
                 resource_type_code: resource_handler.resource_type_code)
      end

      before do
        message_handler.update_attributes(message_type: MessageHandler::BASIC_LTI_LAUNCH_REQUEST)
        resource_handler.message_handlers = [message_handler]
        resource_handler.save!
        lti_link.save!
        user_session(account_admin_user)
      end

      it 'succeeds if tool is installed in the current account' do
        get 'resource', params: {account_id: account.id, resource_link_id: link_id}
        expect(response).to be_ok
      end

      it 'succeeds if the tool is installed in the current course' do
        tool_proxy.update_attributes(context: course)
        get 'resource', params: {course_id: course.id, resource_link_id: link_id}
        expect(response).to be_ok
      end

      it "succeeds if the tool is installed in the current course's account" do
        tool_proxy.update_attributes(context: account)
        get 'resource', params: {course_id: course.id, resource_link_id: link_id}
        expect(response).to be_ok
      end

      context 'resource_url' do
        let(:custom_url) {'http://www.samplelaunch.com/custom-resource-url'}
        let(:link_id) {SecureRandom.uuid}
        let(:lti_link) do
          Link.create!(resource_link_id: link_id,
                       vendor_code: product_family.vendor_code,
                       product_code: product_family.product_code,
                       resource_type_code: resource_handler.resource_type_code,
                       resource_url: custom_url)
        end

        it "uses the 'resource_url' if provided in the 'link_id'" do
          get 'resource', params: {account_id: account.id, resource_link_id: link_id}
          expect(assigns[:lti_launch].resource_url).to eq custom_url
        end

        it "responds with 400 if host name does not match" do
          message_handler.update_attributes(launch_path: 'http://www.different.com')
          get 'resource', params: {account_id: account.id, resource_link_id: link_id}
          expect(response).to be_bad_request
        end
      end

      context 'assignment' do
        let(:assignment) {course.assignments.create!(name: 'test')}

        before {tool_proxy.update_attributes(context: course)}

        it 'finds the specified assignment' do
          get 'resource', params: {course_id: course.id,
              assignment_id: assignment.id,
              resource_link_id: link_id}
          expect(assigns[:_assignment]).to eq assignment
        end

        it 'renders not found if assignment does not exist' do
          get 'resource', params: {course_id: course.id,
              assignment_id: assignment.id + 1,
              resource_link_id: link_id}
          expect(response).to be_not_found
        end
      end

      context 'search account chain' do
        let(:root_account) {Account.create!}

        before {account.update_attributes(root_account: root_account)}

        it "succeeds if the tool is installed in the current account's root account" do
          tool_proxy.update_attributes(context: root_account)
          get 'resource', params: {account_id: account.id, resource_link_id: link_id}
          expect(response).to be_ok
        end

        it "succeeds if the tool is installed in the current course's root account" do
          tool_proxy.update_attributes(context: root_account)
          get 'resource', params: {course_id: course.id, resource_link_id: link_id}
          expect(response).to be_ok
        end
      end

      it "renders 'not found' no message handler is found" do
        resource_handler.message_handlers = []
        resource_handler.save!
        get 'resource', params: {account_id: account.id, resource_link_id: link_id}
        expect(response).to be_not_found
      end
    end

    describe "GET #basic_lti_launch_request" do
      before(:each) do
        course_with_student(account: account, active_all: true)
        user_session(@student)
      end

      context 'jwt' do
        let(:tool_profile) do
          {
            'security_profile' => { 'security_profile_name' => 'lti_jwt_message_security' }
          }
        end

        before(:each) do
          tool_proxy.raw_data['tool_profile'] = tool_profile
          tool_proxy.save!
        end

        it 'does a jwt launch' do
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params
          expect(params.keys).to eq [:jwt]
        end

        it 'signs the jwt with the shared secret' do
          get 'basic_lti_launch_request', params: {account_id: account.id,
                                                      message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params
          launch_url = assigns[:lti_launch].resource_url
          authenticator = IMS::LTI::Services::MessageAuthenticator.new(launch_url, params, tool_proxy.shared_secret)
          expect(authenticator.valid_signature?).to eq true
        end

        it 'returns the roles as an array' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          get 'basic_lti_launch_request', params: {account_id: account.id,
                                                   message_handler_id: message_handler.id,
                                                   params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.stringify_keys!
          message = IMS::LTI::Models::Messages::Message.generate(params)
          expect(message.post_params["roles"]).to eq ["http://purl.imsglobal.org/vocab/lis/v2/system/person#User"]
        end

        it 'url encodes the aud' do
          message_handler.launch_path = "http://example.com/test?query with space=true"
          message_handler.save!
          get 'basic_lti_launch_request', params: {account_id: account.id,
                                                   message_handler_id: message_handler.id,
                                                   params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.stringify_keys!
          aud = JSON::JWT.decode(params["jwt"], :skip_verification)["aud"]
          expect(aud).to eq "http://example.com/test?query%20with%20space=true"
        end

      end

      context 'account' do

        it 'returns the signed params' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          expect(response.code).to eq "200"

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.resource_url).to eq 'https://www.samplelaunch.com/blti'
          params = lti_launch.params.with_indifferent_access
          expect(params[:oauth_consumer_key]).to eq tool_proxy.guid
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
          get 'basic_lti_launch_request', params: {course_id: course.id, message_handler_id: message_handler.id,
                                                      module_item_id: tag.id, params: { tool_launch_context: 'my_custom_context' }}
          expect(response.code).to eq "200"
        end

        it 'sets the active tab' do
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id}
          expect(response.code).to eq "200"
          expect(assigns[:active_tab]).to eq message_handler.asset_string
        end

        it 'returns a 404 when when no handler is found' do
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: 0}
          expect(response.code).to eq "404"
        end

        it 'redirects to login page if there is no session' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          allow(PseudonymSession).to receive(:find).and_return(nil)
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id}
          expect(response).to redirect_to(login_url)
        end

        it 'does custom variable expansion for tool settings' do
          parameters = %w( LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url ).map do |key|
            IMS::LTI::Models::Parameter.new(name: key.underscore, variable: key)
          end
          message_handler.parameters = parameters.as_json
          message_handler.save

          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id}
          expect(response.code).to eq "200"

          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_lti_link.custom.url']).to include('api/lti/tool_settings/')
          expect(params['custom_tool_proxy_binding.custom.url']).to include('api/lti/tool_settings/')
          expect(params['custom_tool_proxy.custom.url']).to include('api/lti/tool_settings/')
        end

        it 'returns the roles' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['roles']).to eq "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"
        end

        it 'returns the oauth_callback' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                   params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['oauth_callback']).to eq 'about:blank'
        end


        it 'adds module item substitutions' do
          parameters = %w( Canvas.module.id Canvas.moduleItem.id ).map do |key|
            IMS::LTI::Models::Parameter.new(name: key.underscore, variable: key)
          end
          message_handler.parameters = parameters.as_json
          message_handler.save

          tag = message_handler.context_module_tags.create!(context: @course, tag_type: 'context_module')
          tag.context_module = ContextModule.create!(context: @course)
          tag.save!

          get 'basic_lti_launch_request', params: {course_id: @course.id, message_handler_id: message_handler.id,
                                                      module_item_id: tag.id, params: { tool_launch_context: 'my_custom_context' }}
          expect(response.code).to eq "200"

          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_canvas.module.id']).to eq tag.context_module_id
          expect(params['custom_canvas.module_item.id']).to eq tag.id
        end

        it 'sets the launch to window' do
          tag = message_handler.context_module_tags.create!(context: @course, tag_type: 'context_module', new_tab: true)
          tag.context_module = ContextModule.create!(context: @course)
          tag.save!
          get 'basic_lti_launch_request', params: {course_id: @course.id, message_handler_id: message_handler.id,
                                                      module_item_id: tag.id, params: { tool_launch_context: 'my_custom_context' }}
          expect(response.code).to eq "200"
          expect(assigns[:lti_launch].launch_type).to eq 'window'
        end

        it 'returns the locale' do
          tool_proxy.raw_data['enabled_capability'] += enabled_capability
          tool_proxy.save!
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['launch_presentation_locale']).to eq :en
        end

        it 'returns tool settings in the launch' do
          ToolSetting.create(tool_proxy: tool_proxy, context_id: nil, context_type: nil, resource_link_id: nil,
                             custom: { 'default' => 42 })
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_default']).to eq 42
        end

        it 'does not do variable substitutions for tool settings' do
          ToolSetting.create(tool_proxy: tool_proxy, context_id: nil, context_type: nil, resource_link_id: nil,
                             custom: { 'default' => 'Canvas.api.baseUrl' })
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['custom_default']).to eq 'Canvas.api.baseUrl'
        end

        it 'adds params from secure_params' do
          lti_assignment_id = SecureRandom.uuid
          jwt = Canvas::Security.create_jwt({ lti_assignment_id: lti_assignment_id })
          get 'basic_lti_launch_request', params: {account_id: account.id,
              message_handler_id: message_handler.id, secure_params: jwt}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['ext_lti_assignment_id']).to eq lti_assignment_id
        end

        it 'uses the lti_assignment_id as the resource_link_id' do
          lti_assignment_id = SecureRandom.uuid
          jwt = Canvas::Security.create_jwt({ lti_assignment_id: lti_assignment_id })
          get 'basic_lti_launch_request', params: {account_id: account.id,
                                                   message_handler_id: message_handler.id, secure_params: jwt}
          params = assigns[:lti_launch].params.with_indifferent_access
          expect(params['resource_link_id']).to eq lti_assignment_id
        end

        it 'does only adds non-required params if they are present in enabled_capability' do
          allow_any_instance_of(IMS::LTI::Models::ToolProxy).to receive(:enabled_capability) {{}}

          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
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
            get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                        params: { tool_launch_context: 'my_custom_context' }}
            expect(response.code).to eq "200"

            lti_launch = assigns[:lti_launch]
            params = lti_launch.params.with_indifferent_access
            expected_id = Canvas::Security.hmac_sha1("Account_#{account.global_id},MessageHandler_#{message_handler.global_id}")
            expect(params[:resource_link_id]).to eq expected_id
          end
        end

        it 'creates with a resource_link_fragment' do
          Timecop.freeze do
            get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                resource_link_fragment: 'my_custom_postfix'}
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
          get 'basic_lti_launch_request', params: {account_id: account.id, message_handler_id: message_handler.id,
                                                      params: { tool_launch_context: 'my_custom_context' }}
          expect(ToolSetting.where(tool_proxy_id: tool_proxy.id, context_id: nil, resource_link_id: nil).size).to eq 1
        end
      end

    end
  end
end
