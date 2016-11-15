#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

class ContextModulesController < ApplicationController
  include Api::V1::ContextModule

  before_filter :require_context
  add_crumb(proc { t('#crumbs.modules', "Modules") }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_context_modules_url }
  before_filter { |c| c.active_tab = "modules" }

  module ModuleIndexHelper
    include ContextModulesHelper

    def load_module_file_details
      attachment_tags = @context.module_items_visible_to(@current_user).where(content_type: 'Attachment').preload(:content => :folder)
      attachment_tags.inject({}) do |items, file_tag|
        items[file_tag.id] = {
          id: file_tag.id,
          content_id: file_tag.content_id,
          content_details: content_details(file_tag, @current_user, :for_admin => true)
        }
        items
      end
    end

    def modules_cache_key
      @modules_cache_key ||= begin
        visible_assignments = @current_user.try(:assignment_and_quiz_visibilities, @context)
        cache_key_items = [@context.cache_key, @can_edit, 'all_context_modules_draft_9', collection_cache_key(@modules), Time.zone, Digest::MD5.hexdigest(visible_assignments.to_s)]
        cache_key = cache_key_items.join('/')
        cache_key = add_menu_tools_to_cache_key(cache_key)
        cache_key = add_mastery_paths_to_cache_key(cache_key, @context, @modules, @current_user)
      end
    end

    def load_modules
      @modules = @context.modules_visible_to(@current_user)
      @collapsed_modules = ContextModuleProgression.for_user(@current_user).for_modules(@modules).pluck(:context_module_id, :collapsed).select{|cm_id, collapsed| !!collapsed }.map(&:first)

      @can_edit = can_do(@context, @current_user, :manage_content)

      modules_cache_key

      @is_student = @context.grants_right?(@current_user, session, :participate_as_student)
      @is_cyoe_on = ConditionalRelease::Service.enabled_in_context?(@context)

      @menu_tools = {}
      placements = [:assignment_menu, :discussion_topic_menu, :file_menu, :module_menu, :quiz_menu, :wiki_page_menu]
      tools = ContextExternalTool.all_tools_for(@context, placements: placements,
                                        :root_account => @domain_root_account, :current_user => @current_user).to_a
      placements.select { |p| @menu_tools[p] = tools.select{|t| t.has_placement? p} }

      module_file_details = load_module_file_details if @context.grants_right?(@current_user, session, :manage_content)
      js_env :course_id => @context.id,
        :CONTEXT_URL_ROOT => polymorphic_path([@context]),
        :FILES_CONTEXTS => [{asset_string: @context.asset_string}],
        :MODULE_FILE_DETAILS => module_file_details,
        :MODULE_FILE_PERMISSIONS => {
           usage_rights_required: @context.feature_enabled?(:usage_rights_required),
           manage_files: @context.grants_right?(@current_user, session, :manage_files)
        }
      conditional_release_js_env(includes: :active_rules)
    end
  end
  include ModuleIndexHelper

  def index
    if authorized_action(@context, @current_user, :read)
      log_asset_access([ "modules", @context ], "modules", "other")
      load_modules

      if @is_student && tab_enabled?(@context.class::TAB_MODULES)
        @modules.each{|m| m.evaluate_for(@current_user) }
        session[:module_progressions_initialized] = true
      end
    end
  end

  def choose_mastery_path
    if authorized_action(@context, @current_user, :participate_as_student)
      id = params[:id]
      item = @context.context_module_tags.not_deleted.find(params[:id])

      if item.present? && item.published? && item.context_module.published?
        rules = ConditionalRelease::Service.rules_for(@context, @current_user, item, session)
        rule = conditional_release(item, conditional_release_rules: rules)

        # locked assignments always have 0 sets, so this check makes it not return 404 if locked
        # but instead progress forward and return a warning message if is locked later on
        if rule.present? && (rule[:locked] || !rule[:selected_set_id] || rule[:assignment_sets].length > 1)
          if !rule[:locked]
            options = rule[:assignment_sets].map { |set|
              option = {
                setId: set[:id]
              }

              option[:assignments] = set[:assignments].map { |a|
                assg = assignment_json(a[:model], @current_user, session)
                assg[:assignmentId] = a[:assignment_id]
                assg
              }

              option
            }

            js_env({
              CHOOSE_MASTERY_PATH_DATA: {
                options: options,
                selectedOption: rule[:selected_set_id],
                courseId: @context.id,
                moduleId: item.context_module.id,
                itemId: id
              }
            })

            css_bundle :choose_mastery_path
            js_bundle :choose_mastery_path

            @page_title = join_title(t('Choose Assignment Set'), @context.name)

            return render :text => '', :layout => true
          else
            flash[:warning] = t('Module Item is locked.')
            return redirect_to named_context_url(@context, :context_context_modules_url)
          end
        end
      end
      return render status: 404, template: 'shared/errors/404_message'
    end
  end

  def item_redirect
    if authorized_action(@context, @current_user, :read)
      @tag = @context.context_module_tags.not_deleted.find(params[:id])

      if !(@tag.unpublished? || @tag.context_module.unpublished?) || authorized_action(@tag.context_module, @current_user, :view_unpublished_items)
        reevaluate_modules_if_locked(@tag)
        @progression = @tag.context_module.evaluate_for(@current_user) if @tag.context_module
        @progression.uncollapse! if @progression && @progression.collapsed?
        content_tag_redirect(@context, @tag, :context_context_modules_url, :modules)
      end
    end
  end

  def item_redirect_mastery_paths
    @tag = @context.context_module_tags.not_deleted.find(params[:id])

    type_controllers = {
      assignment: 'assignments',
      quiz: 'quizzes/quizzes',
      discussion_topic: 'discussion_topics'
    }

    if @tag
      if authorized_action(@tag.content, @current_user, :update)
        controller = type_controllers[@tag.content_type_class.to_sym]

        if controller.present?
          redirect_to url_for(
            controller: controller,
            action: 'edit',
            id: @tag.content_id,
            anchor: 'mastery-paths-editor',
            return_to: params[:return_to]
          )
        else
          render status: 404, template: 'shared/errors/404_message'
        end
      end
    else
      render status: 404, template: 'shared/errors/404_message'
    end
  end

  def module_redirect
    if authorized_action(@context, @current_user, :read)
      @module = @context.context_modules.not_deleted.find(params[:context_module_id])
      @tags = @module.content_tags_visible_to(@current_user)
      if params[:last]
        @tags.pop while @tags.last && @tags.last.content_type == 'ContextModuleSubHeader'
      else
        @tags.shift while @tags.first && @tags.first.content_type == 'ContextModuleSubHeader'
      end
      @tag = params[:last] ? @tags.last : @tags.first
      if !@tag
        flash[:notice] = t 'module_empty', %{There are no items in the module "%{module}"}, :module => @module.name
        redirect_to named_context_url(@context, :context_context_modules_url, :anchor => "module_#{@module.id}")
        return
      end

      reevaluate_modules_if_locked(@tag)
      @progression = @tag.context_module.evaluate_for(@current_user) if @tag && @tag.context_module
      @progression.uncollapse! if @progression && @progression.collapsed?
      content_tag_redirect(@context, @tag, :context_context_modules_url)
    end
  end

  def reevaluate_modules_if_locked(tag)
    # if the object is locked for this user, reevaluate all the modules and clear the cache so it will be checked again when loaded
    if tag.content && tag.content.respond_to?(:locked_for?)
      locked = tag.content.locked_for?(@current_user, :context => @context)
      if locked
        @context.context_modules.active.each { |m| m.evaluate_for(@current_user) }
        if tag.content.respond_to?(:clear_locked_cache)
          tag.content.clear_locked_cache(@current_user)
        end
      end
    end
  end

  def create
    if authorized_action(@context.context_modules.temp_record, @current_user, :create)
      @module = @context.context_modules.build
      @module.workflow_state = 'unpublished'
      @module.attributes = params[:context_module]
      respond_to do |format|
        if @module.save
          format.html { redirect_to named_context_url(@context, :context_context_modules_url) }
          format.json { render :json => @module.as_json(:include => :content_tags, :methods => :workflow_state, :permissions => {:user => @current_user, :session => session}) }
        else
          format.html
          format.json { render :json => @module.errors, :status => :bad_request }
        end
      end
    end
  end

  def reorder
    if authorized_action(@context.context_modules.temp_record, @current_user, :update)
      m = @context.context_modules.not_deleted.first

      m.update_order(params[:order].split(","))
      # Need to invalidate the ordering cache used by context_module.rb
      @context.touch

      # I'd like to get rid of this saving every module, but we have to
      # update the list of prerequisites since a reorder can cause
      # prerequisites to no longer be valid
      @modules = @context.context_modules.not_deleted
      @modules.each{|m| m.save_without_touching_context }
      @context.touch

      # # Background this, not essential that it happen right away
      # ContextModule.send_later(:update_tag_order, @context)
      render :json => @modules.map{ |m| m.as_json(include: :content_tags, methods: :workflow_state) }
    end
  end

  def content_tag_assignment_data
    if authorized_action(@context, @current_user, :read)
      info = {}
      now = Time.now.utc.iso8601

      all_tags = @context.module_items_visible_to(@current_user)
      user_is_admin = @context.grants_right?(@current_user, session, :read_as_admin)

      preload_assignments_and_quizzes(all_tags, user_is_admin)

      all_tags.each do |tag|
        info[tag.id] = if tag.can_have_assignment? && tag.assignment
          tag.assignment.context_module_tag_info(@current_user, @context, user_is_admin: user_is_admin)
        elsif tag.content_type_quiz?
          tag.content.context_module_tag_info(@current_user, @context, user_is_admin: user_is_admin)
        else
          {:points_possible => nil, :due_date => nil}
        end
      end
      render :json => info
    end
  end

  def prerequisites_needing_finishing_for(mod, progression, before_tag=nil)
    tags = mod.content_tags_visible_to(@current_user)
    pres = []
    tags.each do |tag|
      if req = (mod.completion_requirements || []).detect{|r| r[:id] == tag.id }
        progression.requirements_met ||= []
        if !progression.requirements_met.any?{|r| r[:id] == req[:id] && r[:type] == req[:type] }
          if !before_tag || tag.position <= before_tag.position
            pre = {
              :url => named_context_url(@context, :context_context_modules_item_redirect_url, tag.id),
              :id => tag.id,
              :context_module_id => mod.id,
              :title => tag.title
            }
            pre[:requirement] = req
            pre[:requirement_description] = ContextModule.requirement_description(req)
            pre[:available] = !progression.locked? && (!mod.require_sequential_progress || tag.position <= progression.current_position)
            pres << pre
          end
        end
      end
    end
    pres
  end
  protected :prerequisites_needing_finishing_for

  def content_tag_prerequisites_needing_finishing
    type, id = ActiveRecord::Base.parse_asset_string params[:code]
    raise ActiveRecord::RecordNotFound if id == 0
    if type == 'ContentTag'
      @tag = @context.context_module_tags.active.where(id: id).first
    else
      @tag = @context.context_module_tags.active.where(context_module_id: params[:context_module_id], content_id: id, content_type: type).first
    end
    @module = @context.context_modules.active.find(params[:context_module_id])
    @progression = @module.evaluate_for(@current_user)
    @progression.current_position ||= 0 if @progression
    res = {};
    if !@progression
    elsif @progression.locked?
      res[:locked] = true
      res[:modules] = []
      previous_modules = @context.context_modules.active.where('position<?', @module.position).order(:position).to_a
      previous_modules.reverse!
      valid_previous_modules = []
      prereq_ids = @module.prerequisites.select{|p| p[:type] == 'context_module' }.map{|p| p[:id] }
      previous_modules.each do |mod|
        if prereq_ids.include?(mod.id)
          valid_previous_modules << mod
          prereq_ids += mod.prerequisites.select{|p| p[:type] == 'context_module' }.map{|p| p[:id] }
        end
      end
      valid_previous_modules.reverse!
      valid_previous_modules.each do |mod|
        prog = mod.evaluate_for(@current_user)
        res[:modules] << {
          :id => mod.id,
          :name => mod.name,
          :prerequisites => prerequisites_needing_finishing_for(mod, prog),
          :locked => prog.locked?
        } unless prog.completed?
      end
    elsif @module.require_sequential_progress && @progression.current_position && @tag && @tag.position && @progression.current_position < @tag.position
      res[:locked] = true
      pres = prerequisites_needing_finishing_for(@module, @progression, @tag)
      res[:modules] = [{
        :id => @module.id,
        :name => @module.name,
        :prerequisites => pres,
        :locked => false
      }]
    else
      res[:locked] = false
    end
    render :json => res
  end

  def toggle_collapse
    if authorized_action(@context, @current_user, :read)
      @module = @context.modules_visible_to(@current_user).find(params[:context_module_id])
      @progression = @module.evaluate_for(@current_user) #context_module_progressions.find_by_user_id(@current_user)
      @progression ||= ContextModuleProgression.new
      if params[:collapse] == '1'
        @progression.collapsed = true
      elsif params[:collapse]
        @progression.uncollapse!
      else
        @progression.collapsed = !@progression.collapsed
      end
      @progression.save
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_context_modules_url) }
        format.json { render :json => (@progression.collapsed ? @progression : @module.content_tags_visible_to(@current_user) )}
      end
    end
  end

  def show
    @module = @context.context_modules.not_deleted.find(params[:id])
    if authorized_action @module, @current_user, :read
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_context_modules_url, :anchor => "module_#{params[:id]}") }
        format.json { render :json => @module.content_tags_visible_to(@current_user) }
      end
    end
  end

  def reorder_items
    @module = @context.context_modules.not_deleted.find(params[:context_module_id])
    if authorized_action(@module, @current_user, :update)
      order = params[:order].split(",").map{|id| id.to_i}
      tags = @context.context_module_tags.not_deleted.where(id: order)
      affected_module_ids = (tags.map(&:context_module_id) + [@module.id]).uniq.compact
      affected_items = []
      items = order.map{|id| tags.detect{|t| t.id == id.to_i } }.compact.uniq
      items.each_with_index do |item, idx|
        item.position = idx
        item.context_module_id = @module.id
        if item.changed?
          item.skip_touch = true
          item.save
          affected_items << item
        end
      end
      ContentTag.touch_context_modules(affected_module_ids)
      ContentTag.update_could_be_locked(affected_items)
      @context.touch
      @module.reload
      render :json => @module.as_json(:include => :content_tags, :methods => :workflow_state, :permissions => {:user => @current_user, :session => session})
    end
  end


  def item_details
    if authorized_action(@context, @current_user, :read)
      # namespaced models are separated by : in the url
      code = params[:id].gsub(":", "/").split("_")
      id = code.pop.to_i
      type = code.join("_").classify
      @modules = @context.modules_visible_to(@current_user)
      @tags = @context.context_module_tags.active.sort_by{|t| t.position ||= 999}
      result = {}
      possible_tags = @tags.find_all {|t| t.content_type == type && t.content_id == id }
      if possible_tags.size > 1
        # if there's more than one tag for the item, but the caller didn't
        # specify which one they want, we don't want to return any information.
        # this way the module item prev/next links won't appear with misleading navigation info.
        if params[:module_item_id]
          result[:current_item] = possible_tags.detect { |t| t.id == params[:module_item_id].to_i }
        end
      else
        result[:current_item] = possible_tags.first
        if !result[:current_item]
          obj = @context.find_asset(params[:id], [:attachment, :discussion_topic, :assignment, :quiz, :wiki_page, :content_tag])
          if obj.is_a?(ContentTag)
            result[:current_item] = @tags.detect{|t| t.id == obj.id }
          elsif obj.is_a?(DiscussionTopic) && obj.assignment_id
            result[:current_item] = @tags.detect{|t| t.content_type == 'Assignment' && t.content_id == obj.assignment_id }
          elsif obj.is_a?(Quizzes::Quiz) && obj.assignment_id
            result[:current_item] = @tags.detect{|t| t.content_type == 'Assignment' && t.content_id == obj.assignment_id }
          end
        end
      end
      result[:current_item].evaluate_for(@current_user) rescue nil
      if result[:current_item] && result[:current_item].position
        result[:previous_item] = @tags.reverse.detect{|t| t.id != result[:current_item].id && t.context_module_id == result[:current_item].context_module_id && t.position && t.position <= result[:current_item].position && t.content_type != "ContextModuleSubHeader" }
        result[:next_item] = @tags.detect{|t| t.id != result[:current_item].id && t.context_module_id == result[:current_item].context_module_id && t.position && t.position >= result[:current_item].position && t.content_type != "ContextModuleSubHeader" }
        current_module = @modules.detect{|m| m.id == result[:current_item].context_module_id}
        if current_module
          result[:previous_module] = @modules.reverse.detect{|m| (m.position || 0) < (current_module.position || 0) }
          result[:next_module] = @modules.detect{|m| (m.position || 0) > (current_module.position || 0) }
        end
      end
      render :json => result
    end
  end

  include ContextModulesHelper
  def add_item
    @module = @context.context_modules.not_deleted.find(params[:context_module_id])
    if authorized_action(@module, @current_user, :update)
      @tag = @module.add_item(params[:item])
      unless @tag.valid?
        return render :json => @tag.errors, :status => :bad_request
      end
      json = @tag.as_json
      json['content_tag'].merge!(
        publishable: module_item_publishable?(@tag),
        published: @tag.published?,
        publishable_id: module_item_publishable_id(@tag),
        unpublishable:  module_item_unpublishable?(@tag),
        graded: @tag.graded?,
        content_details: content_details(@tag, @current_user),
        assignment_id: @tag.assignment.try(:id),
        is_cyoe_able: cyoe_able?(@tag)
      )
      render json: json
    end
  end

  def remove_item
    @tag = @context.context_module_tags.not_deleted.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @module = @tag.context_module
      @tag.destroy
      render :json => @tag
    end
  end

  def update_item
    @tag = @context.context_module_tags.not_deleted.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @tag.title = params[:content_tag][:title] if params[:content_tag] && params[:content_tag][:title]
      @tag.url = params[:content_tag][:url] if %w(ExternalUrl ContextExternalTool).include?(@tag.content_type) && params[:content_tag] && params[:content_tag][:url]
      @tag.indent = params[:content_tag][:indent] if params[:content_tag] && params[:content_tag][:indent]
      @tag.new_tab = params[:content_tag][:new_tab] if params[:content_tag] && params[:content_tag][:new_tab]

      unless @tag.save
        return render :json => @tag.errors, :status => :bad_request
      end

      @tag.update_asset_name! if params[:content_tag][:title]
      render :json => @tag
    end
  end

  def progressions
    if authorized_action(@context, @current_user, :read)
      if request.format == :json
        if @context.grants_right?(@current_user, session, :view_all_grades)
          if params[:user_id] && @user = @context.students.find(params[:user_id])
            @progressions = @context.context_modules.active.map{|m| m.evaluate_for(@user) }
          else
            if @context.large_roster
              @progressions = []
            else
              context_module_ids = @context.context_modules.active.pluck(:id)
              @progressions = ContextModuleProgression.where(:context_module_id => context_module_ids).each{|p| p.evaluate }
            end
          end
        elsif @context.grants_right?(@current_user, session, :participate_as_student)
          @progressions = @context.context_modules.active.order(:id).map{|m| m.evaluate_for(@current_user) }
        else
          # module progressions don't apply, but unlock_at still does
          @progressions = @context.context_modules.active.order(:id).map do |m|
            { :context_module_progression =>
                { :context_module_id => m.id,
                  :workflow_state => (m.to_be_unlocked ? 'locked' : 'unlocked'),
                  :requirements_met => [],
                  :incomplete_requirements => [] } }
          end
        end
        render :json => @progressions
      elsif !@context.grants_right?(@current_user, session, :view_all_grades)
        @restrict_student_list = true
        student_ids = @context.observer_enrollments.for_user(@current_user).map(&:associated_user_id)
        student_ids << @current_user.id if @context.user_is_student?(@current_user)
        students = UserSearch.scope_for(@context, @current_user, {:enrollment_type => 'student'}).where(:id => student_ids)
        @visible_students = students.map { |u| user_json(u, @current_user, session) }
      end
    end
  end

  def update
    @module = @context.context_modules.not_deleted.find(params[:id])
    if authorized_action(@module, @current_user, :update)
      if params[:publish]
        @module.publish
        @module.publish_items!
      elsif params[:unpublish]
        @module.unpublish
      end
      if @module.update_attributes(params[:context_module])
        json = @module.as_json(:include => :content_tags, :methods => :workflow_state, :permissions => {:user => @current_user, :session => session})
        json['context_module']['relock_warning'] = true if @module.relock_warning?
        render :json => json
      else
        render :json => @module.errors, :status => :bad_request
      end
    end
  end

  def destroy
    @module = @context.context_modules.not_deleted.find(params[:id])
    if authorized_action(@module, @current_user, :delete)
      @module.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_context_modules_url) }
        format.json { render :json => @module.as_json(:methods => :workflow_state) }
      end
    end
  end

  private
  def preload_assignments_and_quizzes(tags, user_is_admin)
    assignment_tags = tags.select{|ct| ct.can_have_assignment?}
    return unless assignment_tags.any?
    ActiveRecord::Associations::Preloader.new.preload(assignment_tags, :content)

    content_with_assignments = assignment_tags.
      select{|ct| ct.content_type != "Assignment" && ct.content.assignment_id}.map(&:content)
    ActiveRecord::Associations::Preloader.new.preload(content_with_assignments, :assignment) if content_with_assignments.any?

    if user_is_admin && should_preload_override_data?
      assignments = assignment_tags.map(&:assignment).compact
      plain_quizzes = assignment_tags.select{|ct| ct.content.is_a?(Quizzes::Quiz) && !ct.content.assignment}.map(&:content)

      preload_has_too_many_overrides(assignments, :assignment_id)
      preload_has_too_many_overrides(plain_quizzes, :quiz_id)
      overrideables = (assignments + plain_quizzes).select{|o| !o.has_too_many_overrides}

      if overrideables.any?
        ActiveRecord::Associations::Preloader.new.preload(overrideables, :assignment_overrides)
        overrideables.each { |o| o.has_no_overrides = true if o.assignment_overrides.size == 0 }
      end
    end
  end

  def should_preload_override_data?
    key = ['preloaded_module_override_data', @context.global_asset_string, @current_user].cache_key
    # if the user has been touched we should preload all of the overrides because it's almost certain we'll need them all
    if Rails.cache.read(key)
      false
    else
      Rails.cache.write(key, true)
      true
    end
  end

  def preload_has_too_many_overrides(assignments_or_quizzes, override_column)
    # find the assignments/quizzes with too many active overrides and mark them as such
    if assignments_or_quizzes.any?
      ids = AssignmentOverride.active.where(override_column => assignments_or_quizzes).
        group(override_column).having("COUNT(*) > ?", Setting.get('assignment_all_dates_too_many_threshold', '25').to_i).
        active.pluck(override_column)

      if ids.any?
        assignments_or_quizzes.each{|o| o.has_too_many_overrides = true if ids.include?(o.id) }
      end
    end
  end
end
