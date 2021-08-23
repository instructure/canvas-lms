# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../../lti_1_3_spec_helper')

describe Lti::Messages::JwtMessage do
  include_context 'lti_1_3_spec_helper'

  let(:return_url) { 'http://www.platform.com/return_url' }
  let(:user) { @student }
  let(:opts) { { resource_type: 'course_navigation' } }
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      nil,
      {
        current_user: user,
        tool: tool
      }
    )
  end
  let(:decoded_jwt) do
    jws = Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)
    JSON::JWT.decode(jws[:id_token], pub_key)
  end
  let(:pub_key) do
    Lti::KeyStorage.present_key.to_key.public_key
  end
  let_once(:course) do
    course_with_student
    @course
  end
  let_once(:assignment) { assignment_model(course: course) }
  let_once(:tool) do
    tool = course.context_external_tools.new(
      name: 'bob',
      consumer_key: 'key',
      shared_secret: 'secret',
      url: 'http://www.example.com/basic_lti',
      developer_key: developer_key
    )
    tool.course_navigation = {
      enabled: true,
      message_type: 'ResourceLinkRequest',
      selection_width: '500',
      selection_height: '400',
      custom_fields: {
        has_expansion: '$User.id',
        no_expansion: 'foo'
      }
    }
    tool.use_1_3 = true
    tool.save!
    tool
  end
  let_once(:developer_key) { DeveloperKey.create! }

  def jwt_message
    Lti::Messages::JwtMessage.new(
      tool: tool,
      context: course,
      user: user,
      expander: expander,
      return_url: return_url,
      opts: opts
    )
  end

  describe 'signing' do
    it 'signs the id token with the current canvas private key' do
      jws = Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)

      expect do
        JSON::JWT.decode(jws[:id_token], pub_key)
      end.not_to raise_exception
    end
  end

  describe 'security claims' do
    it 'sets the "aud" claim' do
      expect(decoded_jwt['aud']).to eq developer_key.global_id.to_s
    end

    it 'sets the "deployment_id" claim' do
      expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/deployment_id']).to eq "#{tool.id}:#{Lti::Asset.opaque_identifier_for(tool.context)}"
    end

    it 'sets the "exp" claim to lti.oauth2.access_token.exp' do
      Timecop.freeze do
        expect(decoded_jwt['exp']).to eq Setting.get('lti.oauth2.access_token.exp', 1.hour).to_i.seconds.from_now.to_i
      end
    end

    it 'sets the "iat" claim to the current time' do
      Timecop.freeze do
        expect(decoded_jwt['iat']).to eq Time.zone.now.to_i
      end
    end

    it 'sets the "iss" to "https://canvas.instructure.com"' do
      config = "test:\n  lti_iss: 'https://canvas.instructure.com'"
      allow(CanvasSecurity).to receive(:config).and_return(YAML.safe_load(config)[Rails.env])
      expect(decoded_jwt['iss']).to eq 'https://canvas.instructure.com'
    end

    it 'sets the "nonce" claim to a unique ID' do
      first_nonce = decoded_jwt['nonce']
      jws = Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)
      second_nonce = JSON::JWT.decode(jws[:id_token], pub_key)['nonce']

      expect(first_nonce).not_to eq second_nonce
    end

    context 'when user is an authorized user' do
      it 'sets the "sub" claim' do
        expect(decoded_jwt['sub']).to eq user.lti_id
      end
    end

    context 'when user is an unauthorized user' do
      let(:user) { nil }

      it 'does not sets the "sub" claim' do
        expect(decoded_jwt['sub']).to be_nil
      end
    end

    it 'sets the "sub" claim to past lti_id' do
      UserPastLtiId.create!(user: user, context: course, user_lti_id: 'old_lti_id', user_lti_context_id: 'old_lti_id', user_uuid: 'old')
      expect(decoded_jwt['sub']).to eq 'old_lti_id'
    end

    it 'sets the "target_link_uri" claim' do
      expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/target_link_uri']).to eq tool.url
    end

    context 'when the target_link_uri is specified in opts' do
      let(:target_link_uri) { 'https://www.cool-tool.com/test?foo=bar' }
      let(:opts) { { resource_type: 'course_navigation', target_link_uri: target_link_uri } }

      it 'sets the "target_link_uri" claim' do
        expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/target_link_uri']).to eq target_link_uri
      end
    end

    context 'when security claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:security]}) }

      it 'does not set the "aud" claim' do
        expect(decoded_jwt).not_to include 'aud'
      end

      it 'does not set the "deployment_id" claim' do
        expect(decoded_jwt).not_to include 'https://purl.imsglobal.org/spec/lti/claim/deployment_id'
      end

      it 'does not set the "exp" claim' do
        expect(decoded_jwt).not_to include 'exp'
      end

      it 'does not set the "iat" claim' do
        expect(decoded_jwt).not_to include 'iat'
      end

      it 'does not set the "iss" claim' do
        expect(decoded_jwt).not_to include 'iss'
      end

      it 'does not set the "nonce" claim' do
        expect(decoded_jwt).not_to include 'nonce'
      end

      it 'does not set the "sub" claim' do
        expect(decoded_jwt).not_to include 'sub'
      end
    end
  end

  describe 'i18n claims' do
    it 'sets the locale' do
      expected_locale = 'ca'
      allow(I18n).to receive(:locale).and_return expected_locale
      expect(decoded_jwt['locale']).to eq expected_locale
    end

    context 'when i18n claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:i18n]}) }

      it 'does not set the "locale" claim' do
        expect(decoded_jwt).not_to include 'locale'
      end
    end
  end

  describe 'context claims' do
    let(:message_context) { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/context'] }

    it 'sets the id' do
      expect(message_context['id']).to eq course.lti_context_id
    end

    it 'sets the label' do
      expect(message_context['label']).to eq course.course_code
    end

    it 'sets the title' do
      expect(message_context['title']).to eq course.name
    end

    it 'sets the type' do
      expect(message_context['type']).to match_array [
        Lti::SubstitutionsHelper::LIS_V2_ROLE_MAP[Course]
      ]
    end

    context 'when context claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:context]}) }

      it 'does not set the context claim' do
        expect(message_context).to be_nil
      end
    end
  end

  describe 'platform' do
    let(:message_platform) { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/tool_platform'] }

    it 'sets the name' do
      expect(message_platform['name']).to eq course.root_account.name
    end

    it 'sets the version' do
      expect(message_platform['version']).to eq 'cloud'
    end

    it 'sets the product family code' do
      expect(message_platform['product_family_code']).to eq 'canvas'
    end

    it 'sets the guid' do
      expect(message_platform['guid']).to eq course.root_account.lti_guid
    end

    context 'when platform claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:tool_platform]}) }

      it 'does not set the platform claim' do
        expect(message_platform).to be_nil
      end
    end
  end

  describe 'launch presentation' do
    let(:message_launch_presentation) { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/launch_presentation'] }

    it 'sets the document target' do
      expect(message_launch_presentation['document_target']).to eq 'iframe'
    end

    it 'sets the height' do
      expect(message_launch_presentation['height']).to eq 400
    end

    it 'sets the width' do
      expect(message_launch_presentation['width']).to eq 500
    end

    it 'sets the return url' do
      expect(message_launch_presentation['return_url']).to eq return_url
    end

    it 'sets the locale' do
      expected_locale = 'ca'
      allow(I18n).to receive(:locale).and_return expected_locale
      expect(message_launch_presentation['locale']).to eq expected_locale
    end

    context 'when launch presentation claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:launch_presentation]}) }

      it 'does not set the launch presentation claim' do
        expect(message_launch_presentation).to be_nil
      end
    end
  end

  shared_context 'lti advantage service claims context' do
    let_once(:ags_scopes) do
      [
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem',
        'https://purl.imsglobal.org/spec/lti-ags/scope/lineitem.readonly',
        'https://purl.imsglobal.org/spec/lti-ags/scope/result.readonly',
        'https://purl.imsglobal.org/spec/lti-ags/scope/score'
      ]
    end
    let_once(:nrps_scopes) { ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'] }
    let(:lti_advantage_tool) do
      tool = course.context_external_tools.new(
        name: 'bob',
        consumer_key: 'key',
        shared_secret: 'secret',
        url: 'http://www.example.com/basic_lti',
        developer_key: lti_advantage_developer_key
      )
      tool.use_1_3 = true
      tool.save!
      tool
    end
    let(:lti_advantage_developer_key_scopes) { raise 'Set in example' }
    let(:lti_advantage_developer_key) do
      DeveloperKey.create!(
        name: 'Developer Key With Scopes',
        account: course.root_account,
        scopes: lti_advantage_developer_key_scopes,
        require_scopes: true
      )
    end
    let(:lti_context) { course }
    let(:jwt_message) do
      Lti::Messages::JwtMessage.new(
        tool: lti_advantage_tool,
        context: lti_context,
        user: user,
        expander: expander,
        return_url: return_url,
        opts: opts
      )
    end
    let(:controller) do
      controller = double('controller')
      allow(controller).to receive(:polymorphic_url).and_return('polymorphic_url')
      allow(controller).to receive(:request).and_return(request)
      controller
    end
    # All this setup just so we can stub out controller.polymorphic_url
    let(:request) do
      request = double('request')
      allow(request).to receive(:url).and_return('https://localhost')
      allow(request).to receive(:host).and_return('/my/url')
      allow(request).to receive(:scheme).and_return('https')
      request
    end
    # override b/c all the rest of the tests fail if a Controller is injected into the 'top-level' expander def
    let(:expander) do
      Lti::VariableExpander.new(
        course.root_account,
        lti_context,
        controller,
        {
          current_user: user,
          tool: lti_advantage_tool
        }
      )
    end
    let(:lti_advantage_service_claim) { raise 'Set in example' }

  end

  shared_context 'with lti advantage group context' do
    let_once(:group_record) { group(context: course) } # _record suffix to avoid conflict with group() factory mtd
    let(:lti_context) { group_record }
  end

  shared_context 'with lti advantage account context' do
    let(:lti_context) { course.root_account }
  end

  shared_examples 'absent lti advantage service claim check' do
    it 'does not set the lti advantage service claim' do
      expect(lti_advantage_service_claim).to be_nil
    end
  end

  shared_examples 'lti advantage service claim group disabled check' do
    let(:opts) { super().merge({claim_group_blacklist: [lti_advantage_service_claim_group]}) }

    it_behaves_like 'absent lti advantage service claim check'
  end

  shared_examples 'lti advantage scopes missing from developer key' do
    let(:lti_advantage_developer_key_scopes) { [ TokenScopes::USER_INFO_SCOPE[:scope] ] }

    it_behaves_like 'absent lti advantage service claim check'
  end

  describe 'names and roles' do
    include_context 'lti advantage service claims context'
    let(:lti_advantage_developer_key_scopes) { nrps_scopes }
    let(:lti_advantage_service_claim) { decoded_jwt['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice'] }
    let(:lti_advantage_service_claim_group) { :names_and_roles_service }

    shared_examples 'names and roles claim check' do
      it 'sets the NRPS url' do
        expect(lti_advantage_service_claim['context_memberships_url']).to eq 'polymorphic_url'
      end

      it 'sets the NRPS version' do
        expect(lti_advantage_service_claim['service_versions']).to eq ['2.0']
      end
    end

    context 'when context is a course' do
      it_behaves_like 'names and roles claim check'
      it_behaves_like 'lti advantage service claim group disabled check'
      it_behaves_like 'lti advantage scopes missing from developer key'
    end

    context 'when context is an account' do
      include_context 'with lti advantage account context'
      it_behaves_like 'absent lti advantage service claim check'
      it_behaves_like 'lti advantage service claim group disabled check'
      it_behaves_like 'lti advantage scopes missing from developer key'
    end

    context 'when context is a group' do
      include_context 'with lti advantage group context'
      it_behaves_like 'names and roles claim check'
      it_behaves_like 'lti advantage service claim group disabled check'
      it_behaves_like 'lti advantage scopes missing from developer key'
    end
  end

  describe 'custom parameters' do
    let(:message_custom) { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/custom'] }

    it 'adds custom parameters in the root settings' do
      tool.settings[:custom_fields] = { my_custom_field: 'banana' }
      tool.save!
      expect(message_custom['my_custom_field']).to eq 'banana'
    end

    it 'adds placement-specific custom parameters' do
      Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)
      expect(message_custom['no_expansion']).to eq 'foo'
    end

    it 'expands variable expansions' do
      Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)
      expect(message_custom['has_expansion']).to eq user.id
    end

    context 'when custom parameters claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:custom_params]}) }

      it 'does not set the custom parameters claim' do
        expect(message_custom).to be_nil
      end
    end
  end

  describe 'roles claims' do
    shared_examples 'sets roles claim' do
      it 'sets the roles' do
        expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/roles']).to match_array [
          "http://purl.imsglobal.org/vocab/lis/v2/membership#Learner",
          "http://purl.imsglobal.org/vocab/lis/v2/system/person#User"
        ]
      end
    end

    shared_examples 'skips roles claim' do
      it 'does not set the roles claim' do
        expect(decoded_jwt).not_to include 'https://purl.imsglobal.org/spec/lti/claim/roles'
      end
    end

    it_behaves_like 'sets roles claim'

    context 'when roles claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:roles]}) }

      it_behaves_like 'skips roles claim'
    end

    describe 'when Canvas roles extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:roles]}) }

      it_behaves_like 'sets roles claim'
    end

    describe 'when Canvas enrollment state extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_enrollment_state]}) }

      it_behaves_like 'sets roles claim'
    end

  end

  describe 'include name claims' do
    before do
      course
      tool.update!(workflow_state: 'name_only')
    end

    context 'when the user is nil' do
      let(:user) { nil }

      it 'does not add the name' do
        expect(decoded_jwt['name']).to be_blank
      end

      it 'does not add the given name' do
        expect(decoded_jwt['given_name']).to be_blank
      end

      it 'does not add the family name' do
        expect(decoded_jwt['family_name']).to be_blank
      end
    end

    it 'adds the name' do
      expect(decoded_jwt['name']).to eq user.name
    end

    it 'adds the given name' do
      expect(decoded_jwt['given_name']).to eq user.first_name
    end

    it 'adds the family name' do
      expect(decoded_jwt['family_name']).to eq user.last_name
    end

    it 'adds the person sourcedid' do
      expect(decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/lis', 'person_sourcedid')).to eq '$Person.sourcedId'
    end

    it 'adds the coures offering sourcedid' do
      course.update!(sis_source_id: SecureRandom.uuid)
      expect(decoded_jwt.dig('https://purl.imsglobal.org/spec/lti/claim/lis', 'course_offering_sourcedid')).to eq course.sis_source_id
    end

    shared_examples 'does not set name claim group' do
      it 'does not set the name claim' do
        expect(decoded_jwt).not_to include 'name'
      end

      it 'does not set the given name claim' do
        expect(decoded_jwt).not_to include 'given_name'
      end

      it 'does not set the family name claim' do
        expect(decoded_jwt).not_to include 'family_name'
      end

      it 'does not set the lis claim' do
        expect(decoded_jwt).not_to include 'https://purl.imsglobal.org/spec/lti/claim/lis'
      end
    end

    context 'when name claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:name]}) }

      it_behaves_like 'does not set name claim group'
    end

    context 'when tool privacy policy does not allow name release' do
      before { tool.update!(workflow_state: 'anonymous') }

      it_behaves_like 'does not set name claim group'
    end
  end

  describe 'include email claims' do
    before { tool.update!(workflow_state: 'email_only') }

    it 'adds the user email' do
      course
      expect(decoded_jwt['email']).to eq user.email
    end

    shared_examples 'does not set email claims' do
      it 'does not set the email claim' do
        expect(decoded_jwt).not_to include 'email'
      end
    end

    context 'when email claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:email]}) }

      it_behaves_like 'does not set email claims'
    end

    context 'when tool privacy policy does not allow email release' do
      before { tool.update!(workflow_state: 'anonymous') }

      it_behaves_like 'does not set email claims'
    end
  end

  describe 'public claims' do
    before { tool.update!(workflow_state: 'public') }

    shared_examples 'sets picture' do
      it 'adds the user picture' do
        course
        expect(decoded_jwt['picture']).to eq user.avatar_url
      end
    end

    shared_examples 'skips picture' do
      it 'does not add the user picture' do
        expect(decoded_jwt).not_to include 'picture'
      end
    end

    shared_context 'when context is an account' do
      let(:account_jwt_message) do
        Lti::Messages::JwtMessage.new(
          tool: tool,
          context: course.root_account,
          user: user,
          expander: expander,
          return_url: return_url,
          opts: opts
        )
      end

      let(:account_jwt) do
        jws = Lti::Messages::JwtMessage.generate_id_token(account_jwt_message.generate_post_payload)
        JSON::JWT.decode(jws[:id_token], pub_key)
      end
    end

    it_behaves_like 'sets picture'

    shared_examples 'does not set public claims group' do
      it_behaves_like 'skips picture'
    end

    context 'when public claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:public]}) }

      it_behaves_like 'does not set public claims group'
    end

    context 'when tool privacy policy does not allow public claim release' do
      before { tool.update!(workflow_state: 'name_only') }

      it_behaves_like 'does not set public claims group'
    end

    context 'when canvas course id extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_course_id]}) }

      it_behaves_like 'sets picture'
    end

    context 'when canvas workflow state extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_workflow_state]}) }

      it_behaves_like 'sets picture'
    end

    context 'when course section sourcedId extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:lis_course_offering_sourcedid]}) }

      it_behaves_like 'sets picture'
    end

    context 'when canvas account id extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_account_id]}) }

      it_behaves_like 'sets picture'
    end

    context 'when canvas account sis id extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_account_sis_id]}) }

      it_behaves_like 'sets picture'
    end
  end

  describe 'mentorship claims' do
    before { tool.update!(workflow_state: 'public') }

    shared_examples 'sets role scope mentor' do
      let(:student) { user_factory }

      before do
        course.enroll_student(student)
        enrollment = course.enroll_user(user, "ObserverEnrollment", associated_user_id: student)
        enrollment.update!(workflow_state: 'active')
        course.update!(workflow_state: 'available')
      end

      it 'adds role scope mentor' do
        expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/role_scope_mentor']).to match_array [
          student.lti_id
        ]
      end
    end

    shared_examples 'skips role scope mentor' do
      it 'does not add role scope mentor' do
        expect(decoded_jwt).not_to include 'https://purl.imsglobal.org/spec/lti/claim/role_scope_mentor'
      end
    end

    it_behaves_like 'sets role scope mentor'

    context 'when mentorship claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:mentorship]}) }

      it_behaves_like 'skips role scope mentor'
    end

    context 'when tool privacy policy does not allow mentorship claim release' do
      before { tool.update!(workflow_state: 'name_only') }

      it_behaves_like 'skips role scope mentor'
    end
  end

  describe 'legacy user id claims' do
    subject { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id'] }

    it { is_expected.to eq tool.opaque_identifier_for(user) }

    context 'when the user is blank' do
      let(:user) { nil }

      it { is_expected.to be_empty }
    end
  end

  describe 'lti1p1 claims' do
    context 'when user does not have lti_context_id' do
      before do
        allow(user).to receive(:lti_context_id).and_return(nil)
      end

      it 'does not include the claim' do
        expect(decoded_jwt).to_not include 'https://purl.imsglobal.org/spec/lti/claim/lti1p1'
      end
    end

    context 'when user has lti_context_id' do
      let(:message_lti1p1) { decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/lti1p1'] }

      it 'adds user_id' do
        expect(message_lti1p1['user_id']).to eq user.lti_context_id
      end
    end
  end
end
