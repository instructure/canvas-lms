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

require 'spec_helper'

describe LtiOutbound::ToolLaunch do
  let(:consumer_instance) do
    consumer_instance = LtiOutbound::LTIConsumerInstance.new
    consumer_instance.id = 'root_account_id'
    consumer_instance.sis_source_id = 'root_account_sis_source_id'
    consumer_instance.domain = 'root_account_domain'
    consumer_instance.lti_guid = 'root_account_lti_guid'
    consumer_instance.name = 'root_account_name'
    consumer_instance
  end

  let(:account) do
    account = LtiOutbound::LTIAccount.new
    account.name = 'account_name'
    account.id = 'account_id'
    account.sis_source_id = 'account_sis_source_id'
    account.consumer_instance = consumer_instance
    account
  end

  let(:course) do
    course = LtiOutbound::LTICourse.new
    course.consumer_instance = consumer_instance
    course.opaque_identifier = 'course_opaque_identifier'
    course.name = 'course_name'
    course.id = 'course_id'
    course.course_code = 'course_code'
    course.sis_source_id = 'course_sis_source_id'
    course
  end

  let(:tool) do
    tool = LtiOutbound::LTITool.new
    tool.name = 'tool_name'
    tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
    tool
  end

  let(:user) do
    teacher_role = LtiOutbound::LTIRoles::ContextNotNamespaced::INSTRUCTOR
    user = LtiOutbound::LTIUser.new
    user.avatar_url = 'avatar_url'
    user.current_roles = 'current_roles'
    user.email = 'nobody@example.com'
    user.first_name = 'first_name'
    user.id = 'user_id'
    user.last_name = 'last_name'
    user.login_id = 'user_login_id'
    user.name = 'user_name'
    user.opaque_identifier = 'user_opaque_identifier'
    user.sis_source_id = 'sis_user_id'
    user.current_roles = [teacher_role]
    user.concluded_roles = []
    user.consumer_instance = consumer_instance
    user
  end

  let(:assignment) do
    assignment = LtiOutbound::LTIAssignment.new
    assignment.id = 'assignment_id'
    assignment.source_id = '123456'
    assignment.title = 'assignment1'
    assignment.points_possible = 100
    assignment.return_types = ['url', 'text']
    assignment.allowed_extensions = ['jpg', 'pdf']
    assignment
  end

  let(:controller) do
    request_mock = double('request')
    allow(request_mock).to receive(:host).returns('/my/url')
    allow(request_mock).to receive(:scheme).returns('https')
    controller = double('controller')
    allow(controller).to receive(:request).returns(request_mock)
    allow(controller).to receive(:logged_in_user).returns(@user)
    controller
  end

  let(:variable_expander) do
    m = double('variable_expander')
    allow(m).to receive(:expand_variables!){ |hash| hash }
    m
  end

  let(:tool_launch) do
    LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                :tool => tool,
                                :user => user,
                                :account => account,
                                :context => course,
                                :link_code => '123456',
                                :return_url => 'http://www.google.com',
                                :outgoing_email_address => 'outgoing_email_address',
                                :variable_expander => variable_expander)
  end

  describe '#generate' do
    it 'generates correct parameters' do
      I18n.config.available_locales_set << :en
      allow(I18n).to receive(:localizer).and_return(-> { :en })

      hash = tool_launch.generate

      expect(hash['lti_message_type']).to eq 'basic-lti-launch-request'
      expect(hash['lti_version']).to eq 'LTI-1p0'
      expect(hash['resource_link_id']).to eq '123456'
      expect(hash['resource_link_title']).to eq 'tool_name'
      expect(hash['user_id']).to eq 'user_opaque_identifier'
      expect(hash['user_image']).to eq 'avatar_url'
      expect(hash['roles']).to eq 'Instructor'
      expect(hash['context_id']).to eq 'course_opaque_identifier'
      expect(hash['context_title']).to eq 'course_name'
      expect(hash['context_label']).to eq 'course_code'
      expect(hash['custom_canvas_user_id']).to eq '$Canvas.user.id'
      expect(hash['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
      expect(hash['custom_canvas_course_id']).to eq '$Canvas.course.id'
      expect(hash['custom_canvas_api_domain']).to eq '$Canvas.api.domain'
      expect(hash['custom_canvas_workflow_state']).to eq '$Canvas.course.workflowState'
      expect(hash['lis_course_offering_sourcedid']).to eq '$CourseSection.sourcedId'
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_sourcedid']).to eq '$Person.sourcedId'
      expect(hash['launch_presentation_locale']).to eq :en #was I18n.default_locale.to_s
      expect(hash['launch_presentation_document_target']).to eq 'iframe'
      expect(hash['launch_presentation_return_url']).to eq 'http://www.google.com'
      expect(hash['tool_consumer_instance_guid']).to eq 'root_account_lti_guid'
      expect(hash['tool_consumer_instance_name']).to eq 'root_account_name'
      expect(hash['tool_consumer_instance_contact_email']).to eq 'outgoing_email_address'
      expect(hash['tool_consumer_info_product_family_code']).to eq 'canvas'
      expect(hash['tool_consumer_info_version']).to eq 'cloud'
      expect(hash['oauth_callback']).to eq 'about:blank'
    end

    it 'allows resource_link_title to be overrriden' do
      hash = tool_launch.generate('resource_link_title' => 'new tool name')
      expect(hash['resource_link_title']).to eq 'new tool name'
    end

    describe 'selected_html' do
      it 'gets escaped and assigned to the key text if passed in' do
        tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                                  :tool => tool,
                                                  :user => user,
                                                  :account => account,
                                                  :context => course,
                                                  :link_code => '123456',
                                                  :return_url => 'http://www.google.com',
                                                  :selected_html => '<div>something</div>',
                                                  :variable_expander => variable_expander)

        hash = tool_launch.generate

        expect(hash['text']).to eq '%3Cdiv%3Esomething%3C%2Fdiv%3E'
      end

      it 'does not include the key if missing' do
        tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                                  :tool => tool,
                                                  :user => user,
                                                  :account => account,
                                                  :context => course,
                                                  :link_code => '123456',
                                                  :return_url => 'http://www.google.com',
                                                  :variable_expander => variable_expander)

        hash = tool_launch.generate

        expect(hash.keys).to_not include('text')

      end
    end

    it 'sets the locale if I18n.localizer exists' do
      I18n.config.available_locales_set << :es
      allow(I18n).to receive(:localizer).and_return(-> { :es })
      hash = tool_launch.generate

      expect(hash['launch_presentation_locale']).to eq :es
    end

    it 'adds account info in launch data for account navigation' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => tool,
                                         :user => user,
                                         :account => account,
                                         :context => account,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com',
                                         :variable_expander => variable_expander).generate
      expect(hash['custom_canvas_account_id']).to eq '$Canvas.account.id'
      expect(hash['custom_canvas_account_sis_id']).to eq '$Canvas.account.sisSourceId'
      expect(hash['custom_canvas_user_login_id']).to eq '$Canvas.user.loginId'
    end

    it 'adds account and user info in launch data for user profile launch' do

      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => tool,
                                         :user => user,
                                         :account => consumer_instance,
                                         :context => user,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com',
                                         :variable_expander => variable_expander).generate
      expect(hash['custom_canvas_account_id']).to eq '$Canvas.account.id'
      expect(hash['custom_canvas_account_sis_id']).to eq '$Canvas.account.sisSourceId'
      expect(hash['lis_person_sourcedid']).to eq '$Person.sourcedId'
      expect(hash['custom_canvas_user_id']).to eq '$Canvas.user.id'
      expect(hash['tool_consumer_instance_guid']).to eq 'root_account_lti_guid' #was hash['tool_consumer_instance_guid']).to eq sub_account.root_account.lti_guid
    end

    it 'does not allow overwriting other parameters from the URI query string' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com?user_id=ATTEMPT_TO_SET_DATA&oauth_callback=ATTEMPT_TO_SET_DATA',
                                         :tool => tool,
                                         :user => user,
                                         :account => account,
                                         :context => course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com',
                                         :variable_expander => variable_expander).generate
      expect(hash['user_id']).to eq 'user_opaque_identifier'
      expect(hash['oauth_callback']).to eq 'about:blank'
    end

    it 'includes custom fields' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      tool.settings = {:custom_fields => {
          'custom_bob' => 'bob',
          'custom_fred' => 'fred',
          'john' => 'john',
          '@$TAA$#$#' => 123}}
      hash = tool_launch.generate
      expect(hash.keys.select { |k| k.match(/^custom_/) }.sort).to eq(
                                                                       ['custom___taa____', 'custom_bob', 'custom_canvas_enrollment_state', 'custom_fred', 'custom_john'])
      expect(hash['custom_bob']).to eql('bob')
      expect(hash['custom_fred']).to eql('fred')
      expect(hash['custom_john']).to eql('john')
      expect(hash['custom___taa____']).to eql(123)
      expect(hash).to_not have_key '@$TAA$#$#'
      expect(hash).to_not have_key 'john'
    end

    context "link_params" do
      let(:link_params) do
        {
          custom: {
            'custom_param' => 123
          },
          ext:{
            'ext_param' => 123,
          }
        }
      end

      let(:tool_launch) do
        LtiOutbound::ToolLaunch.new(
          url: 'http://www.yahoo.com',
          tool: tool,
          user: user,
          account: account,
          context: course,
          link_code: '123456',
          return_url: 'http://www.google.com',
          outgoing_email_address: 'outgoing_email_address',
          variable_expander: variable_expander,
          link_params: link_params
        )
      end

      it 'includes custom fields from link_params' do
        hash = tool_launch.generate
        expect(hash).to include({'custom_param' => 123})
      end

      it 'includes ext fields from link_params' do
        hash = tool_launch.generate
        expect(hash).to include({'ext_param' => 123})
      end

    end

    it 'does not include name and email if anonymous' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      hash = tool_launch.generate
      expect(hash).to_not have_key 'lis_person_name_given'
      expect(hash).to_not have_key 'lis_person_name_family'
      expect(hash).to_not have_key 'lis_person_name_full'
      expect(hash).to_not have_key 'lis_person_contact_email_primary'
    end

    it 'includes name if name_only' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
      hash = tool_launch.generate
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_contact_email_primary']).to be_nil
    end

    it 'includes email if email_only' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
      hash = tool_launch.generate
      expect(hash['lis_person_name_given']).to eq nil
      expect(hash['lis_person_name_family']).to eq nil
      expect(hash['lis_person_name_full']).to eq nil
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
    end

    it 'includes email if public' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      hash = tool_launch.generate
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
    end

    it 'includes role_scope_mentor if user is observer and privacy level is public' do
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      user.current_roles = [LtiOutbound::LTIRoles::ContextNotNamespaced::OBSERVER.split(',').last]
      user.current_observee_ids = ['1', '2', '3']
      hash = tool_launch.generate
      expect(hash['role_scope_mentor']).to eq '1,2,3'
    end

    it 'gets the correct width and height based on resource type' do
      tool.settings = {editor_button: {:selection_width => 1000, :selection_height => 300, :icon_url => 'www.example.com/icon', :url => 'www.example.com'}}
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => tool,
                                         :user => user,
                                         :account => account,
                                         :context => course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.yahoo.com',
                                         :resource_type => 'editor_button',
                                         :variable_expander => variable_expander).generate
      expect(hash['launch_presentation_width']).to eq 1000
      expect(hash['launch_presentation_height']).to eq 300
    end

    it 'does not copy query params to POST body if disable_lti_post_only feature flag is set' do
      tool.settings = {editor_button: {:selection_width => 1000, :selection_height => 300,
                       :icon_url => 'www.example.com/icon', :url => 'www.example.com'}}
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.instructure.com?first=weston&last=dransfield',
                                         :tool => tool,
                                         :user => user,
                                         :account => account,
                                         :context => course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.yahoo.com',
                                         :resource_type => 'editor_button',
                                         :variable_expander => variable_expander,
                                         :disable_lti_post_only => true).generate
      expect(hash.key?('first')).to eq false
    end
  end

  describe '#for_assignment!' do
    it 'includes assignment outcome service params for student' do
      student_role = LtiOutbound::LTIRoles::ContextNotNamespaced::LEARNER
      user.current_roles = [student_role]
      tool_launch.for_assignment!(assignment, '/my/test/url', '/my/other/test/url', '/my/favorite/url')

      hash = tool_launch.generate

      expect(hash['lis_result_sourcedid']).to eq '123456'
      expect(hash['lis_outcome_service_url']).to eq '/my/test/url'
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq '/my/other/test/url'
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq '$Canvas.assignment.title'
      expect(hash['custom_canvas_assignment_points_possible']).to eq '$Canvas.assignment.pointsPossible'
      expect(hash['custom_canvas_assignment_id']).to eq '$Canvas.assignment.id'
    end

    it 'includes assignment outcome service params for teacher' do
      tool_launch.for_assignment!(assignment, '/my/test/url', '/my/other/test/url', '/a/test/url')

      hash = tool_launch.generate

      expect(hash['lis_result_sourcedid']).to be_nil
      expect(hash['lis_outcome_service_url']).to eq '/my/test/url'
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq '/my/other/test/url'
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq '$Canvas.assignment.title'
      expect(hash['custom_canvas_assignment_points_possible']).to eq '$Canvas.assignment.pointsPossible'
    end
  end

  describe '#for_homework_submission!' do
    it 'includes content keys if present' do
      tool_launch.for_homework_submission!(assignment)

      hash = tool_launch.generate

      expect(hash['ext_content_return_types']).to eq 'url,text'
      expect(hash['ext_content_file_extensions']).to eq 'jpg,pdf'
      expect(hash['custom_canvas_assignment_id']).to eq '$Canvas.assignment.id'
    end

    it 'excludes file_extensions if not present' do
      assignment.allowed_extensions = nil
      tool_launch.for_homework_submission!(assignment)

      hash = tool_launch.generate

      expect(hash['ext_content_file_extensions']).to eq nil
    end
  end

end
