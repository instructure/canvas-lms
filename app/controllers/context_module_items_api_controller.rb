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
# @object Module Item
#     {
#       // the unique identifier for the module item
#       id: 768,
#
#       // the position of this item in the module (1-based)
#       position: 1,
#
#       // the title of this item
#       title: "Square Roots: Irrational numbers or boxy vegetables?",
#
#       // 0-based indent level; module items may be indented to show a hierarchy
#       indent: 0,
#
#       // the type of object referred to
#       // one of "File", "Page", "Discussion", "Assignment", "Quiz", "SubHeader",
#       // "ExternalUrl", "ExternalTool"
#       type: "Assignment",
#
#       // link to the item in Canvas
#       html_url: "https://canvas.example.edu/courses/222/modules/items/768",
#
#       // (Optional) link to the Canvas API object, if applicable
#       url: "https://canvas.example.edu/api/v1/courses/222/assignments/987",
#
#       // (only for 'ExternalUrl' and 'ExternalTool' types) external url that the item points to
#       external_url: "https://www.example.com/externalurl",
#
#       // (only for 'ExternalTool' type) whether the external tool opens in a new tab
#       new_tab: false,
#
#       // Completion requirement for this module item
#       completion_requirement: {
#         // one of "must_view", "must_submit", "must_contribute", "min_score"
#         type: "min_score",
#
#         // minimum score required to complete (only present when type == 'min_score')
#         min_score: 10,
#
#         // whether the calling user has met this requirement
#         // (Optional; present only if the caller is a student)
#         completed: true
#       }
#     }
class ContextModuleItemsApiController < ApplicationController
  before_filter :require_context
  include Api::V1::ContextModule

  # @API List module items
  #
  # List the items in a module
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123/items
  #
  # @returns [Module Item]
  def index
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@current_user).find(params[:module_id])
      route = polymorphic_url([:api_v1, @context, mod, :items])
      scope = mod.content_tags.active
      items = Api.paginate(scope, self, route)
      prog = @context.grants_right?(@current_user, session, :participate_as_student) ? mod.evaluate_for(@current_user) : nil
      render :json => items.map { |item| module_item_json(item, @current_user, session, mod, prog) }
    end
  end

  # @API Show module item
  #
  # Get information about a single module item
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123/items/768
  #
  # @returns Module Item
  def show
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@current_user).find(params[:module_id])
      item = mod.content_tags.active.find(params[:id])
      prog = @context.grants_right?(@current_user, session, :participate_as_student) ? mod.evaluate_for(@current_user) : nil
      render :json => module_item_json(item, @current_user, session, mod, prog)
    end
  end

  # Mark an external URL content tag read for purposes of module progression,
  # then redirect to the URL (vs. render in an iframe like content_tag_redirect).
  # Not documented directly; part of an opaque URL returned by above endpoints.
  def redirect
    if authorized_action(@context, @current_user, :read)
      @tag = @context.context_module_tags.active.find(params[:id])
      if @tag.content_type == 'ExternalUrl'
        @tag.context_module_action(@current_user, :read)
        redirect_to @tag.url
      else
        return render(:status => 400, :json => { :message => "incorrect module item type" })
      end
    end
  end

  # @API Create a module item
  #
  # Create and return a new module item
  #
  # @argument module_item[title] [Optional] The name of the module item and associated content
  # @argument module_item[type] [Required] The type of content linked to the item
  #  one of "File", "Page", "Discussion", "Assignment", "Quiz", "SubHeader", "ExternalUrl", "ExternalTool"
  # @argument module_item[content_id] [Required, except for 'ExternalUrl' and 'SubHeader' types] The id of the content to link to the module item
  # @argument module_item[position] [Optional] The position of this module in the course (1-based)
  # @argument module_item[indent] [Optional] 0-based indent level; module items may be indented to show a hierarchy
  # @argument module_item[external_url] [Required for 'ExternalUrl' and 'ExternalTool' types] External url that the item points to
  # @argument module_item[new_tab] [Optional, only applies to 'ExternalTool' type] Whether the external tool opens in a new tab
  # @argument module_item[completion_requirement][type] [Optional] Completion requirement for this module item
  #   "must_view": Applies to all item types
  #   "must_contribute": Only applies to "Assignment", "Discussion", and "Page" types
  #   "must_submit", "min_score": Only apply to "Assignment" and "Quiz" types
  #   Inapplicable types will be ignored
  # @argument module_item[completion_requirement][min_score] [Required for completion_requirement type 'min_score'] minimum score required to complete
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
  # @returns Module Item
  def create
    @module = @context.context_modules.not_deleted.find(params[:module_id])
    if authorized_action(@module, @current_user, :update)
      return render :json => {:message => "missing module item parameter"}, :status => :bad_request unless params[:module_item]

      item_params = params[:module_item].slice(:title, :type, :indent, :new_tab)
      item_params[:id] = params[:module_item][:content_id]
      item_params[:url] = params[:module_item][:external_url]

      if (@tag = @module.add_item(item_params)) && set_position && set_completion_requirement
        @module.touch
        render :json => module_item_json(@tag, @current_user, session, @module, nil)
      elsif @tag
        render :json => @tag.errors.to_json, :status => :bad_request
      else
        render :status => 400, :json => { :message => t(:invalid_content, "Could not find content") }
      end
    end
  end

  # @API Update a module item
  #
  # Update and return an existing module item
  #
  # @argument module_item[title] [Optional] The name of the module item
  # @argument module_item[position] [Optional] The position of this module in the course (1-based)
  # @argument module_item[indent] [Optional] 0-based indent level; module items may be indented to show a hierarchy
  # @argument module_item[external_url] [Optional, only applies to 'ExternalUrl' type] External url that the item points to
  # @argument module_item[new_tab] [Optional, only applies to 'ExternalTool' type] Whether the external tool opens in a new tab
  # @argument module_item[completion_requirement][type] [Optional] Completion requirement for this module item
  #   "must_view": Applies to all item types
  #   "must_contribute": Only applies to "Assignment", "Discussion", and "Page" types
  #   "must_submit", "min_score": Only apply to "Assignment" and "Quiz" types
  #   Inapplicable types will be ignored
  # @argument module_item[completion_requirement][min_score] [Required for completion_requirement type 'min_score'] minimum score required to complete
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id>/items/<item_id> \
  #       -X PUT \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'module_item[content_id]=10' \
  #       -d 'module_item[position]=2' \
  #       -d 'module_item[indent]=1' \
  #       -d 'module_item[new_tab]=true'
  #
  # @returns Module Item
  def update
    @tag = @context.context_module_tags.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      return render :json => {:message => "missing module item parameter"}, :status => :bad_request unless params[:module_item]

      @tag.title = params[:module_item][:title] if params[:module_item][:title]
      @tag.url = params[:module_item][:external_url] if %w(ExternalUrl ContextExternalTool).include?(@tag.content_type) && params[:module_item][:external_url]
      @tag.indent = params[:module_item][:indent] if params[:module_item][:indent]
      @tag.new_tab = value_to_boolean(params[:module_item][:new_tab]) if params[:module_item][:new_tab]

      if @tag.save && set_position && set_completion_requirement
        @tag.update_asset_name! if params[:module_item][:title]
        render :json => module_item_json(@tag, @current_user, session, @tag.context_module, nil)
      else
        render :json => @tag.errors.to_json, :status => :bad_request
      end
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
  # @returns Module Item
  def destroy
    @tag = @context.context_module_tags.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @module = @tag.context_module
      @tag.destroy
      @module.touch
      render :json => module_item_json(@tag, @current_user, session, @module, nil)
    end
  end

  def set_position
    return true unless @tag && params[:module_item][:position]

    @tag.reload
    if @tag.insert_at_position(params[:module_item][:position], @tag.context_module.content_tags.active)
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
end
