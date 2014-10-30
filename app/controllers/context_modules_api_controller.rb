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
# @model ModuleItemCompletionRequirement
#     {
#       "id": "ModuleItemCompletionRequirement",
#       "description": "",
#       "properties": {
#         "type": {
#           "example": "min_score",
#           "type": "string"
#         },
#         "min_score": {
#           "example": 10,
#           "type": "integer"
#         },
#         "completed": {
#           "example": true,
#           "type": "boolean"
#         }
#       }
#     }
#
# @model ModuleItemContentDetails
#     {
#       "id": "ModuleItemContentDetails",
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
#           "$ref": "ModuleItemCompletionRequirement"
#         },
#         "content_details": {
#           "description": "(Present only if requested through include[]=content_details) If applicable, returns additional details specific to the associated object",
#           "$ref": "ModuleItemContentDetails"
#         }
#       }
#     }
#
# @model ModuleItemSequenceAsset
#     {
#       "id": "ModuleItemSequenceAsset",
#       "description": "",
#       "properties": {
#         "id": {
#           "example": 768,
#           "type": "integer"
#         },
#         "module_id": {
#           "example": 123,
#           "type": "integer"
#         },
#         "title": {
#           "example": "A lonely page",
#           "type": "string"
#         },
#         "type": {
#           "example": "Page",
#           "type": "string"
#         }
#       }
#     }
#
# @model ModuleItemSequenceNode
#     {
#       "id": "ModuleItemSequenceNode",
#       "description": "",
#       "properties": {
#         "prev": {
#           "$ref": "ModuleItemSequenceAsset"
#         },
#         "current": {
#           "$ref": "ModuleItemSequenceAsset"
#         },
#         "next": {
#           "$ref": "ModuleItemSequenceAsset"
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
#           "type": "array",
#           "items": { "$ref": "ModuleItemSequenceNode" }
#         },
#         "modules": {
#           "description": "an array containing each Module referenced above",
#           "type": "array",
#           "items": { "$ref": "Module" }
#         }
#       }
#     }
#
# @model Module
#     {
#       "id": "Module",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the module",
#           "example": 123,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "the state of the module: 'active', 'deleted'",
#           "example": "active",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "active",
#               "deleted"
#             ]
#           }
#         },
#         "position": {
#           "description": "the position of this module in the course (1-based)",
#           "example": 2,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of this module",
#           "example": "Imaginary Numbers and You",
#           "type": "string"
#         },
#         "unlock_at": {
#           "description": "(Optional) the date this module will unlock",
#           "example": "2012-12-31T06:00:00-06:00",
#           "type": "datetime"
#         },
#         "require_sequential_progress": {
#           "description": "Whether module items must be unlocked in order",
#           "example": true,
#           "type": "boolean"
#         },
#         "prerequisite_module_ids": {
#           "description": "IDs of Modules that must be completed before this one is unlocked",
#           "example": "\[121, 122\]",
#           "type": "array",
#           "items": {"type": "integer"}
#         },
#         "items_count": {
#           "description": "The number of items in the module",
#           "example": 10,
#           "type": "integer"
#         },
#         "items_url": {
#           "description": "The API URL to retrive this module's items",
#           "example": "https://canvas.example.com/api/v1/modules/123/items",
#           "type": "string"
#         },
#         "items": {
#           "description": "The contents of this module, as an array of Module Items. (Present only if requested via include[]=items AND the module is not deemed too large by Canvas.)",
#           "example": "\[\]",
#           "type": "array",
#           "items": { "$ref": "ModuleItem" }
#         },
#         "state": {
#           "description": "The state of this Module for the calling user one of 'locked', 'unlocked', 'started', 'completed' (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)",
#           "example": "started",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "locked",
#               "unlocked",
#               "started",
#               "completed"
#             ]
#           }
#         },
#         "completed_at": {
#           "description": "the date the calling user completed the module (Optional; present only if the caller is a student or if the optional parameter 'student_id' is included)",
#           "type": "datetime"
#         },
#         "publish_final_grade": {
#           "description": "if the student's final grade for the course should be published to the SIS upon completion of this module",
#           "type": "boolean"
#         }
#       }
#     }
#
class ContextModulesApiController < ApplicationController
  before_filter :require_context
  before_filter :find_student, :only => [:index, :show]
  include Api::V1::ContextModule

  # @API List modules
  #
  # List the modules in a course
  #
  # @argument include[] [String, "items"|"content_details"]
  #    - "items": Return module items inline if possible.
  #      This parameter suggests that Canvas return module items directly
  #      in the Module object JSON, to avoid having to make separate API
  #      requests for each module when enumerating modules and items. Canvas
  #      is free to omit 'items' for any particular module if it deems them
  #      too numerous to return inline. Callers must be prepared to use the
  #      {api:ContextModuleItemsApiController#index List Module Items API}
  #      if items are not returned.
  #    - "content_details": Requires include['items']. Returns additional
  #      details with module items specific to their associated content items.
  #      Includes standard lock information for each item.
  #
  # @argument search_term [String]
  #   The partial name of the modules (and module items, if include['items'] is
  #   specified) to match and return.
  #
  # @argument student_id
  #   Returns module completion information for the student with this id.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules
  #
  # @returns [Module]
  def index
    if authorized_action(@context, @current_user, :read)
      route = polymorphic_url([:api_v1, @context, :context_modules])
      scope = @context.modules_visible_to(@student || @current_user)

      includes = Array(params[:include])
      scope = ContextModule.search_by_attribute(scope, :name, params[:search_term]) unless includes.include?('items')
      modules = Api.paginate(scope, self, route)

      ActiveRecord::Associations::Preloader.new(modules, content_tags: :content) if includes.include?('items')

      if @student
        modules_and_progressions = modules.map { |m| [m, m.evaluate_for(@student)] }
      else
        modules_and_progressions = modules.map { |m| [m, nil] }
      end
      opts = {}
      if includes.include?('items') && params[:search_term].present?
        SearchTermHelper.validate_search_term(params[:search_term])
        opts[:search_term] = params[:search_term]
      end

      if @context.feature_enabled?(:differentiated_assignments) && includes.include?('items')
        user_ids = (@student || @current_user).id

        if @context.user_has_been_observer?(@student || @current_user)
          opts[:observed_student_ids] = ObserverEnrollment.observed_student_ids(self.context, (@student || @current_user) )
          user_ids.concat(opts[:observed_student_ids])
        end

        opts[:assignment_visibilities] = AssignmentStudentVisibility.visible_assignment_ids_for_user(user_ids, @context.id)
        opts[:discussion_visibilities] = DiscussionTopic.visible_to_students_in_course_with_da(user_ids, @context.id).pluck(:id)
        opts[:quiz_visibilities] = Quizzes::Quiz.visible_to_students_in_course_with_da(user_ids,@context.id).pluck(:quiz_id)
      end

      render :json => modules_and_progressions.map { |mod, prog| module_json(mod, @student || @current_user, session, prog, includes, opts) }.compact
    end
  end

  # @API Show module
  #
  # Get information about a single module
  #
  # @argument include[] [String, "items"|"content_details"]
  #    - "items": Return module items inline if possible.
  #      This parameter suggests that Canvas return module items directly
  #      in the Module object JSON, to avoid having to make separate API
  #      requests for each module when enumerating modules and items. Canvas
  #      is free to omit 'items' for any particular module if it deems them
  #      too numerous to return inline. Callers must be prepared to use the
  #      {api:ContextModuleItemsApiController#index List Module Items API}
  #      if items are not returned.
  #    - "content_details": Requires include['items']. Returns additional
  #      details with module items specific to their associated content items.
  #      Includes standard lock information for each item.
  #
  # @argument student_id
  #   Returns module completion information for the student with this id.
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123
  #
  # @returns Module
  def show
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@student || @current_user).find(params[:id])
      includes = Array(params[:include])
      ActiveRecord::Associations::Preloader.new(mod, content_tags: :content).run if includes.include?('items')
      prog = @student ? mod.evaluate_for(@student) : nil
      render :json => module_json(mod, @student || @current_user, session, prog, includes)
    end
  end

  # @note API Update multiple modules
  #
  # Update multiple modules in an account.
  #
  # @argument module_ids[] [Required, String]
  #   List of ids of modules to update.
  #
  # @argument event [Required, String]
  #   The action to take on each module. Must be 'delete'.
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
      modules = @context.context_modules.not_deleted.where(id: module_ids)
      return render(:json => { :message => 'no modules found' }, :status => :not_found) if modules.empty?

      completed_ids = []
      modules.each do |mod|
        case event
          when 'publish'
            unless mod.active?
              mod.publish
              mod.publish_items!
            end
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

  # @API Create a module
  #
  # Create and return a new module
  #
  # @argument module[name] [Required, String]
  #   The name of the module
  #
  # @argument module[unlock_at] [DateTime]
  #   The date the module will unlock
  #
  # @argument module[position] [Integer]
  #   The position of this module in the course (1-based)
  #
  # @argument module[require_sequential_progress] [Boolean]
  #   Whether module items must be unlocked in order
  #
  # @argument module[prerequisite_module_ids][] [String]
  #   IDs of Modules that must be completed before this one is unlocked.
  #   Prerequisite modules must precede this module (i.e. have a lower position
  #   value), otherwise they will be ignored
  #
  # @argument module[publish_final_grade] [Boolean]
  #   Whether to publish the student's final grade for the course upon
  #   completion of this module.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules \
  #       -X POST \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'module[name]=module' \
  #       -d 'module[position]=2' \
  #       -d 'module[prerequisite_module_ids][]=121' \
  #       -d 'module[prerequisite_module_ids][]=122'
  #
  # @returns Module
  def create
    if authorized_action(@context.context_modules.scoped.new, @current_user, :create)
      return render :json => {:message => "missing module parameter"}, :status => :bad_request unless params[:module]
      return render :json => {:message => "missing module name"}, :status => :bad_request unless params[:module][:name].present?

      module_parameters = params[:module].slice(:name, :unlock_at, :require_sequential_progress, :publish_final_grade)

      @module = @context.context_modules.build(module_parameters)

      if ids = params[:module][:prerequisite_module_ids]
        @module.prerequisites = ids.map{|id| "module_#{id}"}.join(',')
      end
      @module.workflow_state = 'unpublished'

      if @module.save && set_position
        render :json => module_json(@module, @current_user, session, nil)
      else
        render :json => @module.errors, :status => :bad_request
      end
    end
  end

  # @API Update a module
  #
  # Update and return an existing module
  #
  # @argument module[name] [String]
  #   The name of the module
  #
  # @argument module[unlock_at] [DateTime]
  #   The date the module will unlock
  #
  # @argument module[position] [Integer]
  #   The position of the module in the course (1-based)
  #
  # @argument module[require_sequential_progress] [Boolean]
  #   Whether module items must be unlocked in order
  #
  # @argument module[prerequisite_module_ids][] [String]
  #   IDs of Modules that must be completed before this one is unlocked
  #   Prerequisite modules must precede this module (i.e. have a lower position
  #   value), otherwise they will be ignored
  #
  # @argument module[publish_final_grade] [Boolean]
  #   Whether to publish the student's final grade for the course upon
  #   completion of this module.
  #
  # @argument module[published] [Boolean]
  #   Whether the module is published and visible to students
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id> \
  #       -X PUT \
  #       -H 'Authorization: Bearer <token>' \
  #       -d 'module[name]=module' \
  #       -d 'module[position]=2' \
  #       -d 'module[prerequisite_module_ids][]=121' \
  #       -d 'module[prerequisite_module_ids][]=122'
  #
  # @returns Module
  def update
    @module = @context.context_modules.not_deleted.find(params[:id])
    if authorized_action(@module, @current_user, :update)
      return render :json => {:message => "missing module parameter"}, :status => :bad_request unless params[:module]
      module_parameters = params[:module].slice(:name, :unlock_at, :require_sequential_progress, :publish_final_grade)

      if ids = params[:module][:prerequisite_module_ids]
        if ids.blank?
          module_parameters[:prerequisites] = []
        else
          module_parameters[:prerequisites] = ids.map{|id| "module_#{id}"}.join(',')
        end
      end

      if params[:module].has_key?(:published)
        if value_to_boolean(params[:module][:published])
          @module.publish
          @module.publish_items!
        else
          @module.unpublish
        end
      end

      if @module.update_attributes(module_parameters) && set_position
        render :json => module_json(@module, @current_user, session, nil)
      else
        render :json => @module.errors, :status => :bad_request
      end
    end
  end

  # @API Delete module
  #
  # Delete a module
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/modules/<module_id> \
  #       -X Delete \
  #       -H 'Authorization: Bearer <token>'
  #
  # @returns Module
  def destroy
    @module = @context.context_modules.not_deleted.find(params[:id])
    if authorized_action(@module, @current_user, :delete)
      @module.destroy
      render :json => module_json(@module, @current_user, session, nil)
    end
  end

  def set_position
    return true unless @module && params[:module][:position]

    if @module.insert_at(params[:module][:position].to_i)
      # see ContextModulesController#reorder
      @context.touch
      @context.context_modules.not_deleted.each{|m| m.save_without_touching_context }
      @context.touch

      @module.reload
      return true
    else
      @module.errors.add(:position, t(:invalid_position, "Invalid position"))
      return false
    end
  end

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
