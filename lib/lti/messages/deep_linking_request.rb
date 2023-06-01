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

module Lti::Messages
  # A "factory" class that builds an ID Token (JWT) to be used in LTI Advantage
  # LTI Deep Linking Requests. These requests indicate to the launched
  # tool that Canvas expects it to return data via deep linking.
  #
  # This class relies on a another class (LtiAdvantage::Messages::DeepLinkingRequest)
  # to model the data in the JWT body and produce a signature.
  #
  # For details on the data included in the ID token please refer
  # to http://www.imsglobal.org/spec/lti-dl/v2p0.
  #
  # For implementation details on LTI Advantage launches in
  # Canvas, please see the inline documentation of
  # app/models/lti/lti_advantage_adapter.rb.
  class DeepLinkingRequest < JwtMessage
    DEEP_LINKING_DETAILS = {
      "assignment_selection" => {
        accept_multiple: false,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: false,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "collaboration" => {
        accept_multiple: false,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: true,
        document_targets: %w[iframe].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "conference_selection" => {
        accept_multiple: false,
        accept_types: %w[link html].freeze,
        auto_create: true,
        document_targets: %w[iframe window].freeze,
        media_types: %w[text/html */*].freeze
      }.freeze,
      "course_assignments_menu" => {
        accept_multiple: true,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: false,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "editor_button" => {
        accept_multiple: true,
        accept_types: %w[link file html ltiResourceLink image].freeze,
        auto_create: false,
        document_targets: %w[embed iframe window].freeze,
        media_types: %w[image/* text/html application/vnd.ims.lti.v1.ltilink */*].freeze
      }.freeze,
      "homework_submission" => {
        accept_multiple: false,
        accept_types: %w[file ltiResourceLink].freeze,
        auto_create: false,
        document_targets: %w[iframe].freeze,
        media_types: %w[*/*].freeze
      }.freeze,
      "link_selection" => {
        accept_multiple: true,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: false,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "migration_selection" => {
        accept_multiple: false,
        accept_types: %w[file].freeze,
        auto_create: false,
        document_targets: %w[iframe].freeze,
        media_types: %w[application/vnd.ims.imsccv1p1 application/vnd.ims.imsccv1p2 application/vnd.ims.imsccv1p3 application/zip application/xml].freeze
      }.freeze,
      "module_index_menu_modal" => {
        accept_multiple: true,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: true,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "module_menu_modal" => {
        accept_multiple: true,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: true,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze,
      "submission_type_selection" => {
        accept_multiple: false,
        accept_types: %w[ltiResourceLink].freeze,
        auto_create: false,
        document_targets: %w[iframe window].freeze,
        media_types: %w[application/vnd.ims.lti.v1.ltilink].freeze
      }.freeze
    }.freeze

    MODAL_PLACEMENTS = %w[editor_button assignment_selection link_selection migration_selection course_assignments_menu module_index_menu_modal module_menu_modal].freeze

    def initialize(tool:, context:, user:, expander:, return_url:, opts: {})
      super
      @message = LtiAdvantage::Messages::DeepLinkingRequest.new
    end

    def generate_post_payload_message(validate_launch: true)
      add_deep_linking_request_claims!
      super(validate_launch:)
    end

    private

    def add_deep_linking_request_claims!
      lti_assignment_id = Lti::Security.decoded_lti_assignment_id(@expander.controller&.params&.[]("secure_params"))
      assignment = Assignment.find_by(lti_context_id: lti_assignment_id) if lti_assignment_id
      content_item_id = @expander.collaboration&.id
      @message.deep_linking_settings.deep_link_return_url = return_url(assignment&.id, content_item_id)
      @message.deep_linking_settings.accept_types = DEEP_LINKING_DETAILS.dig(placement, :accept_types)
      @message.deep_linking_settings.accept_presentation_document_targets = DEEP_LINKING_DETAILS.dig(placement, :document_targets)
      @message.deep_linking_settings.accept_media_types = DEEP_LINKING_DETAILS.dig(placement, :media_types).join(",")
      @message.deep_linking_settings.auto_create = DEEP_LINKING_DETAILS.dig(placement, :auto_create)
      @message.deep_linking_settings.accept_multiple = DEEP_LINKING_DETAILS.dig(placement, :accept_multiple)
    end

    def placement
      @opts[:resource_type]
    end

    def return_url(assignment_id = nil, content_item_id = nil)
      @expander.controller.polymorphic_url(
        [@context, :deep_linking_response],
        deep_link_params(assignment_id, content_item_id)
      )
    end

    def deep_link_params(assignment_id, content_item_id)
      {
        data: Lti::DeepLinkingData.jwt_from({
          modal: MODAL_PLACEMENTS.include?(placement),
          placement:,
          context_module_id: @opts[:context_module_id],
          assignment_id:,
          content_item_id:,
          parent_frame_context: @opts[:parent_frame_context]
        }.compact),
      }
    end
  end
end
