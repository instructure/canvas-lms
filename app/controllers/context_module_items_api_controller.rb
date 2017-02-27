#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Modules
# @subtopic Module Items
#
# @model CompletionRequirement
#     {
#       "id": "CompletionRequirement",
#       "description": "",
#       "properties": {
#         "type": {
#           "description": "one of 'must_view', 'must_submit', 'must_contribute', 'min_score'",
#           "example": "min_score",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "must_view",
#               "must_submit",
#               "must_contribute",
#               "min_score"
#             ]
#           }
#         },
#         "min_score": {
#           "description": "minimum score required to complete (only present when type == 'min_score')",
#           "example": 10,
#           "type": "integer"
#         },
#         "completed": {
#           "description": "whether the calling user has met this requirement (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)",
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model ContentDetails
#     {
#       "id": "ContentDetails",
#       "description": "",
#       "properties": {
#         "points_possible": {
#           "example": 20,
#           "type": "integer"
#         },
#         "due_at": {
#           "example": "2012-12-31T06:00:00-06:00",
#           "type": "datetime"
#         },
#         "unlock_at": {
#           "example": "2012-12-31T06:00:00-06:00",
#           "type": "datetime"
#         },
#         "lock_at": {
#           "example": "2012-12-31T06:00:00-06:00",
#           "type": "datetime"
#         },
#         "locked_for_user": {
#           "example": true,
#           "type": "boolean"
#         },
#         "lock_explanation": {
#           "example": "This quiz is part of an unpublished module and is not available yet.",
#           "type": "string"
#         },
#         "lock_info": {
#           "example": {"asset_string": "assignment_4", "unlock_at": "2012-12-31T06:00:00-06:00", "lock_at": "2012-12-31T06:00:00-06:00", "context_module": {}},
#           "$ref": "LockInfo"
#         }
#       }
#     }
#
# @model ModuleItem
#     {
#       "id": "ModuleItem",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the module item",
#           "example": 768,
#           "type": "integer"
#         },
#         "module_id": {
#           "description": "the id of the Module this item appears in",
#           "example": 123,
#           "type": "integer"
#         },
#         "position": {
#           "description": "the position of this item in the module (1-based)",
#           "example": 1,
#           "type": "integer"
#         },
#         "title": {
#           "description": "the title of this item",
#           "example": "Square Roots: Irrational numbers or boxy vegetables?",
#           "type": "string"
#         },
#         "indent": {
#           "description": "0-based indent level; module items may be indented to show a hierarchy",
#           "example": 0,
#           "type": "integer"
#         },
#         "type": {
#           "description": "the type of object referred to one of 'File', 'Page', 'Discussion', 'Assignment', 'Quiz', 'SubHeader', 'ExternalUrl', 'ExternalTool'",
#           "example": "Assignment",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "File",
#               "Page",
#               "Discussion",
#               "Assignment",
#               "Quiz",
#               "SubHeader",
#               "ExternalUrl",
#               "ExternalTool"
#             ]
#           }
#         },
#         "content_id": {
#           "description": "the id of the object referred to applies to 'File', 'Discussion', 'Assignment', 'Quiz', 'ExternalTool' types",
#           "example": 1337,
#           "type": "integer"
#         },
#         "html_url": {
#           "description": "link to the item in Canvas",
#           "example": "https://canvas.example.edu/courses/222/modules/items/768",
#           "type": "string"
#         },
#         "url": {
#           "description": "(Optional) link to the Canvas API object, if applicable",
#           "example": "https://canvas.example.edu/api/v1/courses/222/assignments/987",
#           "type": "string"
#         },
#         "page_url": {
#           "description": "(only for 'Page' type) unique locator for the linked wiki page",
#           "example": "my-page-title",
#           "type": "string"
#         },
#         "external_url": {
#           "description": "(only for 'ExternalUrl' and 'ExternalTool' types) external url that the item points to",
#           "example": "https://www.example.com/externalurl",
#           "type": "string"
#         },
#         "new_tab": {
#           "description": "(only for 'ExternalTool' type) whether the external tool opens in a new tab",
#           "example": false,
#           "type": "boolean"
#         },
#         "completion_requirement": {
#           "description": "Completion requirement for this module item",
#           "example": {"type": "min_score", "min_score": 10, "completed": true},
#           "$ref": "CompletionRequirement"
#         },
#         "content_details": {
#           "description": "(Present only if requested through include[]=content_details) If applicable, returns additional details specific to the associated object",
#           "example": {"points_possible": 20, "due_at": "2012-12-31T06:00:00-06:00", "unlock_at": "2012-12-31T06:00:00-06:00", "lock_at": "2012-12-31T06:00:00-06:00"},
#           "$ref": "ContentDetails"
#         }
#       }
#     }
#
# @model ModuleItemSequence
#     {
#       "id": "ModuleItemSequence",
#       "description": "",
#       "properties": {
#         "items": {
#           "description": "an array containing one hash for each appearence of the asset in the module sequence (up to 10 total)",
#           "example": [{"prev": null, "current": {"id": 768, "module_id": 123, "title": "A lonely page", "type": "Page"}, "next": {"id": 769, "module_id": 127, "title": "Project 1", "type": "Assignment"}}],
#           "type": "array",
#           "items": { "type": "object" }
#         },
#         "modules": {
#           "description": "an array containing each Module referenced above",
#           "type": "array",
#           "items": { "$ref": "Module" }
#         }
#       }
#     }
#
class ContextModuleItemsApiController < ApplicationController
  before_action :require_context
  before_action :require_user, :only => [:select_mastery_path]
  before_action :find_student, :only => [:index, :show, :select_mastery_path]
  before_action :disable_escape_html_entities, :only => [:index, :show]
  after_action :enable_escape_html_entities, :only => [:index, :show]
  include Api::V1::ContextModule

  # @API List module items
  #
  # List the items in a module
  #
  # @argument include[] [String, "content_details"]
  #   If included, will return additional details specific to the content
  #   associated with each item. Refer to the {api:Modules:Module%20Item Module
  #   Item specification} for more details.
  #   Includes standard lock information for each item.
  #
  # @argument search_term [String]
  #   The partial title of the items to match and return.
  #
  # @argument student_id
  #   Returns module completion information for the student with this id.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123/items
  #
  # @returns [ModuleItem]
  def index
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@student || @current_user).find(params[:module_id])
      ActiveRecord::Associations::Preloader.new.preload(mod, content_tags: :content)
      route = polymorphic_url([:api_v1, @context, mod, :items])
      scope = mod.content_tags_visible_to(@student || @current_user)
      scope = ContentTag.search_by_attribute(scope, :title, params[:search_term])
      items = Api.paginate(scope, self, route)
      prog = @student ? mod.evaluate_for(@student) : nil
      includes = Array(params[:include])
      opts = {}

      # Get conditionally released objects if requested
      # TODO: Document in API when out of beta
      if includes.include?("mastery_paths")
        opts[:conditional_release_rules] = ConditionalRelease::Service.rules_for(@context, @student, items, session)
      end
      render :json => items.map { |item| module_item_json(item, @student || @current_user, session, mod, prog, includes, opts) }
    end
  end

  # @API Show module item
  #
  # Get information about a single module item
  #
  # @argument include[] [String, "content_details"]
  #   If included, will return additional details specific to the content
  #   associated with this item. Refer to the {api:Modules:Module%20Item Module
  #   Item specification} for more details.
  #   Includes standard lock information for each item.
  #
  # @argument student_id
  #   Returns module completion information for the student with this id.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123/items/768
  #
  # @returns ModuleItem
  def show
    if authorized_action(@context, @current_user, :read)
      get_module_item
      prog = @student ? @module.evaluate_for(@student) : nil
      render :json => module_item_json(@item, @student || @current_user, session, @module, prog, Array(params[:include]))
    end
  end

  # Mark an external URL content tag read for purposes of module progression,
  # then redirect to the URL (vs. render in an iframe like content_tag_redirect).
  # Not documented directly; part of an opaque URL returned by above endpoints.
  def redirect
    if authorized_action(@context, @current_user, :read)
      @tag = @context.context_module_tags.not_deleted.find(params[:id])
      if !(@tag.unpublished? || @tag.context_module.unpublished?) || authorized_action(@tag.context_module, @current_user, :update)
        if @tag.content_type == 'ExternalUrl'
          @tag.context_module_action(@current_user, :read)
          redirect_to @tag.url
        else
          return render(:status => 400, :json => { :message => "incorrect module item type" })
        end
      end
    end
  end

  # @API Create a module item
  #
  # Create and return a new module item
  #
  # @argument module_item[title] [String]
  #   The name of the module item and associated content
  #
  # @argument module_item[type] [Required, String, "File"|"Page"|"Discussion"|"Assignment"|"Quiz"|"SubHeader"|"ExternalUrl"|"ExternalTool"]
  #   The type of content linked to the item
  #
  # @argument module_item[content_id] [Required, String]
  #   The id of the content to link to the module item. Required, except for
  #   'ExternalUrl', 'Page', and 'SubHeader' types.
  #
  # @argument module_item[position] [Integer]
  #   The position of this item in the module (1-based).
  #
  # @argument module_item[indent] [Integer]
  #   0-based indent level; module items may be indented to show a hierarchy
  #
  # @argument module_item[page_url] [String]
  #   Suffix for the linked wiki page (e.g. 'front-page'). Required for 'Page'
  #   type.
  #
  # @argument module_item[external_url] [String]
  #   External url that the item points to. [Required for 'ExternalUrl' and
  #   'ExternalTool' types.
  #
  # @argument module_item[new_tab] [Boolean]
  #   Whether the external tool opens in a new tab. Only applies to
  #   'ExternalTool' type.
  #
  # @argument module_item[completion_requirement][type] [String, "must_view"|"must_contribute"|"must_submit"]
  #   Completion requirement for this module item.
  #   "must_view": Applies to all item types
  #   "must_contribute": Only applies to "Assignment", "Discussion", and "Page" types
  #   "must_submit", "min_score": Only apply to "Assignment" and "Quiz" types
  #   Inapplicable types will be ignored
  #
  # @argument module_item[completion_requirement][min_score] [Integer]
  #   Minimum score required to complete. Required for completion_requirement
  #   type 'min_score'.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items \
  #       -X POST \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'module_item[title]=module item' \
  #       -d 'module_item[type]=ExternalTool' \
  #       -d 'module_item[content_id]=10' \
  #       -d 'module_item[position]=2' \
  #       -d 'module_item[indent]=1' \
  #       -d 'module_item[new_tab]=true'
  #
  # @returns ModuleItem
  def create
    @module = @context.context_modules.not_deleted.find(params[:module_id])
    if authorized_action(@module, @current_user, :update)
      return render :json => {:message => "missing module item parameter"}, :status => :bad_request unless params[:module_item]

      item_params = params[:module_item].slice(:title, :type, :indent, :new_tab)
      item_params[:id] = params[:module_item][:content_id]
      if ['Page', 'WikiPage'].include?(item_params[:type])
        if page_url = params[:module_item][:page_url]
          if wiki_page = @context.wiki.wiki_pages.not_deleted.where(url: page_url).first
            item_params[:id] = wiki_page.id
          else
            return render :json => {:message => "invalid page_url parameter"}, :status => :bad_request
          end
        else
          return render :json => {:message => "missing page_url parameter"}, :status => :bad_request
        end
      end

      item_params[:url] = params[:module_item][:external_url]

      if (@tag = @module.add_item(item_params)) && set_position && set_completion_requirement
        @tag.workflow_state = 'unpublished'
        @tag.save
        @module.touch
        render :json => module_item_json(@tag, @current_user, session, @module, nil)
      elsif @tag
        render :json => @tag.errors, :status => :bad_request
      else
        render :status => 400, :json => { :message => t(:invalid_content, "Could not find content") }
      end
    end
  end

  # @API Update a module item
  #
  # Update and return an existing module item
  #
  # @argument module_item[title] [String]
  #   The name of the module item
  #
  # @argument module_item[position] [Integer]
  #   The position of this item in the module (1-based)
  #
  # @argument module_item[indent] [Integer]
  #   0-based indent level; module items may be indented to show a hierarchy
  #
  # @argument module_item[external_url] [String]
  #   External url that the item points to. Only applies to 'ExternalUrl' type.
  #
  # @argument module_item[new_tab] [Boolean]
  #   Whether the external tool opens in a new tab. Only applies to
  #   'ExternalTool' type.
  #
  # @argument module_item[completion_requirement][type] [String, "must_view"|"must_contribute"|"must_submit"]
  #   Completion requirement for this module item.
  #   "must_view": Applies to all item types
  #   "must_contribute": Only applies to "Assignment", "Discussion", and "Page" types
  #   "must_submit", "min_score": Only apply to "Assignment" and "Quiz" types
  #   Inapplicable types will be ignored
  #
  # @argument module_item[completion_requirement][min_score] [Integer]
  #   Minimum score required to complete, Required for completion_requirement
  #   type 'min_score'.
  #
  # @argument module_item[published] [Boolean]
  #   Whether the module item is published and visible to students.
  #
  # @argument module_item[module_id] [String]
  #   Move this item to another module by specifying the target module id here.
  #   The target module must be in the same course.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id> \
  #       -X PUT \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'module_item[position]=2' \
  #       -d 'module_item[indent]=1' \
  #       -d 'module_item[new_tab]=true'
  #
  # @returns ModuleItem
  def update
    @tag = @context.context_module_tags.not_deleted.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      return render :json => {:message => "missing module item parameter"}, :status => :bad_request unless params[:module_item]

      @tag.title = params[:module_item][:title] if params[:module_item][:title]
      @tag.url = params[:module_item][:external_url] if %w(ExternalUrl ContextExternalTool).include?(@tag.content_type) && params[:module_item][:external_url]
      @tag.indent = params[:module_item][:indent] if params[:module_item][:indent]
      @tag.new_tab = value_to_boolean(params[:module_item][:new_tab]) if params[:module_item][:new_tab]
      if (target_module_id = params[:module_item][:module_id]) && target_module_id.to_i != @tag.context_module_id
        target_module = @context.context_modules.where(id: target_module_id).first
        return render :json => {:message => "invalid module_id"}, :status => :bad_request unless target_module
        old_module = @context.context_modules.find(@tag.context_module_id)
        @tag.remove_from_list
        @tag.context_module = target_module
        if req_index = old_module.completion_requirements.find_index { |req| req[:id] == @tag.id }
          old_module.completion_requirements_will_change!
          req = old_module.completion_requirements.delete_at(req_index)
          old_module.save!
          params[:module_item][:completion_requirement] = req
        else
          ContentTag.touch_context_modules([old_module.id, target_module_id])
        end
      end

      if params[:module_item].has_key?(:published)
        if value_to_boolean(params[:module_item][:published])
          @tag.publish
        else
          @tag.unpublish
        end
        @tag.save
        @tag.update_asset_workflow_state!
        @tag.context_module.save
      end

      if @tag.save && set_position && set_completion_requirement
        @tag.update_asset_name! if params[:module_item][:title]
        render :json => module_item_json(@tag, @current_user, session, @tag.context_module, nil)
      else
        render :json => @tag.errors, :status => :bad_request
      end
    end
  end

  # @API Select a mastery path
  #
  # Select a mastery path when module item includes several possible paths.
  # Requires Mastery Paths feature to be enabled.  Returns a compound document
  # with the assignments included in the given path and any module items
  # related to those assignments
  #
  # @argument assignment_set_id
  #   Assignment set chosen, as specified in the mastery_paths portion of the
  #   context module item response
  #
  # @argument student_id
  #   Which student the selection applies to.  If not specified, current user is
  #   implied.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id>/select_master_path \
  #       -X POST \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'assignment_set_id=2992'
  #
  def select_mastery_path
    return unless authorized_action(@context, @current_user, :read)
    return unless @student == @current_user || authorized_action(@context, @current_user, :manage_assignments)
    return render json: { message: 'mastery paths not enabled' }, status: :bad_request unless ConditionalRelease::Service.enabled_in_context?(@context)
    return render json: { message: 'assignment_set_id required' }, status: :bad_request unless params[:assignment_set_id]

    get_module_item
    assignment = @item.assignment
    return render json: { message: 'requested item is not an assignment' }, status: :bad_request unless assignment

    response = ConditionalRelease::Service.select_mastery_path(
      @context,
      @current_user,
      @student,
      assignment,
      params[:assignment_set_id],
      session)

    if response[:code] != '200'
      render json: response[:body], status: response[:code]
    else
      assignment_ids = response[:body]['assignments'].map {|a| a['assignment_id'].try(&:to_i) }
      # assignment occurs in delayed job, may not be fully visible to user until job completes
      assignments = @context.assignments.published.where(id: assignment_ids)

      Assignment.preload_context_module_tags(assignments)

      # match cyoe order, omit unpublished or deleted assignments
      assignments = assignments.index_by(&:id).values_at(*assignment_ids).compact

      # grab locally relevant module items
      items = assignments.map(&:all_context_module_tags).flatten.select{|a| a.context_module_id == @module.id}

      render json: {
        meta: { primaryCollection: 'assignments' },
        items: items.map { |item| module_item_json(item, @student || @current_user, session, @module) },
        assignments: assignments_json(assignments, @current_user, session)
      }
    end
  end

  # @API Delete module item
  #
  # Delete a module item
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id> \
  #       -X Delete \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns ModuleItem
  def destroy
    @tag = @context.context_module_tags.not_deleted.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @module = @tag.context_module
      @tag.destroy
      @module.touch
      render :json => module_item_json(@tag, @current_user, session, @module, nil)
    end
  end


  # @API Mark module item as done/not done
  #
  # Mark a module item as done/not done. Use HTTP method PUT to mark as done,
  # and DELETE to mark as not done.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id>/done \
  #       -X Put \
  #       -H 'Authorization: Bearer <token>'
  def mark_as_done
    if authorized_action(@context, @current_user, :read)
      get_module_item
      @item.context_module_action(@current_user, :done)
      render :json => { :message => t('OK') }
    end
  end

  def mark_as_not_done
    if authorized_action(@context, @current_user, :read)
      get_module_item
      if (progression = @item.progression_for_user(@current_user))
        progression.uncomplete_requirement(params[:id].to_i)
        progression.evaluate
      end
      render :json => { :message => t('OK') }
    end
  end

  def get_module_item
    user = @student || @current_user
    @module = @context.modules_visible_to(user).find(params[:module_id])
    @item = @module.content_tags.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @item && @item.visible_to_user?(user)
  end

  MAX_SEQUENCES = 10
  # @API Get module item sequence
  #
  # Given an asset in a course, find the ModuleItem it belongs to, and also the previous and next Module Items
  # in the course sequence.
  #
  # @argument asset_type [String, "ModuleItem"|"File"|"Page"|"Discussion"|"Assignment"|"Quiz"|"ExternalTool"]
  #   The type of asset to find module sequence information for. Use the ModuleItem if it is known
  #   (e.g., the user navigated from a module item), since this will avoid ambiguity if the asset
  #   appears more than once in the module sequence.
  #
  # @argument asset_id [Integer]
  #   The id of the asset (or the url in the case of a Page)
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/module_item_sequence?asset_type=Assignment&asset_id=123 \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns ModuleItemSequence
  def item_sequence
    if authorized_action(@context, @current_user, :read)
      asset_type = Api.api_type_to_canvas_name(params[:asset_type])
      return render :json => { :message => 'invalid asset_type'}, :status => :bad_request unless asset_type
      asset_id = params[:asset_id]
      return render :json => { :message => 'missing asset_id' }, :status => :bad_request unless asset_id

      # assemble a sequence of content tags in the course
      # (break ties on module position by module id)
      tag_ids = @context.sequential_module_item_ids & @context.module_items_visible_to(@current_user).reorder(nil).pluck(:id)

      # find content tags to include
      tag_indices = []
      if asset_type == 'ContentTag'
        tag_ids.each_with_index { |tag_id, ix| tag_indices << ix if tag_id == asset_id.to_i }
      else
        # map wiki page url to id
        if asset_type == 'WikiPage'
          page = @context.wiki.wiki_pages.not_deleted.where(url: asset_id).first
          asset_id = page.id if page
        else
          asset_id = asset_id.to_i
        end

        # find the associated assignment id, if applicable
        if asset_type == 'Quizzes::Quiz'
          asset = @context.quizzes.where(id: asset_id.to_i).first
          associated_assignment_id = asset.assignment_id if asset
        end

        if asset_type == 'DiscussionTopic'
          asset = @context.send(asset_type.tableize).where(id: asset_id.to_i).first
          associated_assignment_id = asset.assignment_id if asset
        end

        # find up to MAX_SEQUENCES tags containing the object (or its associated assignment)
        matching_tag_ids = @context.context_module_tags.where(:id => tag_ids).
          where(:content_type => asset_type, :content_id => asset_id).pluck(:id)
        if associated_assignment_id
          matching_tag_ids += @context.context_module_tags.where(:id => tag_ids).
            where(:content_type => 'Assignment', :content_id => associated_assignment_id).pluck(:id)
        end

        if matching_tag_ids.any?
          tag_ids.each_with_index { |tag_id, ix| tag_indices << ix if matching_tag_ids.include?(tag_id) }
        end
      end

      tag_indices.sort!
      if tag_indices.length > MAX_SEQUENCES
        tag_indices = tag_indices[0, MAX_SEQUENCES]
      end

      # render the result
      result = { :items => [] }

      needed_tag_ids = []
      tag_indices.each do |ix|
        needed_tag_ids << tag_ids[ix]
        needed_tag_ids << tag_ids[ix - 1] if ix > 0
        needed_tag_ids << tag_ids[ix + 1] if ix < tag_ids.size - 1
      end

      needed_tags = ContentTag.where(:id => needed_tag_ids.uniq).preload(:context_module).index_by(&:id)
      tag_indices.each do |ix|
        hash = { :current => module_item_json(needed_tags[tag_ids[ix]], @current_user, session), :prev => nil, :next => nil }
        if ix > 0
          hash[:prev] = module_item_json(needed_tags[tag_ids[ix - 1]], @current_user, session)
        end
        if ix < tag_ids.size - 1
          hash[:next] = module_item_json(needed_tags[tag_ids[ix + 1]], @current_user, session)
        end
        result[:items] << hash
      end
      modules = needed_tags.values.map(&:context_module).uniq
      result[:modules] = modules.map { |mod| module_json(mod, @current_user, session) }

      render :json => result
    end
  end

  # @API Mark module item read
  #
  # Fulfills "must view" requirement for a module item. It is generally not necessary to do this explicitly,
  # but it is provided for applications that need to access external content directly (bypassing the html_url
  # redirect that normally allows Canvas to fulfill "must view" requirements).
  #
  # This endpoint cannot be used to complete requirements on locked or unpublished module items.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id>/mark_read \
  #       -X POST \
  #       -H 'Authorization: Bearer <token>'
  #
  def mark_item_read
    if authorized_action(@context, @current_user, :read)
      get_module_item
      content = (@item.content && @item.content.respond_to?(:locked_for?)) ? @item.content : @item
      return render :json => { :message => t('The module item is locked.') }, :status => :forbidden if content.locked_for?(@current_user)

      @item.context_module_action(@current_user, :read)
      render :json => { :message => t('OK') }
    end
  end

  def disable_escape_html_entities
    ActiveSupport.escape_html_entities_in_json = false
  end
  private :disable_escape_html_entities

  def enable_escape_html_entities
    ActiveSupport.escape_html_entities_in_json = true
  end
  private :enable_escape_html_entities

  def set_position
    return true unless @tag && params[:module_item][:position]

    @tag.reload
    if @tag.insert_at(params[:module_item][:position].to_i)
      # see ContextModulesController#reorder_items
      @tag.touch_context_module
      ContentTag.update_could_be_locked(@tag.context_module.content_tags)
      @context.touch

      @tag.reload
      return true
    else
      @tag.errors.add(:position, t(:invalid_position, "Invalid position"))
      return false
    end
  end
  protected :set_position

  def set_completion_requirement
    return true unless @tag && params[:module_item][:completion_requirement]

    reqs = {}
    @module ||= @tag.context_module
    @module.completion_requirements.each{|i| reqs[i[:id]] = i }

    if params[:module_item][:completion_requirement].blank?
      reqs[@tag.id] = {}
    elsif ["must_view", "must_submit", "must_contribute", "min_score"].include?(params[:module_item][:completion_requirement][:type])
      reqs[@tag.id] = params[:module_item][:completion_requirement].with_indifferent_access
    else
      @tag.errors.add(:completion_requirement, t(:invalid_requirement_type, "Invalid completion requirement type"))
      return false
    end

    @module.completion_requirements = reqs
    @module.save
  end
  protected :set_completion_requirement

  def find_student
    if params[:student_id]
      student_enrollments = @context.student_enrollments.for_user(params[:student_id])
      return render_unauthorized_action unless student_enrollments.any?{|e| e.grants_right?(@current_user, session, :read_grades)}
      @student = student_enrollments.first.user
    elsif @context.grants_right?(@current_user, session, :participate_as_student)
      @student = @current_user
    else
      return true
    end
  end
  protected :find_student
end
