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

  let(:jwt_message) do
    Lti::Messages::JwtMessage.new(
      tool: tool,
      context: course,
      user: user,
      expander: expander,
      return_url: return_url,
      opts: opts
    )
  end

  let(:decoded_jwt) do
    jws = jwt_message.generate_post_payload
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
    tool.settings['use_1_3'] = true
    tool.save!
    tool
  end
  let_once(:developer_key) { DeveloperKey.create! }

  describe 'signing' do
    it 'signs the id token with the current canvas private key' do
      jws = jwt_message.generate_post_payload

      expect do
        JSON::JWT.decode(jws[:id_token], pub_key)
      end.not_to raise_exception
    end
  end

  describe 'security claims' do
    it 'sets the "aud" claim' do
      expect(decoded_jwt['aud']).to eq developer_key.global_id
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
      jws = jwt_message.generate_post_payload
      second_nonce = JSON::JWT.decode(jws[:id_token], pub_key)['nonce']

      expect(first_nonce).not_to eq second_nonce
    end

    it 'sets the "sub" claim' do
      expect(decoded_jwt['sub']).to eq user.lti_context_id
    end
  end

  describe 'private claims' do
    it 'sets the locale' do
      expected_locale = 'ca'
      allow(I18n).to receive(:locale).and_return expected_locale
      expect(decoded_jwt['locale']).to eq expected_locale
    end

    it 'sets the roles' do
      expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/roles']).to match_array [
        'http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'
      ]
    end

    context 'context' do
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
    end

    context 'platform' do
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
    end

    context 'launch presentation' do
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
    end

    context 'extensions' do
      it 'adds the Canvas roles extension' do
        expect(decoded_jwt['https://www.instructure.com/roles']).to eq 'urn:lti:role:ims/lis/Learner,urn:lti:sysrole:ims/lis/User'
      end

      it 'adds the Canvas enrollment state extension' do
        expect(decoded_jwt['https://www.instructure.com/canvas_enrollment_state']).to eq 'inactive'
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
        jwt_message.generate_post_payload
        expect(message_custom['no_expansion']).to eq 'foo'
      end

      it 'expands variable expansions' do
        jwt_message.generate_post_payload
        expect(message_custom['has_expansion']).to eq user.id
      end
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
  end

  describe 'include email claims' do
    before { tool.update!(workflow_state: 'email_only') }

    it 'adds the user email' do
      course
      expect(decoded_jwt['email']).to eq user.email
    end
  end

  describe 'public claims' do
    before { tool.update!(workflow_state: 'public') }

    it 'adds the user picture' do
      course
      expect(decoded_jwt['picture']).to eq user.avatar_url
    end

    it 'adds role scope mentor' do
      course
      observer = user_factory
      observer.update!(lti_context_id: SecureRandom.uuid)
      observer_enrollment = course.enroll_user(observer, 'ObserverEnrollment')
      observer_enrollment.update_attribute(:associated_user_id, user.id)
      allow(jwt_message).to receive(:current_observee_list).and_return([observer.lti_context_id])

      expect(decoded_jwt['https://purl.imsglobal.org/spec/lti/claim/role_scope_mentor']).to match_array [
        observer.lti_context_id
      ]
    end

    context 'extensions' do
      context 'when context is a course' do
        it 'adds the canvas course id extension' do
          expect(decoded_jwt['https://www.instructure.com/canvas_course_id']).to eq course.id
        end

        it 'adds the canvas workflow state' do
          expect(decoded_jwt['https://www.instructure.com/canvas_workflow_state']).to eq 'created'
        end

        it 'adds the course section sourcedId' do
          course.update!(sis_source_id: SecureRandom.uuid)
          expect(decoded_jwt['https://www.instructure.com/lis_course_offering_sourcedid']).to eq course.sis_source_id
        end
      end

      context 'when context is an account' do
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
          jws = account_jwt_message.generate_post_payload
          JSON::JWT.decode(jws[:id_token], pub_key)
        end

        it 'adds the canvas account id' do
          expect(account_jwt['https://www.instructure.com/canvas_account_id']).to eq course.root_account.id
        end

        it 'adds the canvas accoutn sis id' do
          expect(account_jwt['https://www.instructure.com/canvas_account_sis_id']).to eq course.root_account.sis_source_id
        end
      end
    end
  end

  describe 'resource claims' do
    context 'editor button' do
      before { opts[:resource_type] = 'editor_button' }

      it 'adds selection directive' do
        expect(decoded_jwt['https://www.instructure.com/selection_directive']).to eq 'embed_content'
      end

      it 'adds content intended use' do
        expect(decoded_jwt['https://www.instructure.com/content_intended_use']).to eq 'embed'
      end

      it 'adds content return types' do
        expect(decoded_jwt['https://www.instructure.com/content_return_types']).to eq 'oembed,lti_launch_url,url,image_url,iframe'
      end

      it 'adds content return url' do
        expect(decoded_jwt['https://www.instructure.com/content_return_url']).to eq return_url
      end
    end

    context 'resource selection' do
      before { opts[:resource_type] = 'resource_selection' }

      it 'adds selection directive' do
        expect(decoded_jwt['https://www.instructure.com/selection_directive']).to eq 'select_link'
      end

      it 'adds content intended use' do
        expect(decoded_jwt['https://www.instructure.com/content_intended_use']).to eq 'navigation'
      end

      it 'adds content return types' do
        expect(decoded_jwt['https://www.instructure.com/content_return_types']).to eq 'lti_launch_url'
      end

      it 'adds content return url' do
        expect(decoded_jwt['https://www.instructure.com/content_return_url']).to eq return_url
      end
    end

    context 'homework submission' do
      before { opts[:resource_type] = 'homework_submission' }

      it 'adds content intended use' do
        expect(decoded_jwt['https://www.instructure.com/content_intended_use']).to eq 'homework'
      end

      it 'adds content return url' do
        expect(decoded_jwt['https://www.instructure.com/content_return_url']).to eq return_url
      end
    end

    context 'migration selection' do
      before { opts[:resource_type] = 'migration_selection' }

      it 'adds selection directive' do
        expect(decoded_jwt['https://www.instructure.com/content_file_extensions']).to eq 'zip,imscc'
      end

      it 'adds content intended use' do
        expect(decoded_jwt['https://www.instructure.com/content_intended_use']).to eq 'content_package'
      end

      it 'adds content return types' do
        expect(decoded_jwt['https://www.instructure.com/content_return_types']).to eq 'file'
      end

      it 'adds content return url' do
        expect(decoded_jwt['https://www.instructure.com/content_return_url']).to eq return_url
      end
    end
  end
end