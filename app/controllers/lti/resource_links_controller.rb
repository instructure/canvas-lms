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

# @API LTI Resource Links
#
# API that exposes LTI Resource Links for viewing and editing.
# LTI Resource Links are artifacts created by the LTI 1.3 Deep Linking
# process, where a user selects a content item that is returned to
# Canvas for future launches.
#
# Resource Links can be associated with Assignments, Module Items,
# Collaborations, and Rich Content embeddings.
#
# Use of this API requires the `manage_lti_add` and `manage_assignments_add` permissions.
#
# <b>Caution!</b> Resource Links are usually managed by the tool that created them via LTI Deep Linking,
# and using this API to create or modify links may result in errors when launching the link.
#
# Common patterns for using this API include:
# * facilitating migration between two different versions of the same tool by updating the domain of the launch URL
# * creating new links to embed in rich content in Canvas
# * responding to a course copy or other Canvas content migration by updating the launch URL
#
# @model Lti::ResourceLink
#     {
#       "id": "Lti::ResourceLink",
#       "properties": {
#         "id": {
#           "type": "integer",
#           "description": "The Canvas identifier for the LTI Resource Link.",
#           "example": 1
#         },
#         "context_id": {
#           "type": "integer",
#           "description": "The Canvas identifier for the context that the LTI Resource Link is associated with.",
#           "example": 1
#         },
#         "context_type": {
#           "type": "string",
#           "description": "The type of the context that the LTI Resource Link is associated with.",
#           "example": "Course",
#           "enum":
#           [
#             "Course",
#             "Assignment",
#             "Collaboration"
#           ]
#         },
#         "context_external_tool_id": {
#           "type": "integer",
#           "description": "The Canvas identifier for the LTI 1.3 External Tool that the LTI Resource Link was originally installed from. Note that this tool may have been deleted or reinstalled and may not be the tool that would be launched for this url.",
#           "example": 1
#         },
#         "resource_type": {
#           "type": "string",
#           "description": "The type of Canvas content for the resource link. Included for convenience.",
#           "example": "assignment",
#           "enum":
#           [
#             "assignment",
#             "module_item",
#             "collaboration",
#             "rich_content"
#           ]
#         },
#         "canvas_launch_url": {
#           "type": "string",
#           "description": "The Canvas URL that launches the LTI Resource Link. Suitable for use in Canvas rich content",
#           "example": "https://example.instructure.com/courses/1/external_tools/retrieve?resource_link_lookup_uuid=ae43ba23-d238-49bc-ab55-ba7f79f77896"
#         },
#         "resource_link_uuid": {
#           "type": "string",
#           "description": "The LTI identifier for the LTI Resource Link, included as the resource_link_id when this link is launched",
#           "example": "ae43ba23-d238-49bc-ab55-ba7f79f77896"
#         },
#         "lookup_uuid": {
#           "type": "string",
#           "description": "A unique identifier for the LTI Resource Link, present in the rich content representation. Remains the same across content migration.",
#           "example": "c522554a-d4be-49ef-b163-9c87fdc6ad6f"
#         },
#         "title": {
#           "type": "string",
#           "description": "The title of the LTI Resource Link. Usually tool-provided, or matches the assignment name",
#           "example": "Assignment 1"
#         },
#         "url": {
#           "type": "string",
#           "description": "The tool URL to which the LTI Resource Link will launch",
#           "example": "https://example.com/lti/launch/content_item/123"
#         },
#         "lti_1_1_id": {
#           "type": "string",
#           "description": "The LTI 1.1 identifier for the LTI Resource Link, included in lti1p1 migration claim when launched. Only present if tool was migrated from 1.1 to 1.3.",
#           "example": "6a8aaca162bfc4393804afd4cd53cd94413c48bb"
#         },
#         "created_at": {
#           "description": "Timestamp of the resource link's creation",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "updated_at": {
#           "description": "Timestamp of the resource link's last update",
#           "example": "2024-01-01T00:00:00Z",
#           "type": "string"
#         },
#         "workflow_state": {
#           "description": "The state of the resource link",
#           "example": "active",
#           "type": "string",
#           "enum":
#           [
#             "active",
#             "deleted"
#           ]
#         },
#         "associated_content_type": {
#           "description": "Type of the associated content this resource link belongs to if present. Now only supports `ModuleItems`, later may be extend others",
#           "example": "ModuleItem",
#           "type": "string",
#           "enum":
#           [
#             "ModuleItem"
#           ]
#         },
#         "associated_content_id": {
#           "description": "The Canvas identifier of the associated content, e.g. ModuleItem related to this link. Present if associated_content_type is present",
#           "example": 1,
#           "type": "integer"
#         }
#       }
#     }
class Lti::ResourceLinksController < ApplicationController
  before_action :require_context_instrumented
  before_action :require_permissions
  before_action :validate_custom, only: [:create, :update]
  before_action :validate_url, only: [:create, :update]
  before_action :validate_tool, only: [:update]
  before_action :validate_url_match_tool, only: [:update]

  include Api::V1::Lti::ResourceLink

  MAX_BULK_CREATE = 100

  # @API List LTI Resource Links
  # Returns all Resource Links in the specified course. This includes links
  # that are associated with Assignments, Module Items, Collaborations, and
  # that are embedded in rich content. This endpoint is paginated, and will
  # return 50 links per page by default.
  # Links are sorted by the order in which they were created.
  #
  # @argument include_deleted [Optional, Boolean] Include deleted resource links and links associated with deleted content in response. Default is false.
  # @argument per_page [integer] The number of registrations to return per page. Defaults to 50.
  #
  # @example_request
  #
  #   This would return the first 50 LTI resource links for the course, with a Link header pointing to the next page
  #   curl -X GET 'https://<canvas>/api/v1/courses/1/lti_resource_links' \
  #       -H "Authorization: Bearer <token>" \
  #
  # @returns [Lti::ResourceLink]
  def index
    course_assignment_ids = base_scope(@context.assignments).ids
    # preload Assignment -> Course, used for launch_url
    assignment_links = base_scope.where(context_type: "Assignment", context_id: course_assignment_ids).preload(context: :context)

    # includes Module Items, Collaborations, and Rich Content
    all_other_links = base_scope.where(context: @context).preload(:context)

    bookmarker = BookmarkedCollection::SimpleBookmarker.new(Lti::ResourceLink, :created_at, :id)
    all_links = BookmarkedCollection.merge(
      ["assignment", BookmarkedCollection.wrap(bookmarker, assignment_links)],
      ["course", BookmarkedCollection.wrap(bookmarker, all_other_links)]
    )

    per_page = Api.per_page_for(self, default: 50)
    paginated_links = Api.paginate(all_links, self, url_for, { per_page: })

    render json: paginated_links.map { |link| resource_link_json(link) }
  rescue => e
    report_error(e)
    raise e
  end

  # @API Show an LTI Resource Link
  # Return details about the specified resource link. The ID can be in the standard
  # Canvas format ("1"), or in these special formats:
  #
  # - resource_link_uuid:<uuid> - Find the resource link by its resource_link_uuid
  # - lookup_uuid:<uuid> - Find the resource link by its lookup_uuid
  #
  # @argument include_deleted [Optional, Boolean] Include deleted resource links in search. Default is false.
  #
  # @example_request
  #
  #   This would return the specified LTI resource link
  #   curl -X GET 'https://<canvas>/api/v1/courses/1/lti_resource_links/lookup_uuid:c522554a-d4be-49ef-b163-9c87fdc6ad6f' \
  #       -H "Authorization: Bearer <token>"
  #
  # @returns Lti::ResourceLink
  def show
    render json: resource_link_json(resource_link)
  rescue => e
    report_error(e)
    raise e
  end

  # @API Create an LTI Resource Link
  # Create a new LTI Resource Link in the specified course with the provided parameters.
  #
  # <b>Caution!</b> Resource Links are usually created by the tool via LTI Deep Linking. The tool has no
  # knowledge of links created via this API, and may not be able to handle or launch them.
  #
  # Links created using this API cannot be associated with a specific piece of Canvas content,
  # like an Assignment, Module Item, or Collaboration. Links created using this API are only suitable
  # for embedding in rich content using the `canvas_launch_url` provided in the API response.
  #
  # This link will be associated with the ContextExternalTool available in this context that matches the provided url.
  # If a matching tool is not found, the link will not be created and this will return an error.
  #
  # @argument url [Required, String] The launch URL for this resource link.
  # @argument title [Optional, String] The title of the resource link.
  # @argument custom [Optional, Hash] Custom parameters to be sent to the tool when launching this link.
  #
  # @example_request
  #
  #   This would create a new LTI resource link in the specified course
  #   curl -X POST 'https://<canvas>/api/v1/courses/1/lti_resource_links' \
  #       -H "Authorization: Bearer <token>" \
  #       -d 'url=https://example.com/lti/launch/new_content_item/456' \
  #       -d 'title=New Content Item' \
  #       -d 'custom[hello]=world' \
  #
  # @returns Lti::ResourceLink
  def create
    tool = Lti::ToolFinder.from_url(create_params[:url], @context, only_1_3: true)
    return render_error(:invalid_url, "No tool found for the provided URL") unless tool

    resource_link = Lti::ResourceLink.create_with(
      @context,
      tool,
      create_params[:custom],
      create_params[:url],
      create_params[:title]
    )
    render json: lti_resource_link_json(resource_link, @current_user, session, :rich_content, nil)
  rescue => e
    report_error(e)
    raise e
  end

  # @API Bulk Create LTI Resource Links
  # Create up to 100 new LTI Resource Links in the specified course with the provided parameters.
  #
  # <b>Caution!</b> Resource Links are usually created by the tool via LTI Deep Linking. The tool has no
  # knowledge of links created via this API, and may not be able to handle or launch them.
  #
  # Links created using this API cannot be associated with a specific piece of Canvas content,
  # like an Assignment, Module Item, or Collaboration. Links created using this API are only suitable
  # for embedding in rich content using the `canvas_launch_url` provided in the API response.
  #
  # Each link will be associated with the ContextExternalTool available in this context that matches the provided url.
  # If a matching tool is not found, or any parameters are invalid, no links will be created and this will return an error.
  #
  # @argument POST body [Required, Array] The POST body should be a JSON array of objects containing the parameters for each link to create.
  # @argument []url [Required, String] Each object must contain a launch URL.
  # @argument []title [Optional, String] Each object may contain a title.
  # @argument []custom [Optional, Hash] Custom parameters to be sent to the tool when launching this link.
  #
  # @example_request
  #
  #   This would create a new LTI resource link in the specified course
  #   curl -X POST 'https://<canvas>/api/v1/courses/1/lti_resource_links/bulk' \
  #       -H "Authorization: Bearer <token>" \
  #       --json '[{"url":"https://example.com/lti/launch/new_content_item/456","title":"New Content Item","custom":{"hello":"world"}}]'
  #
  # @returns Lti::ResourceLink
  def bulk_create
    if bulk_create_params[:_json].size > MAX_BULK_CREATE
      return render_error(:invalid_request, "Cannot create more than #{MAX_BULK_CREATE} resource links at once")
    end

    possible_links = bulk_create_params[:_json].map do |link_params|
      tool = Lti::ToolFinder.from_url(link_params[:url], @context, only_1_3: true)
      link_params.merge(tool:)
    end

    errors = possible_links.filter_map do |link_params|
      url = link_params[:url]
      custom = link_params[:custom]

      unless valid_url?(url)
        next { value: url, error: :invalid_url, message: "'url' param must be a valid URL" }
      end

      unless valid_custom?(custom)
        next { value: custom, error: :invalid_custom, message: "'custom' param must contain key/value pairs" }
      end

      unless link_params[:tool]
        next { value: url, error: :invalid_url, message: "No tool found for the provided URL" }
      end

      nil
    end

    if errors.present?
      return render json: { errors: }, status: :unprocessable_entity
    end

    links = bulk_create_links(possible_links, @context)

    render json: links.map { |link| lti_resource_link_json(link, @current_user, session, :rich_content, nil) }
  rescue => e
    report_error(e)
    raise e
  end

  # @API Update an LTI Resource Link
  # Update the specified resource link with the provided parameters.
  #
  # <b>Caution!</b> Changing existing links may result in launch errors.
  #
  # @argument url [Optional, String] The launch URL for this resource link.
  #   <b>Caution!</b> URL must match the URL or domain of the tool associated with this resource link
  # @argument custom [Optional, Hash] Custom parameters to be sent to the tool when launching this link.
  #   <b>Caution!</b> Changing these from what the tool provided could result in errors if the tool doesn't see what it's expecting.
  # @argument include_deleted [Optional, Boolean] Update link even if it is deleted. Default is false.
  # @argument context_external_tool_id [Optional, Integer] The Canvas identifier for the LTI 1.3 External Tool that the LTI Resource Link was originally installed from.
  #  <b>Caution!</b> The resource link url must match the tool's domain or url.
  #
  # @example_request
  #
  #   This would update the specified LTI resource link
  #   curl -X PUT 'https://<canvas>/api/v1/courses/1/lti_resource_links/1' \
  #       -H "Authorization: Bearer <token>" \
  #       -d 'url=https://example.com/lti/launch/new_content_item/456'
  #       -d 'custom[hello]=world'
  #
  # @returns Lti::ResourceLink
  def update
    resource_link.update!(update_params)
    render json: resource_link_json(resource_link)
  rescue => e
    report_error(e)
    raise e
  end

  # @API Delete an LTI Resource Link
  # Delete the specified resource link. The ID can be in the standard
  # Canvas format ("1"), or in these special formats:
  #
  # - resource_link_uuid:<uuid> - Find the resource link by its resource_link_uuid
  # - lookup_uuid:<uuid> - Find the resource link by its lookup_uuid
  #
  # Only links that are not associated with Assignments, Module Items, or Collaborations can be deleted.
  #
  # @example_request
  #
  #   This would return the specified LTI resource link
  #   curl -X DELETE 'https://<canvas>/api/v1/courses/1/lti_resource_links/lookup_uuid:c522554a-d4be-49ef-b163-9c87fdc6ad6f' \
  #       -H "Authorization: Bearer <token>"
  #
  # @returns Lti::ResourceLink
  def destroy
    params.delete(:include_deleted)

    link_type = resource_link_type(resource_link)
    unless link_type == :rich_content
      return render_error(:invalid_resource_link, "Cannot delete resource links associated with Assignments, Module Items, or Collaborations")
    end

    resource_link.destroy!
    render json: resource_link_json(resource_link)
  rescue => e
    report_error(e)
    raise e
  end

  private

  def base_scope(scope = Lti::ResourceLink)
    return scope if params[:include_deleted]

    scope.active
  end

  def resource_link
    id_parameter = params[:id]

    if id_parameter.include?("lookup_uuid:")
      lookup_uuid = id_parameter.sub("lookup_uuid:", "")
      return @resource_link ||= base_scope.find_by!(lookup_uuid:)
    end

    if id_parameter.include?("resource_link_uuid:")
      resource_link_uuid = id_parameter.sub("resource_link_uuid:", "")
      return @resource_link ||= base_scope.find_by!(resource_link_uuid:)
    end

    @resource_link ||= base_scope.find(id_parameter)
  end

  def resource_link_json(link)
    lti_resource_link_json(link, @current_user, session, resource_link_type(link), link_id_to_module_item_id[link.id])
  end

  def resource_link_type(link)
    return :assignment if link.context_type == "Assignment"
    return :module_item if module_item_resource_link_ids.include?(link.id)
    return :collaboration if collaboration_lookup_uuids.include?(link.lookup_uuid)

    :rich_content
  end

  def collaboration_lookup_uuids
    @collaboration_lookup_uuids ||= base_scope(ExternalToolCollaboration.where(context: @context)).pluck(:resource_link_lookup_uuid).compact
  end

  def module_item_resource_link_ids
    @module_item_resource_link_ids ||= link_id_to_module_item_id.keys
  end

  def link_id_to_module_item_id
    @link_id_to_module_item_id ||= base_scope(@context.context_module_tags)
                                   .where(associated_asset_type: "Lti::ResourceLink")
                                   .pluck(:associated_asset_id, :id).to_h
  end

  def bulk_create_links(links, context)
    timestamp = Time.now.utc
    context_id = context.id
    context_type = context.class
    root_account_id = context.root_account_id

    link_data = links.map do |link_params|
      {
        context_id:,
        context_type:,
        context_external_tool_id: link_params[:tool].id,
        url: link_params[:url],
        title: link_params[:title],
        custom: Lti::DeepLinkingUtil.validate_custom_params(link_params[:custom]&.to_unsafe_h),
        lookup_uuid: SecureRandom.uuid,
        resource_link_uuid: SecureRandom.uuid,
        created_at: timestamp,
        updated_at: timestamp,
        workflow_state: "active",
        root_account_id:
      }
    end

    link_ids = Lti::ResourceLink.insert_all(link_data, returning: :id)
    Lti::ResourceLink.where(id: link_ids.rows.flatten).preload(:context)
  end

  def validate_custom
    return if valid_custom?(params[:custom])

    render_error(:invalid_custom, "'custom' param must contain key/value pairs")
  end

  def validate_url
    return if valid_url?(params[:url])

    render_error(:invalid_url, "'url' param must be a valid URL")
  end

  def validate_tool
    return if params[:context_external_tool_id].nil? || (new_tool.present? && new_tool.root_account_id == resource_link.root_account_id)

    render_error(:context_external_tool_id, "'context_external_tool_id' param must be a valid ContextExternalTool ID")
  end

  def validate_url_match_tool
    return if params[:url].nil? && new_tool.nil?

    url = params[:url] || resource_link.url
    tool = new_tool || resource_link.original_context_external_tool
    return if url.nil? || tool.matches_host?(url)

    render_error(:url_tool_mismatch, "'url' param must match the tool associated with 'context_external_tool_id'")
  end

  def valid_custom?(custom)
    return true if custom.nil?
    return false unless custom.respond_to?(:to_unsafe_h)

    custom.to_unsafe_h.all? { |k, v| k.is_a?(String) && v.is_a?(String) }
  end

  def valid_url?(url)
    url.nil? || !!URI.parse(url)
  rescue URI::InvalidURIError
    false
  end

  def new_tool
    @new_tool ||= Lti::ToolFinder.find_by(id: params[:context_external_tool_id])
  end

  def update_params
    params.permit(:url, :context_external_tool_id, custom: ArbitraryStrongishParams::ANYTHING)
  end

  def create_params
    params.permit(:url, :title, custom: ArbitraryStrongishParams::ANYTHING)
  end

  def bulk_create_params
    params.permit(_json: [:url, :title, { custom: ArbitraryStrongishParams::ANYTHING }])
  end

  def require_context_instrumented
    require_course_context
  rescue ActiveRecord::RecordNotFound => e
    report_error(e)
    raise e
  end

  def require_permissions
    require_context_with_permission(@context, :manage_lti_add)
    require_context_with_permission(@context, :manage_assignments_add)
  end

  def render_error(code, message, status: :unprocessable_entity)
    render json: { errors: [{ code:, message: }] }, status:
  end

  def report_error(exception, code = nil)
    code ||= response_code_for_rescue(exception) if exception
    InstStatsd::Statsd.distributed_increment("canvas.lti_resource_links_controller.request_error", tags: { action: action_name, code: })
  end
end
