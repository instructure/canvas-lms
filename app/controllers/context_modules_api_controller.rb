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
#       // The number of items in the module
#       items_count: 10,
#
#       // The API URL to retrive this module's items
#       items_url: 'https://canvas.example.com/api/v1/modules/123/items',
#
#       items: [ ... ]
#       // The contents of this module, as an array of Module Items.
#       // (Present only if requested via include[]=items
#       //  AND the module is not deemed too large by Canvas.)
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
class ContextModulesApiController < ApplicationController
  before_filter :require_context  
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
  #
  # @argument search_term [Optional, String]
  #   The partial name of the modules (and module items, if include['items'] is
  #   specified) to match and return.
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

      includes = Array(params[:include])
      scope = ContextModule.search_by_attribute(scope, :name, params[:search_term]) unless includes.include?('items')
      modules = Api.paginate(scope, self, route)

      ContextModule.send(:preload_associations, modules, {:content_tags => :content}) if includes.include?('items')

      modules_and_progressions = if @context.grants_right?(@current_user, session, :participate_as_student)
        modules.map { |m| [m, m.evaluate_for(@current_user, true)] }
      else
        modules.map { |m| [m, nil] }
      end
      opts = {}
      if includes.include?('items') && params[:search_term].present?
        SearchTermHelper.validate_search_term(params[:search_term])
        opts[:search_term] = params[:search_term]
      end
      render :json => modules_and_progressions.map { |mod, prog| module_json(mod, @current_user, session, prog, includes, opts) }.compact
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
  #
  # @example_request
  #     curl -H 'Authorization: Bearer <token>' \
  #          https://<canvas>/api/v1/courses/222/modules/123
  #
  # @returns Module
  def show
    if authorized_action(@context, @current_user, :read)
      mod = @context.modules_visible_to(@current_user).find(params[:id])
      includes = Array(params[:include])
      ContextModule.send(:preload_associations, mod, {:content_tags => :content}) if includes.include?('items')
      prog = @context.grants_right?(@current_user, session, :participate_as_student) ? mod.evaluate_for(@current_user, true) : nil
      render :json => module_json(mod, @current_user, session, prog, includes)
    end
  end

  # @undocumented API Update multiple modules
  #
  # Update multiple modules in an account.
  #
  # @argument module_ids[] [String]
  #   List of ids of modules to update.
  #
  # @argument event [String]
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
      modules = @context.context_modules.not_deleted.find_all_by_id(module_ids)
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
  # @argument module[name] [String]
  #   The name of the module
  #
  # @argument module[unlock_at] [Optional, DateTime]
  #   The date the module will unlock
  #
  # @argument module[position] [Optional, Integer]
  #   The position of this module in the course (1-based)
  #
  # @argument module[require_sequential_progress] [Optional, Boolean]
  #   Whether module items must be unlocked in order
  #
  # @argument module[prerequisite_module_ids][] [Optional, String]
  #   IDs of Modules that must be completed before this one is unlocked.
  #   Prerequisite modules must precede this module (i.e. have a lower position
  #   value), otherwise they will be ignored
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
    if authorized_action(@context.context_modules.new, @current_user, :create)
      return render :json => {:message => "missing module parameter"}, :status => :bad_request unless params[:module]
      return render :json => {:message => "missing module name"}, :status => :bad_request unless params[:module][:name].present?

      module_parameters = params[:module].slice(:name, :unlock_at, :require_sequential_progress)

      @module = @context.context_modules.build(module_parameters)

      if ids = params[:module][:prerequisite_module_ids]
        @module.prerequisites = ids.map{|id| "module_#{id}"}.join(',')
      end
      if @domain_root_account.enable_draft?
        @module.workflow_state = 'unpublished'
      else
        @module.workflow_state = 'active'
      end

      if @module.save && set_position
        render :json => module_json(@module, @current_user, session, nil)
      else
        render :json => @module.errors.to_json, :status => :bad_request
      end
    end
  end

  # @API Update a module
  #
  # Update and return an existing module
  #
  # @argument module[name] [Optional, String]
  #   The name of the module
  #
  # @argument module[unlock_at] [Optional, DateTime]
  #   The date the module will unlock
  #
  # @argument module[position] [Optional, Integer]
  #   The position of the module in the course (1-based)
  #
  # @argument module[require_sequential_progress] [Optional, Boolean]
  #   Whether module items must be unlocked in order
  #
  # @argument module[prerequisite_module_ids][] [Optional, String]
  #   IDs of Modules that must be completed before this one is unlocked
  #   Prerequisite modules must precede this module (i.e. have a lower position
  #   value), otherwise they will be ignored
  #
  # @argument module[published] [Optional, Boolean]
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
      module_parameters = params[:module].slice(:name, :unlock_at, :require_sequential_progress)

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
        render :json => @module.errors.to_json, :status => :bad_request
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

    if @module.insert_at_position(params[:module][:position], @context.context_modules.not_deleted)
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
end
