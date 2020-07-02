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

module Lti::Messages
  class DeepLinkingRequest < JwtMessage
    ACCEPT_TYPES = {
      'migration_selection' => %w(file).freeze,
      'editor_button' => %w(link file html ltiResourceLink image).freeze,
      'assignment_selection' => %w(ltiResourceLink).freeze,
      'homework_submission' => %w(file).freeze,
      'link_selection' => %w(ltiResourceLink).freeze,
      'conference_selection' => %w(link html).freeze,
      'submission_type_selection' => %w(ltiResourceLink).freeze
    }.freeze

    DOCUMENT_TARGETS = {
      'migration_selection' => %w(iframe).freeze,
      'editor_button' => %w(embed iframe window).freeze,
      'assignment_selection' => %w(iframe window).freeze,
      'homework_submission' => %w(iframe).freeze,
      'link_selection' => %w(iframe window).freeze,
      'conference_selection' => %w(iframe window).freeze,
      'submission_type_selection' => %w(iframe window).freeze
    }.freeze

    MEDIA_TYPES = {
      'migration_selection' => %w(
        application/vnd.ims.imsccv1p1
        application/vnd.ims.imsccv1p2
        application/vnd.ims.imsccv1p3
        application/zip
        application/xml
      ).freeze,
      'editor_button' => %w(image/* text/html application/vnd.ims.lti.v1.ltilink */*).freeze,
      'assignment_selection' => %w(application/vnd.ims.lti.v1.ltilink).freeze,
      'homework_submission' => %w(*/*).freeze,
      'link_selection' => %w(application/vnd.ims.lti.v1.ltilink).freeze,
      'conference_selection' => %w(text/html */*).freeze,
      'submission_type_selection' => %w(application/vnd.ims.lti.v1.ltilink).freeze,
    }.freeze

    AUTO_CREATE = {
      'migration_selection' => false,
      'editor_button' => false,
      'assignment_selection' => false,
      'homework_submission' => false,
      'link_selection' => false,
      'conference_selection' => true
    }.freeze

    ACCEPT_MULTIPLE = {
      'migration_selection' => false,
      'editor_button' => true,
      'assignment_selection' => false,
      'homework_submission' => false,
      'link_selection' => true,
      'conference_selection' => false
    }.freeze

    MODAL_PLACEMENTS = %w(editor_button assignment_selection link_selection migration_selection).freeze

    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      super
      @message = LtiAdvantage::Messages::DeepLinkingRequest.new
    end

    def generate_post_payload_message(validate_launch: true)
      add_deep_linking_request_claims!
      super(validate_launch: validate_launch)
    end

    private

    def accept_multiple_overrides
      {
        'link_selection' => Account.site_admin.feature_enabled?(:process_multiple_content_items_modules_index)
      }
    end

    def add_deep_linking_request_claims!
      @message.deep_linking_settings.deep_link_return_url = return_url
      @message.deep_linking_settings.accept_types = ACCEPT_TYPES[placement]
      @message.deep_linking_settings.accept_presentation_document_targets = DOCUMENT_TARGETS[placement]
      @message.deep_linking_settings.accept_media_types = MEDIA_TYPES[placement].join(',')
      @message.deep_linking_settings.accept_multiple = ACCEPT_MULTIPLE.merge(accept_multiple_overrides)[placement]
      @message.deep_linking_settings.auto_create = AUTO_CREATE[placement]
    end

    def placement
      @opts[:resource_type]
    end

    def return_url
      @expander.controller.polymorphic_url(
        [@context, :deep_linking_response],
        {
          modal: MODAL_PLACEMENTS.include?(placement),
          context_module_id: @opts[:context_module_id]
        }.compact
      )
    end
  end
end
