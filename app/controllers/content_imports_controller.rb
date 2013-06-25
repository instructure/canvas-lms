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

# @API Courses
class ContentImportsController < ApplicationController
  before_filter :require_context, :add_imports_crumb
  before_filter { |c| c.active_tab = "home" }
  prepend_around_filter :load_pseudonym_from_policy, :only => :migrate_content_upload
  
  include Api::V1::Course

  COPY_TYPES = %w{assignment_groups assignments context_modules learning_outcomes
                quizzes assessment_question_banks folders attachments wiki_pages discussion_topics
                calendar_events context_external_tools learning_outcome_groups rubrics}

  def add_imports_crumb
    if @context.is_a?(Course)
      add_crumb(t('crumbs.content_imports', "Content Imports"), named_context_url(@context, :context_imports_url))
    end
    true
  end
  
  def intro
    authorized_action(@context, @current_user, [:manage_content, :manage_files, :manage_quizzes])
  end
  
  def files
    authorized_action(@context, @current_user, [:manage_content, :manage_files])
  end
  
  def quizzes
    if authorized_action(@context, @current_user, [:manage_content, :manage_quizzes])
      @quizzes = @context.quizzes.active
    end
  end
  
  def migrate_content
    if authorized_action(@context, @current_user, :manage_content)
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
            att.workflow_state = 'unattached_temporary'
            att.filename = params[:attachment][:filename]
            att.file_state = 'deleted'
            att.content_type = Attachment.mimetype(att.filename)
            att.save
            @migration.attachment = att
            @migration.save
            upload_params = att.ajax_upload_params(
              @current_pseudonym,
              named_context_url(@context, :context_import_upload_url, :id => @migration.id),
              named_context_url(@context, :context_import_s3_success_url, :id => @migration.id,
                                          :uuid => att.uuid, :include_host => true),
              :max_size => 5.gigabytes,
              :file_param => :export_file,
              :ssl => request.ssl?)
            render :json => upload_params
          else
            @migration.export_content
            render :json => @migration.to_json
          end
        else
          render :json => @migration.errors, :status => :bad_request
        end
      else
        @plugins = ContentMigration.migration_plugins(true)
        @select_options = @plugins.select{|p| p.settings[:migration_partial].present? }.map{|p|[p.metadata(:select_text), p.id]}
        @pending_migrations = ContentMigration.find_all_by_context_id(@context.id).any?
        render
      end
    end
  end

  def migrate_content_upload
    load_migration_and_attachment do
      if Attachment.local_storage? && params[:export_file]
        @attachment.uploaded_data = params[:export_file]
        @attachment.save
        @migration.export_content
      end
    end
  end

  def migrate_content_s3_success
    load_migration_and_attachment do
      if Attachment.s3_storage? && details = @attachment.s3object.head rescue nil
        @attachment.process_s3_details!(details)
        @migration.export_content
      end
    end
  end

  def migrate_content_choose
    if authorized_action(@context, @current_user, :manage_content)
      @content_migration = ContentMigration.for_context(@context).find(params[:id]) #)_all_by_context_id_and_context_type(@context.id, @context.class.to_s).last
      if @content_migration.workflow_state == "imported"
        flash[:notice] = t 'notices.already_imported', "That extraction has already been imported into the course"
        redirect_to named_context_url(@context, :context_url)
        return
      end

      
      if request.xhr?
        if @content_migration && @content_migration.overview_attachment
          stream = @content_migration.overview_attachment.open()
          send_file_or_data(stream, :type => :json, :disposition => 'inline')
        else
          logger.error "There was no overview.json file for this content_migration."
          render :json => {:success=>false}.to_json
        end
      end
    end
  end

  def migrate_content_execute
    if authorized_action(@context, @current_user, :manage_content)
      migration_id = params[:id] || params[:copy] && params[:copy][:content_migration_id]
      @content_migration = ContentMigration.find_by_context_id_and_context_type_and_id(@context.id, @context.class.to_s, migration_id) if migration_id.present?
      @content_migration ||= ContentMigration.find_by_context_id_and_context_type(@context.id, @context.class.to_s, :order => "id DESC")
      if request.method == :post
        @content_migration.set_date_shift_options(params[:copy] || {})
        process_migration_params
        @content_migration.migration_settings[:migration_ids_to_import] = params
        @content_migration.save
        @content_migration.import_content
        render :text => {:success => true}.to_json
      else
        render :json => @content_migration.to_json
      end
    end
  end

  def choose_content
    if authorized_action(@context, @current_user, :manage_content)
      find_source_course
      if @source_course
        respond_to do |format|
          format.html
        end
      else
        respond_to do |format|
          flash[:notice] = t('notices.choose_a_course', "Choose a course to copy")
          format.html { redirect_to course_import_choose_course_url(@context) }
        end
      end
    end
  end

  def copy_course_checklist
    if authorized_action(@context, @current_user, :manage_content)
      find_source_course
      if @source_course
        render :json => {:selection_list => render_to_string(:partial => 'copy_course_item_selection', :layout => false)}
      else
        render.html ""
      end
    end
  end

  def copy_course_finish
    if authorized_action(@context, @current_user, :manage_content)
      cm = ContentMigration.find_by_context_id_and_id(@context.id, params[:content_migration_id])
      @source_course = cm.source_course
      @copies = []
    end
  end

  def choose_course
    if authorized_action(@context, @current_user, :manage_content)
    end
  end

  def find_source_course
    if params[:source_course]
      course_id = params[:source_course].to_i
      @source_course = Course.find_by_id(course_id)
      @source_course = nil if @source_course && !@source_course.grants_rights?(@current_user, session, :manage)
    end
  end
  
  # @API Get course copy status
  #
  # Retrieve the status of a course copy
  #
  # @response_field id The unique identifier for the course copy.
  #
  # @response_field created_at The time that the copy was initiated.
  #
  # @response_field progress The progress of the copy as an integer. It is null before the copying starts, and 100 when finished.
  #
  # @response_field workflow_state The current status of the course copy. Possible values: "created", "started", "completed", "failed"
  #
  # @response_field status_url The url for the course copy status API endpoint.
  #
  # @example_response
  #   {'progress':100, 'workflow_state':'completed', 'id':257, 'created_at':'2011-11-17T16:50:06Z', 'status_url':'/api/v1/courses/9457/course_copy/257'}
  def copy_course_status
    if api_request?
      @context = api_find(Course, params[:course_id])
    end
    if authorized_action(@context, @current_user, :manage_content)
      cm = ContentMigration.find_by_context_id_and_id(@context.id, params[:id])
      raise ActiveRecord::RecordNotFound unless cm

      respond_to do |format|
        format.json { render :json => copy_status_json(cm, @context, @current_user, session)}
      end
    end
  end
  
  
  # @API Copy course content
  #
  # Copies content from one course into another. The default is to copy all course
  # content. You can control specific types to copy by using either the 'except' option
  # or the 'only' option.
  #
  # @argument source_course ID or SIS-ID of the course to copy the content from
  #
  # @argument except[] A list of the course content types to exclude, all areas not listed will be copied.
  #
  # @argument only[] A list of the course content types to copy, all areas not listed will not be copied.
  #
  # The possible items for 'except' and 'only' are: "course_settings", "assignments", "external_tools", 
  # "files", "topics", "calendar_events", "quizzes", "wiki_pages", "modules", "outcomes"
  #
  # The response is the same as the course copy status endpoint
  #
  def copy_course_content
    if api_request?
      @context = api_find(Course, params[:course_id])
    end
    
    if authorized_action(@context, @current_user, :manage_content)
      if api_request?
        @source_course = api_find(Course, params[:source_course])
        copy_params = {:everything => false}
        if params[:only] && params[:except]
          render :json => {"errors"=>t('errors.no_only_and_except', 'You can not use "only" and "except" options at the same time.')}.to_json, :status => :bad_request
          return
        elsif params[:only]
          convert_to_table_name(params[:only]).each {|o| copy_params["all_#{o}".to_sym] = true}
        elsif params[:except]
          COPY_TYPES.each {|o| copy_params["all_#{o}".to_sym] = true}
          convert_to_table_name(params[:except]).each {|o| copy_params["all_#{o}".to_sym] = false}
        else
          copy_params[:everything] = true
        end
      else
        process_migration_params
        @source_course = Course.find(params[:source_course])
        copy_params = params[:copy]
      end

      # make sure the user can copy from the source course
      return render_unauthorized_action unless @source_course.grants_rights?(@current_user, nil, :read, :read_as_admin).values.all?
      cm = ContentMigration.create!(:context => @context, :user => @current_user, :source_course => @source_course, :copy_options => copy_params)
      cm.copy_course
      render :json => copy_status_json(cm, @context, @current_user, session)
    end
  end

  def review
    if authorized_action(@context, @current_user, :manage_content)
      @root_folders = Folder.root_folders(@context)
      @folders = @context.folders.active
      @assignments = @context.assignments.active
      @events = @context.calendar_events.active
      @entries = (@assignments + @events).sort_by{|e| [e.start_at || Time.parse("Jan 1 2000"), e.title]}
      @quizzes = @context.quizzes.active
    end
  end
  
  def index
    if authorized_action(@context, @current_user, :manage_content)
      @successful = ContentMigration.successful.find_all_by_context_id(@context.id)
      @running = ContentMigration.running.find_all_by_context_id(@context.id)
      @waiting = ContentMigration.waiting.find_all_by_context_id(@context.id)
      @failed = ContentMigration.failed.find_all_by_context_id(@context.id)
    end
  end
  
  def download_archive
    if authorized_action(@context, @current_user, :manage_content)
      @migration = ContentMigration.for_context(@context).find(params[:id])
      @attachment = @migration.attachment
      
      respond_to do |format|
        if @attachment
          if Attachment.s3_storage?
            format.html { redirect_to @attachment.cacheable_s3_download_url }
          else
            cancel_cache_buster
            format.html { send_file(@attachment.full_filename, :type => @attachment.content_type, :disposition => 'attachment') }
          end
        else
          flash[:notice] = t('notices.no_archive', "There is no archive for this content migration")
          format.html { redirect_to course_import_list(@context) }
        end
      end
    end
  end

  private

  def load_migration_and_attachment
    if authorized_action(@context, @current_user, :manage_content)
      @migration = ContentMigration.for_context(@context).find(params[:id])
      @attachment = @migration.attachment
      if block_given?
        if @attachment && yield
          render :json => @attachment.to_json(:allow => :uuid, :methods => [:uuid,:readable_size,:mime_class,:currently_locked,:scribdable?]),
                 :as_text => true
        else
          render :text => "", :status => :bad_request
        end
      end
    end
  end

  def process_migration_params
    if params[:items_to_copy]
      params[:copy] ||= {}
      params[:items_to_copy].each_pair do |key, vals|
        params[:copy][key] ||= {}
        if vals && !vals.empty?
          vals.each do |val|
            params[:copy][key][val] = true
          end
        end
      end
      params.delete :items_to_copy
    end
  end

  SELECTION_CONVERSIONS = {
          "external_tools" => "context_external_tools",
          "files" => "attachments",
          "topics" => "discussion_topics",
          "modules" => "context_modules",
          "outcomes" => "learning_outcomes"
  }
  # convert types selected in API to expected format
  def convert_to_table_name(selections)
    selections.map{|s| SELECTION_CONVERSIONS[s] || s}
  end

end
