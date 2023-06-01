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

require_relative "lti_advantage_shared_examples"

describe Lti::Messages::DeepLinkingRequest do
  include_context "lti_advantage_shared_examples"

  let(:opts) { { resource_type: "editor_button" } }

  let(:jwt_message) do
    Lti::Messages::DeepLinkingRequest.new(
      tool:,
      context: course,
      user:,
      expander:,
      return_url:,
      opts:
    )
  end

  let(:jws) { jwt_message.generate_post_payload }

  it_behaves_like "lti 1.3 message initialization"

  describe "#generate_post_payload_message" do
    subject { jws["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"] }

    it 'sets the "deep_link_return_url"' do
      expect(subject["deep_link_return_url"]).to eq deep_linking_return_url
    end

    context "when assignment with nil lti_context_id exists" do
      before do
        a = Assignment.create!(name: "no lti_context_id", context: course)
        a.update_attribute(:lti_context_id, nil)
      end

      it "does not use assignment return url" do
        expect(subject["deep_link_return_url"]).to eq deep_linking_return_url
      end
    end

    shared_examples_for "sets deep linking attributes" do
      it 'sets the correct "accept_types"' do
        expect(subject["accept_types"]).to match_array accept_types
      end

      it 'sets the correct "accept_presentation_document_targets"' do
        expect(
          subject["accept_presentation_document_targets"]
        ).to match_array accept_presentation_document_targets
      end

      it 'sets the correct "accept_media_types"' do
        expect(subject["accept_media_types"]).to eq accept_media_types
      end

      it 'sets the correct "auto_create"' do
        expect(subject["auto_create"]).to eq auto_create
      end

      it 'sets "accept_multiple"' do
        expect(subject["accept_multiple"]).to eq accept_multiple
      end
    end

    context 'when resource type is "collaboration"' do
      let(:opts) { { resource_type: "collaboration" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe] }
        let(:accept_media_types) { "application/vnd.ims.lti.v1.ltilink" }
        let(:auto_create) { true }
        let(:accept_multiple) { false }
      end

      context "when editing an existing collaboration (expander.collaboration != nil)" do
        let(:collaboration) do
          ExternalToolCollaboration.create! context: course, title: "foo", url: "http://notneededhere.example.com"
        end

        it "includes the content_item_id in the deep linking return URL's data JWT" do
          expect(Lti::DeepLinkingData).to receive(:jwt_from) do |claims|
            expect(claims[:content_item_id]).to eq(collaboration.id)
          end
          subject
        end
      end
    end

    context 'when resource type is "link_selection"' do
      let(:opts) { { resource_type: "link_selection" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe window] }
        let(:accept_media_types) { "application/vnd.ims.lti.v1.ltilink" }
        let(:auto_create) { false }
        let(:accept_multiple) { true }
      end
    end

    context 'when resource type is "assignment_selection"' do
      let(:opts) { { resource_type: "assignment_selection" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe window] }
        let(:accept_media_types) { "application/vnd.ims.lti.v1.ltilink" }
        let(:auto_create) { false }
        let(:accept_multiple) { false }
      end
    end

    context 'when resource type is "homework_submission"' do
      let(:opts) { { resource_type: "homework_submission" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[file ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe] }
        let(:accept_media_types) { "*/*" }
        let(:auto_create) { false }
        let(:accept_multiple) { false }
      end
    end

    context 'when resource type is "migration_selection"' do
      let(:opts) { { resource_type: "migration_selection" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[file] }
        let(:accept_presentation_document_targets) { %w[iframe] }
        let(:accept_media_types) do
          "application/vnd.ims.imsccv1p1,application/vnd.ims.imsccv1p2,application/vnd.ims.imsccv1p3,application/zip,application/xml"
        end
        let(:auto_create) { false }
        let(:accept_multiple) { false }
      end
    end

    context 'when resource type is "editor_button"' do
      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[link file html ltiResourceLink image] }
        let(:accept_presentation_document_targets) { %w[embed iframe window] }
        let(:accept_media_types) { "image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*" }
        let(:auto_create) { false }
        let(:accept_multiple) { true }
      end
    end

    context 'when resource type is "conference_selection"' do
      let(:opts) { { resource_type: "conference_selection" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[html link] }
        let(:accept_presentation_document_targets) { %w[iframe window] }
        let(:accept_media_types) { "text/html,*/*" }
        let(:auto_create) { true }
        let(:accept_multiple) { false }
      end
    end

    context 'when resource type is "course_assignments_menu"' do
      let(:opts) { { resource_type: "course_assignments_menu" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe window] }
        let(:accept_media_types) { "application/vnd.ims.lti.v1.ltilink" }
        let(:auto_create) { false }
        let(:accept_multiple) { true }
      end
    end

    context 'when resource type is "module_index_menu_modal"' do
      let(:opts) { { resource_type: "module_index_menu_modal" } }

      it_behaves_like "sets deep linking attributes" do
        let(:accept_types) { %w[ltiResourceLink] }
        let(:accept_presentation_document_targets) { %w[iframe window] }
        let(:accept_media_types) { "application/vnd.ims.lti.v1.ltilink" }
        let(:auto_create) { true }
        let(:accept_multiple) { true }
      end
    end
  end
end
