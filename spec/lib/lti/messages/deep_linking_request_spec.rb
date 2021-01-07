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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/lti_advantage_shared_examples')


describe Lti::Messages::DeepLinkingRequest do
  include_context 'lti_advantage_shared_examples'

  let(:opts) { { resource_type: 'editor_button' } }

  let(:jwt_message) do
    Lti::Messages::DeepLinkingRequest.new(
      tool: tool,
      context: course,
      user: user,
      expander: expander,
      return_url: return_url,
      opts: opts
    )
  end

  let(:jws) { jwt_message.generate_post_payload }

  it_behaves_like 'lti 1.3 message initialization'

  describe '#generate_post_payload_message' do
    subject { jws['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings'] }

    it 'sets the "deep_link_return_url"' do
      expect(subject['deep_link_return_url']).to eq deep_linking_return_url
    end

    context 'when resource type is "collaboration"' do
      let(:opts) {{resource_type: 'collaboration'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(
          ltiResourceLink
        )
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(iframe)
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'application/vnd.ims.lti.v1.ltilink'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq true
      end

      it 'sets "accept_multiple to false"' do
        expect(subject['accept_multiple']).to eq false
      end
    end

    context 'when resource type is "link_selection"' do
      let(:opts) {{resource_type: 'link_selection'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(
          ltiResourceLink
        )
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(
          iframe
          window
        )
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'application/vnd.ims.lti.v1.ltilink'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq false
      end

      it 'sets "accept_multiple to false"' do
        expect(subject['accept_multiple']).to eq false
      end

      context 'when "process_multiple_content_items_modules_index" is enabled' do
        before { Account.site_admin.enable_feature!(:process_multiple_content_items_modules_index) }

        it 'sets "accept_multiple to true"' do
          expect(subject['accept_multiple']).to eq true
        end
      end
    end

    context 'when resource type is "assignment_selection"' do
      let(:opts) {{resource_type: 'assignment_selection'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(
          ltiResourceLink
        )
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(
          iframe
          window
        )
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'application/vnd.ims.lti.v1.ltilink'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq false
      end

      it 'sets the correct "accept_multiple"' do
        expect(subject['accept_multiple']).to eq false
      end
    end

    context 'when resource type is "homework_submission"' do
      let(:opts) {{resource_type: 'homework_submission'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(file ltiResourceLink)
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(iframe)
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq('*/*')
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq false
      end

      it 'sets the correct "accept_multiple"' do
        expect(subject['accept_multiple']).to eq false
      end
    end

    context 'when resource type is "migration_selection"' do
      let(:opts) {{resource_type: 'migration_selection'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(file)
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(iframe)
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'application/vnd.ims.imsccv1p1,application/vnd.ims.imsccv1p2,application/vnd.ims.imsccv1p3,application/zip,application/xml'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq false
      end

      it 'sets the correct "accept_multiple"' do
        expect(subject['accept_multiple']).to eq false
      end
    end

    context 'when resource type is "editor_button"' do
      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(
          link
          file
          html
          ltiResourceLink
          image
        )
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(
          embed
          iframe
          window
        )
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq false
      end

      it 'sets "accept_multiple" to true ' do
        expect(subject['accept_multiple']).to eq true
      end
    end

    context 'when resource type is "conference_selection"' do
      let(:opts) {{resource_type: 'conference_selection'}}

      it 'sets the correct "accept_types"' do
        expect(subject['accept_types']).to match_array %w(
          html
          link
        )
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(subject['accept_presentation_document_targets']).to match_array %w(
          iframe
          window
        )
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject['accept_media_types']).to eq(
          'text/html,*/*'
        )
      end

      it 'sets the correct "auto_create"' do
        expect(subject['auto_create']).to eq true
      end

      it 'sets "accept_multiple" to true ' do
        expect(subject['accept_multiple']).to eq false
      end
    end
  end
end
