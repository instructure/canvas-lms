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
    # @internal
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
    #            "description": "A Tool Provider specified id for the Line Item.
    #                            Multiple line items can share the same resourceId within a given context",
    #            "example": "50",
    #            "type": "string"
    #          },
    #          "ltiLinkId": {
    #            "description": "The resource link id the Line Item is attached to",
    #            "example": "50",
    #            "type": "string"
    #          }
    #       }
    #     }
    class LineItemsController < ApplicationController
      include Concerns::GradebookServices

      skip_before_action :load_user

      before_action :verify_line_item_in_context, only: %i(show update destroy)
      before_action :verify_valid_resource_link, only: :create

      MIME_TYPE = 'application/vnd.ims.lis.v2.lineitem+json'.freeze
      CONTAINER_MIME_TYPE = 'application/vnd.ims.lis.v2.lineitemcontainer+json'.freeze

      # @API Create a Line Item
      # Create a new Line Item
      #
      # @argument scoreMaximum [Required, Float]
      #   The maximum score for the line item. Scores created for the Line Item may exceed this value.
      #
      # @argument label [Required, String]
      #   The label for the Line Item. If no ltiLinkId is specified this value will also be used
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
      # @argument ltiLinkId [String]
      #   The resource link id the Line Item should be attached to. This value should
      #   match the LTI id of the Canvas assignment associated with the tool.
      #
      # @returns LineItem
      def create
        new_line_item = LineItem.create!(
          line_item_params.merge({assignment_id: assignment_id, resource_link: resource_link})
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
      #   The label for the Line Item. If no ltiLinkId is specified this value will also be used
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
        line_item.update_attributes!(line_item_params)
        update_assignment_title if line_item.assignment_line_item?
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
      # @argument resouce_id [String]
      #   If specified only Line Items with this resource_id will be included.
      #
      # @argument lti_link_id [String]
      #   If specified only Line Items attached to the specified lti_link_id will be included.
      #
      # @argument limit [String]
      #   May be used to limit the number of Line Items returned in a page
      #
      # @returns LineItem
      def index
        line_items = Api.paginate(
          Lti::LineItem.where(index_query),
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
        return render_unauthorized_action if line_item.assignment_line_item? && line_item.resource_link.present?
        line_item.destroy!
        head :no_content
      end

      private

      def line_item_params
        @_line_item_params ||= begin
          params.permit(%i(resourceId ltiLinkId scoreMaximum label tag)).transform_keys do |k|
            k.to_s.underscore
          end.except(:lti_link_id)
        end
      end

      def assignment_id
        @_assignment_id ||= begin
          if params[:ltiLinkId].present?
            resource_link.line_items&.first&.assignment_id
          else
            Assignment.create!(
              context: context,
              name: line_item_params[:label],
              points_possible: line_item_params[:score_maximum],
              submission_types: 'none'
            ).id
          end
        end
      end

      def line_item_id(line_item)
        lti_line_item_show_url(
          course_id: params[:course_id],
          id: line_item.id
        )
      end

      def update_assignment_title
        return if line_item_params[:label].blank?
        line_item.assignment.update_attributes!(name: line_item_params[:label])
      end

      def resource_link
        # TODO: Create an Lti::ResourceLink when a 1.3 tool is associated with an assignment
        @_resource_link ||= ResourceLink.find_by(resource_link_id: params[:ltiLinkId])
      end

      def index_query
        assignments = Assignment.where(context: context)
        # TODO: only show line items that belong to the current tool.
        {
          assignment: assignments,
          tag: params[:tag],
          resource_id: params[:resource_id],
          lti_resource_link_id: Lti::ResourceLink.find_by(resource_link_id: params[:lti_link_id])
        }.compact
      end

      def line_item_collection(line_items)
        line_items.map { |li| LineItemsSerializer.new(li, line_item_id(li)) }
      end

      def verify_valid_resource_link
        return unless params[:ltiLinkId]
        raise ActiveRecord::RecordNotFound if resource_link.blank?
        head :precondition_failed if resource_link.line_items.blank?
        # TODO: check that the Lti::ResouceLink is owned by the tool
      end
    end
  end
end
