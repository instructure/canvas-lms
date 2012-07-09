#
# Copyright (C) 2011 Instructure, Inc.
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
  before_filter :require_context  
  add_crumb(proc { t('#crumbs.modules', "Modules") }) { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_context_modules_url }
  before_filter { |c| c.active_tab = "modules" }  
  
  def index
    if authorized_action(@context, @current_user, :read)
      @modules = @context.context_modules.active
      @collapsed_modules = ContextModuleProgression.for_user(@current_user).for_modules(@modules).scoped(:select => 'context_module_id, collapsed').select{|p| p.collapsed? }.map(&:context_module_id)
      if @context.grants_right?(@current_user, session, :participate_as_student)
        return unless tab_enabled?(@context.class::TAB_MODULES)
        ContextModule.send(:preload_associations, @modules, [:context_module_progressions, :content_tags])
        @modules.each{|m| m.evaluate_for(@current_user) }
        session[:module_progressions_initialized] = true
      end
    end
  end

  def item_redirect
    if authorized_action(@context, @current_user, :read)
      @tag = @context.context_module_tags.active.include_progressions.find(params[:id])

      reevaluate_modules_if_locked(@tag)
      @progression = @tag.context_module.evaluate_for(@current_user) if @tag.context_module
      @progression.uncollapse! if @progression && @progression.collapsed != false
      content_tag_redirect(@context, @tag, :context_context_modules_url)
    end
  end
  
  def module_redirect
    if authorized_action(@context, @current_user, :read)
      @module = @context.context_modules.active.find(params[:context_module_id])
      @tags = @module.content_tags.active.include_progressions
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
      @progression.uncollapse! if @progression && @progression.collapsed != false
      content_tag_redirect(@context, @tag, :context_context_modules_url)
    end
  end

  def reevaluate_modules_if_locked(tag)
    # if the object is locked for this user, reevaluate all the modules and clear the cache so it will be checked again when loaded
    if tag.content && tag.content.respond_to?(:locked_for?)
      locked = tag.content.is_a?(WikiPage) ? tag.content.locked_for?(@context, @current_user) : tag.content.locked_for?(@current_user) 
      if locked
        @context.context_modules.each { |m| m.evaluate_for(@current_user, true, true) }
        if tag.content.respond_to?(:clear_locked_cache)
          tag.content.clear_locked_cache(@current_user)
        end
      end
    end
  end
  
  def create
    if authorized_action(@context.context_modules.new, @current_user, :create)
      @module = @context.context_modules.build
      @module.attributes = params[:context_module]
      respond_to do |format|
        if @module.save
          format.html { redirect_to named_context_url(@context, :context_context_modules_url) }
          format.json { render :json => @module.to_json(:include => :content_tags, :permissions => {:user => @current_user, :session => session}) }
        else
          format.html
          format.json { render :json => @module.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def reorder
    if authorized_action(@context.context_modules.new, @current_user, :update)
      m = @context.context_modules.active.first
      
      m.update_order(params[:order].split(","))
      # Need to invalidate the ordering cache used by context_module.rb
      @context.touch

      # I'd like to get rid of this saving every module, but we have to
      # update the list of prerequisites since a reorder can cause
      # prerequisites to no longer be valid
      @modules = @context.context_modules.active
      @modules.each{|m| m.save_without_touching_context }
      @context.touch
      
      # # Background this, not essential that it happen right away
      # ContextModule.send_later(:update_tag_order, @context)
      respond_to do |format|
        format.json { render :json => @modules.to_json }
      end
    end
  end
  
  def content_tag_assignment_data
    if authorized_action(@context, @current_user, :read)
      result = Rails.cache.fetch([ @context, "content_tag_assignment_info_all" ].cache_key) do
        info = {}
        @context.context_module_tags.active.map do |tag|
          info[tag.id] = {
            :due_date => (tag.assignment.due_at.utc.iso8601 rescue tag.content.due_at.utc.iso8601 rescue nil),
            :points_possible => (tag.assignment.points_possible rescue nil)
          }
        end
        info.to_json
      end
      render :json => result
    end
  end
  
  def prerequisites_needing_finishing_for(mod, progression, before_tag=nil)
    tags = mod.content_tags.active #.find(:all, :conditions => ['position <= ?', progression.current_position], :order => :position)
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
    code = params[:code].split("_")
    id = code.pop
    type = code.join("_").classify
    @tag = @context.context_module_tags.active.find_by_context_module_id_and_content_id_and_content_type(params[:context_module_id], id, type)
    @module = @context.context_modules.active.find(params[:context_module_id])
    @progression = @module.evaluate_for(@current_user)
    @progression.current_position ||= 0 if @progression
    res = {};
    if !@progression
    elsif @progression.locked?
      res[:locked] = true
      res[:modules] = []
      previous_modules = @context.context_modules.active.find(:all, :conditions => ['position < ?', @module.position], :order => :position)
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
    render :json => res.to_json
  end
  
  def toggle_collapse
    if authorized_action(@context, @current_user, :read)
      @module = @context.context_modules.find(params[:context_module_id])
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
        format.json { render :json => (@progression.collapsed ? @progression.to_json : @module.content_tags.active.to_json) }
      end
    end
  end
  
  def show
    @module = @context.context_modules.find(params[:id])
    respond_to do |format|
      format.html { redirect_to named_context_url(@context, :context_context_modules_url, :anchor => "module_#{params[:id]}") }
      format.json { render :json => (@module.content_tags.active.to_json) }
    end
  end
  
  def reorder_items
    @module = @context.context_modules.find(params[:context_module_id])
    if authorized_action(@module, @current_user, :update)
      order = params[:order].split(",")
      tags = @context.context_module_tags.active.find_all_by_id(order).compact
      affected_module_ids = tags.map(&:context_module_id).uniq.compact
      items = order.map{|id| tags.detect{|t| t.id == id.to_i } }.compact.uniq
      items.each_index do |idx|
        item = items[idx]
        item.position = idx
        item.context_module_id = @module.id
        item.save
      end
      ContextModule.update_all({:updated_at => Time.now.utc}, {:id => affected_module_ids})
      @context.touch
      @module.reload
      respond_to do |format|
        format.json { render :json => @module.to_json(:include => :content_tags, :permissions => {:user => @current_user, :session => session}) }
      end
    end
  end
  

  def item_details  
    if authorized_action(@context, @current_user, :read)
      code = params[:id].split("_")
      id = code.pop.to_i
      type = code.join("_").classify
      @modules = @context.context_modules.active
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
          elsif obj.is_a?(Quiz) && obj.assignment_id
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
      render :json => result.to_json
    end
  end
  
  def add_item
    @module = @context.context_modules.find(params[:context_module_id])
    if authorized_action(@module, @current_user, :update)
      @tag = @module.add_item(params[:item]) #@item)
      @module.touch
      render :json => @tag.to_json
    end
  end
  
  def remove_item
    @tag = @context.context_module_tags.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @module = @tag.context_module
      @tag.destroy
      @module.touch
      render :json => @tag.to_json
    end
  end
  
  def update_item
    @tag = @context.context_module_tags.find(params[:id])
    if authorized_action(@tag.context_module, @current_user, :update)
      @tag.title = params[:content_tag][:title] if params[:content_tag] && params[:content_tag][:title]
      @tag.url = params[:content_tag][:url] if @tag.content_type == 'ExternalUrl' && params[:content_tag] && params[:content_tag][:url]
      @tag.indent = params[:content_tag][:indent] if params[:content_tag] && params[:content_tag][:indent]
      @tag.new_tab = params[:content_tag][:new_tab] if params[:content_tag] && params[:content_tag][:new_tab]
      @tag.save
      @tag.update_asset_name! if params[:content_tag][:title]
      render :json => @tag.to_json
    end
  end

  def progressions
    if authorized_action(@context, @current_user, :read)
      if @context.context_modules.new.grants_right?(@current_user, session, :update)
        if params[:user_id] && @user = @context.students.find(params[:user_id])
          @progressions = @context.context_modules.map{|m| m.evaluate_for(@user, true, true) }
        else
          context_module_ids = @context.context_modules.scoped(:select => "id").map &:id
          @progressions = ContextModuleProgression.scoped(:conditions => {:context_module_id => context_module_ids})
        end
        render :json => @progressions.to_json
      else
        @progressions = @context.context_modules.map{|m| m.evaluate_for(@current_user, true) }
        render :json => @progressions.to_json
      end
    end
  end
  
  def update
    @module = @context.context_modules.find(params[:id])
    if authorized_action(@module, @current_user, :update)
      respond_to do |format|
        if @module.update_attributes(params[:context_module])
          format.json { render :json => @module.to_json(:include => :content_tags, :permissions => {:user => @current_user, :session => session}) }
        else
          format.json { render :json => @module.errors.to_json, :status => :bad_request }
        end
      end
    end
  end
  
  def destroy
    @module = @context.context_modules.find(params[:id])
    if authorized_action(@module, @current_user, :delete)
      @module.destroy
      respond_to do |format|
        format.html { redirect_to named_context_url(@context, :context_context_modules_url) }
        format.json { render :json => @module.to_json }
      end
    end
  end
end
