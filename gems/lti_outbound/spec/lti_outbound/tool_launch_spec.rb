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
  before do
    @consumer_instance = LtiOutbound::LTIConsumerInstance.new.tap do |consumer_instance|
      consumer_instance.id = 'root_account_id'
      consumer_instance.sis_source_id = 'root_account_sis_source_id'
      consumer_instance.domain = 'root_account_domain'
      consumer_instance.lti_guid = 'root_account_lti_guid'
      consumer_instance.name = 'root_account_name'
    end
    @account = LtiOutbound::LTIAccount.new.tap do |account|
      account.name = 'account_name'
      account.id = 'account_id'
      account.sis_source_id = 'account_sis_source_id'
      account.consumer_instance = @consumer_instance
    end
    @course = LtiOutbound::LTICourse.new.tap do |course|
      course.consumer_instance = @consumer_instance
      course.opaque_identifier = 'course_opaque_identifier'
      course.name = 'course_name'
      course.id = 'course_id'
      course.course_code = 'course_code'
      course.sis_source_id = 'course_sis_source_id'
    end
    @tool = LtiOutbound::LTITool.new.tap do |tool|
      tool.name = 'tool_name'
      tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
    end
    teacher_role = LtiOutbound::LTIRole::INSTRUCTOR
    @user = LtiOutbound::LTIUser.new.tap do |user|
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
      user.consumer_instance = @consumer_instance
    end
    @assignment = LtiOutbound::LTIAssignment.new.tap do |assignment|
      assignment.id = 'assignment_id'
      assignment.source_id = '123456'
      assignment.title = 'assignment1'
      assignment.points_possible = 100
      assignment.return_types = ['url', 'text']
      assignment.allowed_extensions = ['jpg', 'pdf']
    end
    @tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                               :tool => @tool,
                                               :user => @user,
                                               :account => @account,
                                               :context => @course,
                                               :link_code => '123456',
                                               :return_url => 'http://www.google.com',
                                               :outgoing_email_address => 'outgoing_email_address')
  end

  describe '#generate' do
    it 'generates correct parameters' do
      hash = @tool_launch.generate

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
      expect(hash['custom_canvas_user_id']).to eq 'user_id'
      expect(hash['custom_canvas_user_login_id']).to eq 'user_login_id'
      expect(hash['custom_canvas_course_id']).to eq 'course_id'
      expect(hash['custom_canvas_api_domain']).to eq 'root_account_domain'
      expect(hash['lis_course_offering_sourcedid']).to eq 'course_sis_source_id'
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_sourcedid']).to eq 'sis_user_id'
      expect(hash['launch_presentation_locale']).to eq 'en' #was I18n.default_locale.to_s
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
      hash = @tool_launch.generate('resource_link_title' => 'new tool name')
      expect(hash['resource_link_title']).to eq 'new tool name'
    end

    describe 'selected_html' do
      it 'gets escaped and assigned to the key text if passed in' do
        tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                                  :tool => @tool,
                                                  :user => @user,
                                                  :account => @account,
                                                  :context => @course,
                                                  :link_code => '123456',
                                                  :return_url => 'http://www.google.com',
                                                  :selected_html => '<div>something</div>')

        hash = tool_launch.generate

        expect(hash['text']).to eq '%3Cdiv%3Esomething%3C%2Fdiv%3E'
      end

      it 'does not include the key if missing' do
        tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                                  :tool => @tool,
                                                  :user => @user,
                                                  :account => @account,
                                                  :context => @course,
                                                  :link_code => '123456',
                                                  :return_url => 'http://www.google.com')

        hash = tool_launch.generate

        expect(hash.keys).to_not include('text')

      end
    end

    it 'sets the locale if I18n.localizer exists' do
      I18n.localizer = lambda { :es }
      hash = @tool_launch.generate

      expect(hash['launch_presentation_locale']).to eq 'es'
      I18n.localizer = lambda { :en }
    end

    it 'adds account info in launch data for account navigation' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => @tool,
                                         :user => @user,
                                         :account => @account,
                                         :context => @account,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com').generate
      expect(hash['custom_canvas_account_id']).to eq 'account_id'
      expect(hash['custom_canvas_account_sis_id']).to eq 'account_sis_source_id'
      expect(hash['custom_canvas_user_login_id']).to eq 'user_login_id'
    end

    it 'adds account and user info in launch data for user profile launch' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => @tool,
                                         :user => @user,
                                         :account => @consumer_instance,
                                         :context => @user,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com').generate
      expect(hash['custom_canvas_account_id']).to eq 'root_account_id'
      expect(hash['custom_canvas_account_sis_id']).to eq 'root_account_sis_source_id'
      expect(hash['lis_person_sourcedid']).to eq 'sis_user_id'
      expect(hash['custom_canvas_user_id']).to eq 'user_id'
      expect(hash['tool_consumer_instance_guid']).to eq 'root_account_lti_guid' #was hash['tool_consumer_instance_guid']).to eq sub_account.root_account.lti_guid
    end

    it 'includes URI query parameters' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com?paramater_a=value_a&parameter_b=value_b',
                                         :tool => @tool,
                                         :user => @user,
                                         :account => @account,
                                         :context => @course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com').generate
      expect(hash['paramater_a']).to eq 'value_a'
      expect(hash['parameter_b']).to eq 'value_b'
    end

    it 'does not allow overwriting other parameters from the URI query string' do
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com?user_id=ATTEMPT_TO_SET_DATA&oauth_callback=ATTEMPT_TO_SET_DATA',
                                         :tool => @tool,
                                         :user => @user,
                                         :account => @account,
                                         :context => @course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.google.com').generate
      expect(hash['user_id']).to eq 'user_opaque_identifier'
      expect(hash['oauth_callback']).to eq 'about:blank'
    end

    it 'includes custom fields' do
      @tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      @tool.settings = {:custom_fields => {
          'custom_bob' => 'bob',
          'custom_fred' => 'fred',
          'john' => 'john',
          '@$TAA$#$#' => 123}}
      hash = @tool_launch.generate
      expect(hash.keys.select { |k| k.match(/^custom_/) }.sort).to eq(
                                                                       ['custom___taa____', 'custom_bob', 'custom_canvas_enrollment_state', 'custom_fred', 'custom_john'])
      expect(hash['custom_bob']).to eql('bob')
      expect(hash['custom_fred']).to eql('fred')
      expect(hash['custom_john']).to eql('john')
      expect(hash['custom___taa____']).to eql('123')
      expect(hash).to_not have_key '@$TAA$#$#'
      expect(hash).to_not have_key 'john'
    end

    it 'does not include name and email if anonymous' do
      @tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_ANONYMOUS
      hash = @tool_launch.generate
      expect(hash).to_not have_key 'lis_person_name_given'
      expect(hash).to_not have_key 'lis_person_name_family'
      expect(hash).to_not have_key 'lis_person_name_full'
      expect(hash).to_not have_key 'lis_person_contact_email_primary'
    end

    it 'includes name if name_only' do
      @tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_NAME_ONLY
      hash = @tool_launch.generate
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_contact_email_primary']).to be_nil
    end

    it 'includes email if email_only' do
      @tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_EMAIL_ONLY
      hash = @tool_launch.generate
      expect(hash['lis_person_name_given']).to eq nil
      expect(hash['lis_person_name_family']).to eq nil
      expect(hash['lis_person_name_full']).to eq nil
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
    end

    it 'includes email if public' do
      @tool.privacy_level = LtiOutbound::LTITool::PRIVACY_LEVEL_PUBLIC
      hash = @tool_launch.generate
      expect(hash['lis_person_name_given']).to eq 'first_name'
      expect(hash['lis_person_name_family']).to eq 'last_name'
      expect(hash['lis_person_name_full']).to eq 'user_name'
      expect(hash['lis_person_contact_email_primary']).to eq 'nobody@example.com'
    end

    it 'gets the correct width and height based on resource type' do
      @tool.settings = {editor_button: {:selection_width => 1000, :selection_height => 300, :icon_url => 'www.example.com/icon', :url => 'www.example.com'}}
      hash = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                         :tool => @tool,
                                         :user => @user,
                                         :account => @account,
                                         :context => @course,
                                         :link_code => '123456',
                                         :return_url => 'http://www.yahoo.com',
                                         :resource_type => 'editor_button').generate
      expect(hash['launch_presentation_width']).to eq '1000'
      expect(hash['launch_presentation_height']).to eq '300'
    end

    describe 'variable substitutions' do
      before do
        @substitutor = double('Substitutor', substitute!: 'something')
        LtiOutbound::VariableSubstitutor.stub(:new).and_return(@substitutor)
      end

      it 'substitutes for a course context' do
        @tool_launch.generate

        expect(@substitutor).to have_received(:substitute!)
      end

      it 'substitutes with an assignment' do
        @tool_launch.for_homework_submission!(@assignment)
        @tool_launch.generate

        expect(@substitutor).to have_received(:substitute!)
      end

      it 'substitutes account if context is account' do
        tool_launch = LtiOutbound::ToolLaunch.new(:url => 'http://www.yahoo.com',
                                                  :tool => @tool,
                                                  :user => @user,
                                                  :account => @account,
                                                  :context => @account,
                                                  :link_code => '123456',
                                                  :return_url => 'http://www.google.com',
                                                  :outgoing_email_address => 'outgoing_email_address')
        tool_launch.generate

        expect(@substitutor).to have_received(:substitute!)
      end
    end
  end

  describe '#for_assignment!' do
    it 'includes assignment outcome service params for student' do
      student_role = LtiOutbound::LTIRole::LEARNER
      @user.current_roles = [student_role]
      @tool_launch.for_assignment!(@assignment, '/my/test/url', '/my/other/test/url')

      hash = @tool_launch.generate

      expect(hash['lis_result_sourcedid']).to eq '123456'
      expect(hash['lis_outcome_service_url']).to eq '/my/test/url'
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq '/my/other/test/url'
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq 'assignment1'
      expect(hash['custom_canvas_assignment_points_possible']).to eq '100'
      expect(hash['custom_canvas_assignment_id']).to eq 'assignment_id'
    end

    it 'includes assignment outcome service params for teacher' do
      @tool_launch.for_assignment!(@assignment, '/my/test/url', '/my/other/test/url')

      hash = @tool_launch.generate

      expect(hash['lis_result_sourcedid']).to be_nil
      expect(hash['lis_outcome_service_url']).to eq '/my/test/url'
      expect(hash['ext_ims_lis_basic_outcome_url']).to eq '/my/other/test/url'
      expect(hash['ext_outcome_data_values_accepted']).to eq 'url,text'
      expect(hash['custom_canvas_assignment_title']).to eq 'assignment1'
      expect(hash['custom_canvas_assignment_points_possible']).to eq '100'
    end
  end

  describe '#for_homework_submission!' do
    it 'includes content keys if present' do
      @tool_launch.for_homework_submission!(@assignment)

      hash = @tool_launch.generate

      expect(hash['ext_content_return_types']).to eq 'url,text'
      expect(hash['ext_content_file_extensions']).to eq 'jpg,pdf'
      expect(hash['custom_canvas_assignment_id']).to eq 'assignment_id'
    end

    it 'excludes file_extensions if not present' do
      @assignment.allowed_extensions = nil
      @tool_launch.for_homework_submission!(@assignment)

      hash = @tool_launch.generate

      expect(hash['ext_content_file_extensions']).to eq nil
    end
  end

  #TODO: do not test private methods
  describe '.generate_params' do
    def explicit_signature_settings(timestamp, nonce)
      LtiOutbound::ToolLaunch.instance_variable_set(:'@timestamp', timestamp)
      LtiOutbound::ToolLaunch.instance_variable_set(:'@nonce', nonce)
    end

    it 'generate a correct signature' do
      explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
          :resource_link_id => '120988f929-274612',
          :user_id => '292832126',
          :roles => 'Instructor',
          :lis_person_name_full => 'Jane Q. Public',
          :lis_person_contact_email_primary => 'user@school.edu',
          :lis_person_sourced_id => 'school.edu:user',
          :context_id => '456434513',
          :context_title => 'Design of Personal Environments',
          :context_label => 'SI182',
          :lti_version => 'LTI-1p0',
          :lti_message_type => 'basic-lti-launch-request',
          :tool_consumer_instance_guid => 'lmsng.school.edu',
          :tool_consumer_instance_description => 'University of School (LMSng)',
          :lti_submit => 'Launch Endpoint with LTI Data'
      }, 'http://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')

      expect(hash['oauth_signature']).to eql('l1ZTsn1HjGXzqeaTQMPbjrqvjLU=')
    end

    it 'generate a correct signature with URL query parameters' do
      explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')
      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
          :resource_link_id => '120988f929-274612',
          :user_id => '292832126',
          :roles => 'Instructor',
          :lis_person_name_full => 'Jane Q. Public',
          :lis_person_contact_email_primary => 'user@school.edu',
          :lis_person_sourced_id => 'school.edu:user',
          :context_id => '456434513',
          :context_title => 'Design of Personal Environments',
          :context_label => 'SI182',
          :lti_version => 'LTI-1p0',
          :lti_message_type => 'basic-lti-launch-request',
          :tool_consumer_instance_guid => 'lmsng.school.edu',
          :tool_consumer_instance_description => 'University of School (LMSng)',
          :lti_submit => 'Launch Endpoint with LTI Data'
      }, 'http://dr-chuck.com/ims/php-simple/tool.php?a=1&b=2&c=3%20%26a', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('k/+aMdax1Jm5kuGF6DG/ptN5VfY=')
      expect(hash['c']).to eq '3 &a'
    end

    it 'generate a correct signature with a non-standard port' do
      #signatures generated using http://oauth.googlecode.com/svn/code/javascript/example/signature.html
      explicit_signature_settings('1251600739', 'c8350c0e47782d16d2fa48b2090c1d8f')
      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'http://dr-chuck.com:123/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('ghEdPHwN4iJmsM3Nr4AndDx2Kx8=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'http://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('WoSpvCr2HEsLzao6Do0eukxwAsk=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'http://dr-chuck.com:80/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('WoSpvCr2HEsLzao6Do0eukxwAsk=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'http://dr-chuck.com:443/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('KqAV7eIS/+iWIDpvCyDfY8ZpmT4=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'https://dr-chuck.com/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('wFRB/1ZXi/91dop6GwahfboWPvQ=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'https://dr-chuck.com:443/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('wFRB/1ZXi/91dop6GwahfboWPvQ=')

      hash = LtiOutbound::ToolLaunch.send(:generate_params, {
      }, 'https://dr-chuck.com:80/ims/php-simple/tool.php', '12345', 'secret')
      expect(hash['oauth_signature']).to eql('X8Aq2HXSHnr6u/6z/G9zI5aDoR0=')
    end
  end
end