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
      'editor_button' => %w(link file html ltiResourceLink image).freeze
    }.freeze

    DOCUMENT_TARGETS = {
      'editor_button' => %w(embed iframe window).freeze
    }.freeze

    MEDIA_TYPES = {
      'editor_button' => %w(image/* text/html application/vnd.ims.lti.v1.ltilink */*).freeze
    }.freeze

    AUTO_CREATE = {
      'editor_button' => false
    }.freeze

    MODAL_PLACEMENTS = ['editor_button'].freeze

    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      super
      @message = LtiAdvantage::Messages::DeepLinkingRequest.new
    end

    def generate_post_payload_message
      super
      add_deep_linking_request_claims!
      @message
    end

    private

    def add_deep_linking_request_claims!
      @message.deep_linking_settings.deep_link_return_url = return_url
      @message.deep_linking_settings.accept_types = ACCEPT_TYPES[placement]
      @message.deep_linking_settings.accept_presentation_document_targets = DOCUMENT_TARGETS[placement]
      @message.deep_linking_settings.accept_media_types = MEDIA_TYPES[placement].join(',')
      @message.deep_linking_settings.accept_multiple = false
      @message.deep_linking_settings.auto_create = AUTO_CREATE[placement]
    end

    def placement
      @opts[:resource_type]
    end

    def return_url
      @expander.controller.polymorphic_url(
        [@context, :deep_linking_response],
        { modal: MODAL_PLACEMENTS.include?(placement) }
      )
    end
  end
end
