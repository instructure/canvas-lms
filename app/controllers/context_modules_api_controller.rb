#
# Copyright (C) 2012 Instructure, Inc.
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
#
# Modules are collections of learning materials useful for organizing courses
# and optionally providing a linear flow through them. Module items can be
# accessed linearly or sequentially depending on module configuration. Items
# can be unlocked by various criteria such as reading a page or achieving a
# minimum score on a quiz. Modules themselves can be unlocked by the completion
# of other Modules.
#
# @object Module
#     {
#       // the unique identifier for the module
#       id: 123,
#       // the state of the module: active, deleted
#       workflow_state: active,
#
#       // the position of this module in the course (1-based)
#       position: 2,
#
#       // the name of this module
#       name: "Imaginary Numbers and You",
#
#       // (Optional) the date this module will unlock
#       unlock_at: "2012-12-31T06:00:00-06:00",
#
#       // Whether module items must be unlocked in order
#       require_sequential_progress: true,
#
#       // IDs of Modules that must be completed before this one is unlocked
#       prerequisite_module_ids: [121, 122],
#
#       // The state of this Module for the calling user
#       // one of 'locked', 'unlocked', 'started', 'completed'
#       // (Optional; present only if the caller is a student)
#       state: 'started',
#
#       // the date the calling user completed the module
#       // (Optional; present only if the caller is a student)
#       completed_at: nil
#     }
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
class ContextModulesApiController < ApplicationController
  before_filter :require_context  
  include Api::V1::ContextModule

  # @API List modules
  #
  # List the modules in a course
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/222/modules
  #
  # @returns [Module]
  def index
    if authorized_action(@context, @current_user, :read)
      route = polymorphic_url([:api_v1, @context, :context_modules])
      scope = @context.modules_visible_to(@current_user)
      modules = Api.paginate(scope, self, route)
      modules_and_progressions = if @context.grants_right?(@current_user, session, :participate_as_student)
        modules.map { |m| [m, m.evaluate_for(@current_user)] }
      else
        modules.map { |m| [m, nil] }
      end
      render :json => modules_and_progressions.map { |mod, prog| module_json(mod, @current_user, session, prog) }
    end
  end

  # @API Show module
  #
  # Get information about a single module
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/222/modules/123
  #
  # @returns Module
  def show
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@current_user).find(params[:id])
      prog = @context.grants_right?(@current_user, session, :participate_as_student) ? mod.evaluate_for(@current_user) : nil
      render :json => module_json(mod, @current_user, session, prog)
    end
  end

  # @API List module items
  #
  # List the items in a module
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \ 
  #          https://<canvas>/api/v1/courses/222/modules/123/items
  #
  # @returns [Module Item]
  def list_module_items
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
  def show_module_item
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
  def module_item_redirect
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

  # @undocumented API Update modules
  #
  # Update multiple modules in an account.
  #
  # @argument module_ids[] List of ids of modules to update.
  # @argument event The action to take on each module. Must be 'delete'.
  #
  # @response_field completed A list of IDs for modules that were updated.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules \  
  #       -X PUT \ 
  #       -H 'Authorization: Bearer <token>' \ 
  #       -d 'event=delete' \
  #       -d 'module_ids[]=1' \ 
  #       -d 'module_ids[]=2' 
  #
  # @example_response
  #    {
  #      "completed": [1, 2]
  #    }
  def batch_update
    if authorized_action(@context, @current_user, :manage_content)
      event = params[:event]
      return render(:json => { :message => 'need to specify event' }, :status => :bad_request) unless event.present?
      return render(:json => { :message => 'invalid event' }, :status => :bad_request) unless %w(publish unpublish delete).include? event
      return render(:json => { :message => 'must specify module_ids[]' }, :status => :bad_request) unless params[:module_ids].present?

      module_ids = Api.map_non_sis_ids(Array(params[:module_ids]))
      modules = @context.context_modules.not_deleted.find_all_by_id(module_ids)
      return render(:json => { :message => 'no modules found' }, :status => :not_found) if modules.empty?

      completed_ids = []
      modules.each do |mod|
        case event
          when 'publish'
            mod.publish unless mod.active?
          when 'unpublish'
            mod.unpublish unless mod.unpublished?
          when 'delete'
            mod.destroy
        end
        completed_ids << mod.id
      end

      render :json => { :completed => completed_ids }
    end
  end

end
