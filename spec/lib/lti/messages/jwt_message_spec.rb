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
    jwk = JSON::JWK.new(Lti::KeyStorage.retrieve_keys['jwk-present.json'])
    jwk.to_key.public_key
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
      allow(Canvas::Security).to receive(:config).and_return(YAML.safe_load(config)[Rails.env])
      expect(decoded_jwt['iss']).to eq 'https://canvas.instructure.com'
    end

    it 'sets the "nonce" claim to a unique ID' do
      first_nonce = decoded_jwt['nonce']
      jws = Lti::Messages::JwtMessage.generate_id_token(jwt_message.generate_post_payload)
      second_nonce = JSON::JWT.decode(jws[:id_token], pub_key)['nonce']

      expect(first_nonce).not_to eq second_nonce
    end

    it 'sets the "sub" claim' do
      expect(decoded_jwt['sub']).to eq user.lti_context_id
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

    before(:each) do
      course.root_account.enable_feature!(:lti_1_3)
      course.root_account.save!
    end
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
          'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
        ]
      end
    end

    shared_examples 'skips roles claim' do
      it 'does not set the roles claim' do
        expect(decoded_jwt).not_to include 'https://purl.imsglobal.org/spec/lti/claim/roles'
      end
    end

    shared_examples 'sets Canvas roles extension' do
      it 'adds the Canvas roles extension' do
        expect(decoded_jwt['https://www.instructure.com/roles']).to eq 'urn:lti:role:ims/lis/Learner,urn:lti:sysrole:ims/lis/User'
      end
    end

    shared_examples 'skips Canvas roles extension' do
      it 'does not set the Canvas roles extension' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/roles'
      end
    end

    shared_examples 'sets Canvas enrollment state extension' do
      it 'adds the Canvas enrollment state extension' do
        expect(decoded_jwt['https://www.instructure.com/canvas_enrollment_state']).to eq 'inactive'
      end
    end

    shared_examples 'skips Canvas enrollment state extension' do
      it 'does not set the Canvas enrollment state extension' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/canvas_enrollment_state'
      end
    end

    it_behaves_like 'sets roles claim'
    it_behaves_like 'sets Canvas roles extension'
    it_behaves_like 'sets Canvas enrollment state extension'

    context 'when roles claim group disabled' do
      let(:opts) { super().merge({claim_group_blacklist: [:roles]}) }

      it_behaves_like 'skips roles claim'
      it_behaves_like 'skips Canvas roles extension'
      it_behaves_like 'skips Canvas enrollment state extension'
    end

    describe 'when Canvas roles extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:roles]}) }

      it_behaves_like 'sets roles claim'
      it_behaves_like 'skips Canvas roles extension'
      it_behaves_like 'sets Canvas enrollment state extension'
    end

    describe 'when Canvas enrollment state extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_enrollment_state]}) }

      it_behaves_like 'sets roles claim'
      it_behaves_like 'sets Canvas roles extension'
      it_behaves_like 'skips Canvas enrollment state extension'
    end

  end

  describe 'include name claims' do

    before do
      course
      tool.update!(workflow_state: 'name_only')
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

    shared_examples 'sets canvas course id extension' do
      it 'adds the canvas course id extension' do
        expect(decoded_jwt['https://www.instructure.com/canvas_course_id']).to eq course.id
      end
    end

    shared_examples 'skips canvas course id extension' do
      it 'does not add the canvas course id extension' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/canvas_course_id'
      end
    end

    shared_examples 'sets canvas workflow state extension' do
      it 'adds the canvas workflow state' do
        expect(decoded_jwt['https://www.instructure.com/canvas_workflow_state']).to eq 'created'
      end
    end

    shared_examples 'skips canvas workflow state extension' do
      it 'does not add the canvas workflow state' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/canvas_workflow_state'
      end
    end

    shared_examples 'sets course section sourcedId extension' do
      it 'adds the course section sourcedId' do
        course.update!(sis_source_id: SecureRandom.uuid)
        expect(decoded_jwt['https://www.instructure.com/lis_course_offering_sourcedid']).to eq course.sis_source_id
      end
    end

    shared_examples 'skips course section sourcedId extension' do
      it 'does not add the course section sourcedId' do
        course.update!(sis_source_id: SecureRandom.uuid)
        expect(decoded_jwt).not_to include 'https://www.instructure.com/lis_course_offering_sourcedid'
      end
    end

    shared_examples 'sets the canvas account id extension' do
      it 'adds the canvas account id' do
        expect(account_jwt['https://www.instructure.com/canvas_account_id']).to eq course.root_account.id
      end
    end

    shared_examples 'skips the canvas account id extension' do
      it 'does not add the canvas account id' do
        expect(account_jwt).not_to include 'https://www.instructure.com/canvas_account_id'
      end
    end

    shared_examples 'sets the canvas account sis id' do
      it 'adds the canvas account sis id' do
        expect(account_jwt['https://www.instructure.com/canvas_account_sis_id']).to eq course.root_account.sis_source_id
      end
    end

    shared_examples 'skips the canvas account sis id' do
      it 'does not add the canvas account sis id' do
        expect(account_jwt).not_to include 'https://www.instructure.com/canvas_account_sis_id'
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

    context 'extensions' do
      context 'when context is a course' do
        it_behaves_like 'sets canvas course id extension'
        it_behaves_like 'sets canvas workflow state extension'
        it_behaves_like 'sets course section sourcedId extension'
      end

      it_behaves_like 'when context is an account' do
        it_behaves_like 'sets the canvas account id extension'
        it_behaves_like 'sets the canvas account sis id'
      end
    end

    shared_examples 'does not set public claims group' do
      it_behaves_like 'skips picture'

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'skips canvas course id extension'
          it_behaves_like 'skips canvas workflow state extension'
          it_behaves_like 'skips course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'skips the canvas account id extension'
          it_behaves_like 'skips the canvas account sis id'
        end
      end
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

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'skips canvas course id extension'
          it_behaves_like 'sets canvas workflow state extension'
          it_behaves_like 'sets course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'sets the canvas account id extension'
          it_behaves_like 'sets the canvas account sis id'
        end
      end
    end

    context 'when canvas workflow state extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_workflow_state]}) }

      it_behaves_like 'sets picture'

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'sets canvas course id extension'
          it_behaves_like 'skips canvas workflow state extension'
          it_behaves_like 'sets course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'sets the canvas account id extension'
          it_behaves_like 'sets the canvas account sis id'
        end
      end
    end

    context 'when course section sourcedId extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:lis_course_offering_sourcedid]}) }

      it_behaves_like 'sets picture'

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'sets canvas course id extension'
          it_behaves_like 'sets canvas workflow state extension'
          it_behaves_like 'skips course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'sets the canvas account id extension'
          it_behaves_like 'sets the canvas account sis id'
        end
      end
    end

    context 'when canvas account id extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_account_id]}) }

      it_behaves_like 'sets picture'

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'sets canvas course id extension'
          it_behaves_like 'sets canvas workflow state extension'
          it_behaves_like 'sets course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'skips the canvas account id extension'
          it_behaves_like 'sets the canvas account sis id'
        end
      end
    end

    context 'when canvas account sis id extension disabled' do
      let(:opts) { super().merge({extension_blacklist: [:canvas_account_sis_id]}) }

      it_behaves_like 'sets picture'

      context 'extensions' do
        context 'when context is a course' do
          it_behaves_like 'sets canvas course id extension'
          it_behaves_like 'sets canvas workflow state extension'
          it_behaves_like 'sets course section sourcedId extension'
        end

        it_behaves_like 'when context is an account' do
          it_behaves_like 'sets the canvas account id extension'
          it_behaves_like 'skips the canvas account sis id'
        end
      end
    end
  end

  describe 'mentorship claims' do
    before { tool.update!(workflow_state: 'public') }

    shared_examples 'sets role scope mentor' do
      it 'adds role scope mentor' do
        course
        observer = user_factory
        observer.update!(lti_context_id: SecureRandom.uuid)
        observer_enrollment = course.enroll_user(observer, 'ObserverEnrollment')
        observer_enrollment.update_attribute(:associated_user_id, user.id)
        allow_any_instance_of(Lti::Messages::JwtMessage).to receive(:current_observee_list).and_return([observer.lti_context_id])

        expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/role_scope_mentor']).to match_array [
          observer.lti_context_id
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

  describe 'resource claims' do
    shared_examples 'sets selection directive extension' do |directive|
      it 'adds selection directive' do
        expect(decoded_jwt['https://www.instructure.com/selection_directive']).to eq directive
      end
    end

    shared_examples 'skips selection directive extension' do
      it 'does not add selection directive' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/selection_directive'
      end
    end

    shared_examples 'sets content intended use extension' do |use|
      it 'adds content intended use' do
        expect(decoded_jwt['https://www.instructure.com/content_intended_use']).to eq use
      end
    end

    shared_examples 'skips content intended use extension' do
      it 'does not add content intended use' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/content_intended_use'
      end
    end

    shared_examples 'sets content return types extension' do |types|
      it 'adds content return types' do
        expect(decoded_jwt['https://www.instructure.com/content_return_types']).to eq types
      end
    end

    shared_examples 'skips content return types extension' do
      it 'does not add content return types' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/content_return_types'
      end
    end

    shared_examples 'sets content return url extension' do
      it 'adds content return url' do
        expect(decoded_jwt['https://www.instructure.com/content_return_url']).to eq return_url
      end
    end

    shared_examples 'skips content return url extension' do
      it 'does not add content return url' do
        expect(decoded_jwt).not_to include 'https://www.instructure.com/content_return_url'
      end
    end

    shared_examples 'resource group 1 check' do |directive, use, types|
      it_behaves_like 'sets selection directive extension', directive
      it_behaves_like 'sets content intended use extension', use
      it_behaves_like 'sets content return types extension', types
      it_behaves_like 'sets content return url extension'

      context 'when resource claim group disabled' do
        let(:opts) { super().merge({claim_group_blacklist: [:resource]}) }

        it_behaves_like 'skips selection directive extension'
        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'skips content return types extension'
        it_behaves_like 'skips content return url extension'
      end

      context 'when selection directive extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:selection_directive]}) }

        it_behaves_like 'skips selection directive extension'
        it_behaves_like 'sets content intended use extension', use
        it_behaves_like 'sets content return types extension', types
        it_behaves_like 'sets content return url extension'
      end

      context 'when content intended use extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_intended_use]}) }

        it_behaves_like 'sets selection directive extension', directive
        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'sets content return types extension', types
        it_behaves_like 'sets content return url extension'
      end

      context 'when content return types extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_return_types]}) }

        it_behaves_like 'sets selection directive extension', directive
        it_behaves_like 'sets content intended use extension', use
        it_behaves_like 'skips content return types extension'
        it_behaves_like 'sets content return url extension'
      end

      context 'when content return url extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_return_url]}) }

        it_behaves_like 'sets selection directive extension', directive
        it_behaves_like 'sets content intended use extension', use
        it_behaves_like 'sets content return types extension', types
        it_behaves_like 'skips content return url extension'
      end
    end

    context 'editor button' do
      before { opts[:resource_type] = 'editor_button' }

      it_behaves_like 'resource group 1 check', 'embed_content', 'embed', 'oembed,lti_launch_url,url,image_url,iframe'
    end

    context 'resource selection' do
      before { opts[:resource_type] = 'resource_selection' }

      it_behaves_like 'resource group 1 check', 'select_link', 'navigation', 'lti_launch_url'
    end

    context 'homework submission' do
      before { opts[:resource_type] = 'homework_submission' }

      it_behaves_like 'sets content intended use extension', 'homework'
      it_behaves_like 'sets content return url extension'

      context 'when resource claim group disabled' do
        let(:opts) { super().merge({claim_group_blacklist: [:resource]}) }

        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'skips content return url extension'
      end

      context 'when content intended use extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_intended_use]}) }

        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'sets content return url extension'
      end

      context 'when content return url extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_return_url]}) }

        it_behaves_like 'sets content intended use extension', 'homework'
        it_behaves_like 'skips content return url extension'
      end
    end

    context 'migration selection' do
      shared_examples 'sets content file extensions extension' do
        it 'adds content file extensions' do
          expect(decoded_jwt['https://www.instructure.com/content_file_extensions']).to eq 'zip,imscc'
        end
      end

      shared_examples 'skips content file extensions extension' do
        it 'does not add content file extensions' do
          expect(decoded_jwt).not_to include 'https://www.instructure.com/content_file_extensions'
        end
      end

      before { opts[:resource_type] = 'migration_selection' }

      it_behaves_like 'sets content file extensions extension'
      it_behaves_like 'sets content intended use extension', 'content_package'
      it_behaves_like 'sets content return types extension', 'file'
      it_behaves_like 'sets content return url extension'

      context 'when resource claim group disabled' do
        let(:opts) { super().merge({claim_group_blacklist: [:resource]}) }

        it_behaves_like 'skips content file extensions extension'
        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'skips content return types extension'
        it_behaves_like 'skips content return url extension'
      end

      context 'when content file extensions extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_file_extensions]}) }

        it_behaves_like 'skips content file extensions extension'
        it_behaves_like 'sets content intended use extension', 'content_package'
        it_behaves_like 'sets content return types extension', 'file'
        it_behaves_like 'sets content return url extension'
      end

      context 'when content intended use extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_intended_use]}) }

        it_behaves_like 'sets content file extensions extension'
        it_behaves_like 'skips content intended use extension'
        it_behaves_like 'sets content return types extension', 'file'
        it_behaves_like 'sets content return url extension'
      end

      context 'when content return types extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_return_types]}) }

        it_behaves_like 'sets content file extensions extension'
        it_behaves_like 'sets content intended use extension', 'content_package'
        it_behaves_like 'skips content return types extension'
        it_behaves_like 'sets content return url extension'
      end

      context 'when content return url extension disabled' do
        let(:opts) { super().merge({extension_blacklist: [:content_return_url]}) }

        it_behaves_like 'sets content file extensions extension'
        it_behaves_like 'sets content intended use extension', 'content_package'
        it_behaves_like 'sets content return types extension', 'file'
        it_behaves_like 'skips content return url extension'
      end
    end
  end
end
