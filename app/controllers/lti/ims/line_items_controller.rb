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

module Lti
  module Ims
    # @API Line Items
    #
    # Line Item API for IMS Assignment and Grade Services
    #
    # @model LineItem
    #     {
    #       "id": "LineItem",
    #       "description": "",
    #       "properties": {
    #          "id": {
    #            "description": "The fully qualified URL for showing, updating, and deleting the Line Item",
    #            "example": "http://institution.canvas.com/api/lti/courses/5/line_items/2",
    #            "type": "string"
    #          },
    #          "scoreMaximum": {
    #            "description": "The maximum score of the Line Item",
    #            "example": "50",
    #            "type": "number"
    #          },
    #          "label": {
    #            "description": "The label of the Line Item.",
    #            "example": "50",
    #            "type": "string"
    #          },
    #          "tag": {
    #            "description": "Tag used to qualify a line Item beyond its ids",
    #            "example": "50",
    #            "type": "string"
    #          },
    #          "resourceId": {
    #            "description": "A Tool Provider specified id for the Line Item. Multiple line items can share the same resourceId within a given context",
    #            "example": "50",
    #            "type": "string"
    #          },
    #          "resourceLinkId": {
    #            "description": "The resource link id the Line Item is attached to",
    #            "example": "50",
    #            "type": "string"
    #          },
    #          "https://canvas.instructure.com/lti/submission_type": {
    #            "description": "The extension that defines the submission_type of the line_item. Only returns if set through the line_item create endpoint.",
    #            "example": "{\n\t\"type\":\"external_tool\",\n\t\"external_tool_url\":\"https://my.launch.url\",\n}",
    #            "type": "string"
    #          }
    #       }
    #     }
    class LineItemsController < ApplicationController
      include Concerns::GradebookServices

      before_action :prepare_line_item_for_ags!, only: :create
      before_action :verify_line_item_in_context, only: %i(show update destroy)
      before_action :verify_valid_resource_link, only: :create

      ACTION_SCOPE_MATCHERS = {
        create: all_of(TokenScopes::LTI_AGS_LINE_ITEM_SCOPE),
        update: all_of(TokenScopes::LTI_AGS_LINE_ITEM_SCOPE),
        destroy: all_of(TokenScopes::LTI_AGS_LINE_ITEM_SCOPE),
        show: any_of(TokenScopes::LTI_AGS_LINE_ITEM_SCOPE, TokenScopes::LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE),
        index: any_of(TokenScopes::LTI_AGS_LINE_ITEM_SCOPE, TokenScopes::LTI_AGS_LINE_ITEM_READ_ONLY_SCOPE)
      }.with_indifferent_access.freeze

      MIME_TYPE = 'application/vnd.ims.lis.v2.lineitem+json'.freeze
      CONTAINER_MIME_TYPE = 'application/vnd.ims.lis.v2.lineitemcontainer+json'.freeze

      rescue_from ActionController::BadRequest do |e|
        unless Rails.env.production?
          logger.error(e.message)
          Lti::Errors::ErrorLogger.log_error(e)
        end
        render json: {error: e.message}, status: :bad_request
      end

      # @API Create a Line Item
      # Create a new Line Item
      #
      # @argument scoreMaximum [Required, Float]
      #   The maximum score for the line item. Scores created for the Line Item may exceed this value.
      #
      # @argument label [Required, String]
      #   The label for the Line Item. If no resourceLinkId is specified this value will also be used
      #   as the name of the placeholder assignment.
      #
      # @argument resourceId [String]
      #   A Tool Provider specified id for the Line Item. Multiple line items may
      #   share the same resourceId within a given context.
      #
      # @argument tag [String]
      #    A value used to qualify a line Item beyond its ids. Line Items may be queried
      #    by this value in the List endpoint. Multiple line items can share the same tag
      #    within a given context.
      #
      # @argument resourceLinkId [String]
      #   The resource link id the Line Item should be attached to. This value should
      #   match the LTI id of the Canvas assignment associated with the tool.
      #
      # @argument https://canvas.instructure.com/lti/submission_type [Optional, object]
      #   (EXTENSION) - Optional block to set Assignment Submission Type when creating a new assignment is created.
      #   type - 'none' or 'external_tool'::
      #   external_tool_url - Submission URL only used when type: 'external_tool'::
      # @example_request
      #   {
      #     "scoreMaximum": 100.0,
      #     "label": "LineItemLabel1",
      #     "resourceId": 1,
      #     "tag": "MyTag",
      #     "resourceLinkId": "1",
      #     "https://canvas.instructure.com/lti/submission_type": {
      #       "type": "external_tool",
      #       "external_tool_url": "https://my.launch.url"
      #     }
      #   }
      #
      # @returns LineItem
      def create
        new_line_item = LineItem.create_line_item!(
          assignment,
          context,
          tool,
          line_item_params.merge(resource_link: resource_link)
        )

        render json: LineItemsSerializer.new(new_line_item, line_item_id(new_line_item)),
               status: :created,
               content_type: MIME_TYPE
      end

      # @API Update a Line Item
      # Update new Line Item
      #
      # @argument scoreMaximum [Float]
      #   The maximum score for the line item. Scores created for the Line Item may exceed this value.
      #
      # @argument label [String]
      #   The label for the Line Item. If no resourceLinkId is specified this value will also be used
      #   as the name of the placeholder assignment.
      #
      # @argument resourceId [String]
      #   A Tool Provider specified id for the Line Item. Multiple line items may
      #   share the same resourceId within a given context.
      #
      # @argument tag [String]
      #    A value used to qualify a line Item beyond its ids. Line Items may be queried
      #    by this value in the List endpoint. Multiple line items can share the same tag
      #    within a given context.
      #
      # @returns LineItem
      def update
        line_item.update!(line_item_params)
        update_assignment if line_item.assignment_line_item?
        render json: LineItemsSerializer.new(line_item, line_item_id(line_item)),
               content_type: MIME_TYPE
      end

      # @API Show a Line Item
      # Show existing Line Item
      #
      # @returns LineItem
      def show
        render json: LineItemsSerializer.new(line_item, line_item_id(line_item)),
               content_type: MIME_TYPE
      end

      # @API List line Items
      #
      # @argument tag [String]
      #   If specified only Line Items with this tag will be included.
      #
      # @argument resource_id [String]
      #   If specified only Line Items with this resource_id will be included.
      #
      # @argument resource_link_id [String]
      #   If specified only Line Items attached to the specified resource_link_id will be included.
      #
      # @argument limit [String]
      #   May be used to limit the number of Line Items returned in a page
      #
      # @returns LineItem
      def index
        line_items = Api.paginate(
          Lti::LineItem.active.where(index_query).eager_load(:resource_link),
          self,
          lti_line_item_index_url(course_id: context.id),
          pagination_args
        )
        render json: line_item_collection(line_items),
               content_type: CONTAINER_MIME_TYPE
      end

      # @API Delete a Line Item
      # Delete an existing Line Item
      #
      # @returns LineItem
      def destroy
        head :unauthorized and return if line_item.coupled
        line_item.destroy!
        head :no_content
      end

      private

      def line_item_params
        @_line_item_params ||= begin
          params.permit(%i(resourceId resourceLinkId scoreMaximum label tag),
                        Lti::LineItem::AGS_EXT_SUBMISSION_TYPE => [:type, :external_tool_url]).transform_keys do |k|
            k.to_s.underscore
          end.except(:resource_link_id)
        end
      end

      def assignment
        @_assignment ||= resource_link.line_items&.first&.assignment if params[:resourceLinkId].present?
      end

      def line_item_id(line_item)
        lti_line_item_show_url(
          course_id: params[:course_id],
          id: line_item.id
        )
      end

      def update_assignment
        label = line_item_params[:label]
        score_maximum = line_item_params[:score_maximum]
        return if label.blank? && score_maximum.blank?

        line_item.assignment.name = label if label.present?
        line_item.assignment.points_possible = score_maximum if score_maximum.present?
        line_item.assignment.save!
      end

      def resource_link
        @_resource_link ||= ResourceLink.find_by(
          resource_link_uuid: params[:resourceLinkId],
          context_external_tool: tool
        )
      end

      def index_query
        rlid = params[:resource_link_id]
        assignments = Assignment.
          active.
          joins(rlid.present? ? { line_items: :resource_link } : :line_items).
          where(
            {
              context: context,
              lti_line_items: { client_id: developer_key.global_id }
            }.merge!(rlid.present? ? { lti_resource_links: { resource_link_uuid: rlid } } : {})
          )

        {
          assignment: assignments,
          tag: params[:tag],
          resource_id: params[:resource_id]
        }.compact
      end

      def line_item_collection(line_items)
        line_items.map { |li| LineItemsSerializer.new(li, line_item_id(li)) }
      end

      def verify_valid_resource_link
        return unless params[:resourceLinkId]
        raise ActiveRecord::RecordNotFound if resource_link.blank?
        head :precondition_failed if check_for_bad_resource_link
      end

      def check_for_bad_resource_link
        resource_link.line_items.active.blank? ||
        assignment&.context != context ||
        !assignment&.active?
      end

      def scopes_matcher
        ACTION_SCOPE_MATCHERS.fetch(action_name, self.class.none)
      end
    end
  end
end
