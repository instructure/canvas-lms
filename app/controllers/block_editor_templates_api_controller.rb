# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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
#

# @API BlockEditorTemplate
#
# Block Editor Templates are pre-build templates that can be used to create pages.
# The BlockEditorTemplate API allows you to create, retrieve, update, and delete templates.
#
# @model BlockEditorTemplate
#     {
#       "id": "BlockEditorTemplate",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the ID of the page",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "name of the template",
#           "example": "Navigation Bar",
#           "type": "string"
#         },
#         "description": {
#           "description": "description of the template",
#           "example": "A bar of links to other content",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "the creation date for the template",
#           "example": "2012-08-06T16:46:33-06:00",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "the date the template was last updated",
#           "example": "2012-08-08T14:25:20-06:00",
#           "type": "datetime"
#         },
#         "node_tree": {
#           "description": "The JSON data that is the template",
#           "type": "string"
#         },
#         "editor_version": {
#           "description": "The version of the editor that created the template",
#           "example": "1.0",
#           "type": "string"
#         },
#         "template_type": {
#           "description": "The type of template. One of 'block', 'section', or 'page'",
#           "example": "page",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "String indicating what state this assignment is in.",
#           "example": "unpublished",
#           "type": "string"
#         }
#       }
#     }
#

class BlockEditorTemplatesApiController < ApplicationController
  include Api::V1::BlockEditorTemplate

  before_action :require_context

  # @API List block templates
  #
  # A list of the block templates available to the current user.
  #
  # @argument sort [String, "name"|"created_at"|"updated_at"]
  #   Sort results by this field.
  #
  # @argument order [String, "asc"|"desc"]
  #   The sorting order. Defaults to 'asc'.
  #
  # @argument drafts [Boolean]
  #   If true, include draft templates. If false or omitted
  #   only published templates will be returned.
  #
  # @argument type[] [String, "page"|"section"|"block"]
  #   What type of templates should be returned.
  #
  # @argument include[] [String, "node_tree" | "thumbnail"]
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/123/block_editor_templates?sort=name&order=asc&drafts=true
  #
  # @returns [BlockEditorTemplate]
  def index
    unless @context.account.feature_enabled?(:block_editor)
      return render status: :forbidden
    end

    if authorized_action(@context, @current_user, :read)
      log_api_asset_access(["block_editor_templates", @context], "block_editor_templates", "other")

      includes = Array(params[:include])

      scope_columns = BlockEditorTemplate.column_names
      scope_columns -= ["created_at", "updated_at"]
      scope_columns -= ["node_tree"] unless includes.include?("node_tree")
      scope_columns -= ["thumbnail"] unless includes.include?("thumbnail")

      where_clause = {}
      where_clause[:template_type] = params[:type] if params[:type]
      where_clause[:workflow_state] = (value_to_boolean(params[:drafts]) && template_editor?) ? %w[active unpublished] : "active"

      scope = @context.block_editor_templates.where(where_clause).select(scope_columns)

      order_clause = case params[:sort]
                     when "name"
                       @context.block_editor_templates.name_order_by_clause
                     when "created_at",
                       "updated_at",
                       "todo_date"
                       params[:sort].to_sym
                     end
      if order_clause
        order_clause = { order_clause => :desc } if params[:order] == "desc"
        scope = scope.order(order_clause)
      end
      id_clause = :id
      id_clause = { id: :desc } if params[:order] == "desc"
      scope = scope.order(id_clause)

      render json: block_editor_templates_json(scope, @current_user, session)
    end
  end

  def create
    if template_editor?
      template_params = get_update_params(params)
      template = BlockEditorTemplate.new(template_params)
      template.context = @context
      template.name = params[:name] || "Untitled Template"
      template.node_tree = params[:node_tree] || "{}"
      template.editor_version = params[:editor_version] || "0.2"
      template.template_type = params[:template_type] || "page"
      template.thumbnail = params[:thumbnail] if params[:thumbnail].present?
      template.workflow_state = params[:workflow_state]
      template.save!
      render json: block_editor_template_json(template, @current_user, session)
    else
      render status: :forbidden, json: { message: t("Cannot create block templates.") }
    end
  end

  def update
    if template_editor?
      template = BlockEditorTemplate.find(params[:id])
      template.update!(get_update_params(params))
      render json: block_editor_template_json(template, @current_user, session)
    else
      render status: :forbidden, json: { message: t("Cannot update block templates.") }
    end
  end

  def publish
    if template_editor?
      template = BlockEditorTemplate.find(params[:id])
      if template.present?
        template.publish!
        render json: block_editor_template_json(template, @current_user, session)
      else
        render status: :bad_request
      end
    else
      render status: :forbidden, json: { message: t("Cannot publish block templates.") }
    end
  end

  def destroy
    if template_editor?
      template = BlockEditorTemplate.find(params[:id])

      if template&.destroy
        render json: template.to_json
      else
        render status: :bad_request
      end
    else
      render status: :forbidden, json: { message: t("Cannot delete block templates.") }
    end
  end

  def can_edit
    can = template_editor?
    cang = global_template_editor?
    render json: { can_edit: can || cang, can_edit_global: cang }
  end

  def template_editor?
    @current_user.account.feature_enabled?(:block_editor) &&
      @current_user.account.feature_enabled?(:block_template_editor) &&
      (@context.grants_right?(@current_user, :block_editor_template_editor) ||
       @context.grants_right?(@current_user, :block_editor_global_template_editor))
  end

  def global_template_editor?
    @current_user.account.feature_enabled?(:block_editor) &&
      @current_user.account.feature_enabled?(:block_template_editor) &&
      @context.grants_right?(@current_user, :block_editor_global_template_editor)
  end

  private

  def get_update_params(incoming_params)
    allowed_fields = Set[:id, :name, :description, :node_tree, :editor_version, :template_type, :thumbnail, :workflow_state].freeze
    incoming_params = incoming_params.slice(*allowed_fields)
    incoming_params.permit!
    incoming_params
  end
end
