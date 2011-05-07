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

class ContentImportsController < ApplicationController
  before_filter :require_context
  add_crumb("Content Imports") { |c| c.send :named_context_url, c.instance_variable_get("@context"), :context_imports_url }
  before_filter { |c| c.active_tab = "home" }
  
  def intro
    if authorized_action(@context, @current_user, :update)
    end
  end
  
  def files
    if authorized_action(@context, @current_user, :update)
    end
  end
  
  def quizzes
    if authorized_action(@context, @current_user, :update)
      @quizzes = @context.quizzes.active
    end
  end
  
  def migrate_content
    if authorized_action(@context, @current_user, :manage)
      if params[:migration_settings]

        if params[:migration_settings][:question_bank_name] == 'new_question_bank'
          params[:migration_settings][:question_bank_name] = params[:new_question_bank_name]
        end

        if params[:content_migration_id].present?
          @migration = ContentMigration.for_context(@context).find_by_id(params[:content_migration_id])
        end
        @migration ||= ContentMigration.new
        @migration.context = @context
        @migration.user = @current_user
        @migration.update_migration_settings(params[:migration_settings])
        
        if @migration.save
          if params[:export_file_enabled] == '1'
            att = Attachment.new
            att.context = @migration
            att.uploaded_data = params[:export_file]
            att.save
            @migration.attachment = att
          end
          @migration.export_content
          render :text => @migration.to_json
        else
          render :text => @migration.errors.to_json, :status => :bad_request
        end
      else
        @plugins = Canvas::Plugin.all_for_tag(:export_system)
        @select_options = @plugins.map{|p|[p.settings[:select_text], p.id]}
        @pending_migrations = ContentMigration.find_all_by_context_id(@context.id).any?
        render
      end
    end
  end
  
  def migrate_content_choose
    if authorized_action(@context, @current_user, :manage)
      @content_migration = ContentMigration.for_context(@context).find(params[:id]) #)_all_by_context_id_and_context_type(@context.id, @context.class.to_s).last
      if @content_migration.progress && @content_migration.progress >= 100
        flash[:notice] = "That extraction has already been imported into the course"
        redirect_to named_context_url(@context, :context_url)
        return
      end

      
      if request.xhr?
        if @content_migration && @content_migration.overview_attachment
          stream = @content_migration.overview_attachment.open()
          send_file_or_data(stream, :type => :json, :disposition => 'inline')
        else
          logger.error "There was no overview.json file for this content_migration."
          render :text => {:success=>false}.to_json
        end
      end
    end
  end
  
  def migrate_content_execute
    if authorized_action(@context, @current_user, :manage)
      migration_id = params[:id] || params[:copy] && params[:copy][:content_migration_id]
      @content_migration = ContentMigration.find_by_context_id_and_context_type_and_id(@context.id, @context.class.to_s, migration_id) if migration_id.present?
      @content_migration ||= ContentMigration.find_by_context_id_and_context_type(@context.id, @context.class.to_s, :order => "id DESC")
      if request.method == :post
        @content_migration.migration_settings[:migration_ids_to_import] = params
        @content_migration.save
        @content_migration.import_content
        render :text => {:success => true}.to_json
      else
        render :json => @content_migration.to_json
      end
    end
  end
  
  def copy_course
    if authorized_action(@context, @current_user, :update)
      if params[:import_id]
        @import = CourseImport.for_course(@context, 'instructure_copy').find(params[:import_id])
        @copy_context = @import.source
        @copies = @import.added_item_codes
        @results = @import.log
        respond_to do |format|
          format.html { render :action => 'copy_course_content' }
        end
      else
        if request.format != :json
          @possible_courses = (@current_user.available_courses + @context.course_sections.active.map(&:nonxlist_course)).compact.select{|c| c.grants_right?(@current_user, session, :manage) }
          @possible_courses += @domain_root_account.all_courses if @domain_root_account.grants_right?(@current_user, session, :manage)
          @possible_courses -= [@context]
          @possible_courses = @possible_courses.compact.uniq
          course_id = params[:copy] && params[:copy][:course_id].to_i
          course_id = params[:copy][:autocomplete_course_id] if params[:copy] && params[:copy][:autocomplete_course_id] && !params[:copy][:autocomplete_course_id].empty?
          @copy_context = @possible_courses.find{|c| c.id == course_id.to_i } if course_id
          if !@copy_context
            @copy_context ||= Course.find_by_id(course_id) if course_id.present?
            @copy_context = nil if @copy_context && !@copy_context.grants_rights?(@current_user, session, :manage)
          end
        end
        @running_import = CourseImport.for_course(@context, 'instructure_copy').first
        respond_to do |format|
          format.html
          format.json { render :json => @running_import.to_json }
        end
      end
    end
  end
  
  def copy_course_content
    if authorized_action(@context, @current_user, :update)
      @copy_context = Course.find(params[:copy][:course_id]) #@current_user.available_courses.find(params[:copy][:course_id])
      @copy_context = Course.find(0) unless @copy_context.grants_right?(@current_user, nil, :manage_content)
      @import = CourseImport.create!(:import_type => "instructure_copy", :source => @copy_context, :course => @context)
      params[:copy][:import] = @import
      @copies = []
      begin
        @copies = @context.merge_in(@copy_context, params[:copy])
      rescue => e
        @import.workflow_state = 'failed'
        @import.log = {
          :message => e.to_s,
          :backtrace => e.backtrace.join("\n")
        }
        @import.save
      end
      @results = @context.merge_results || []
      respond_to do |format|
        format.html
      end
    end
  end
  
  def review
    if authorized_action(@context, @current_user, :update)
      @root_folders = Folder.root_folders(@context)
      @folders = @context.folders.active
      @assignments = @context.assignments.active
      @events = @context.calendar_events.active
      @entries = (@assignments + @events).sort_by{|e| [e.start_at || Time.parse("Jan 1 2000"), e.title]}
      @quizzes = @context.quizzes.active
    end
  end
  
  def index
    if authorized_action(@context, @current_user, :update)
      @successful = ContentMigration.successful.find_all_by_context_id(@context.id)
      @running = ContentMigration.running.find_all_by_context_id(@context.id)
      @waiting = ContentMigration.waiting.find_all_by_context_id(@context.id)
      @failed = ContentMigration.failed.find_all_by_context_id(@context.id)
    end
  end
end
