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
  before_action :require_context
  before_action { |c| c.active_tab = "home" }
  prepend_around_action :load_pseudonym_from_policy, :only => :migrate_content_upload

  include Api::V1::Course
  include ContentImportsHelper

  COPY_TYPES = %w{assignment_groups assignments context_modules
                  learning_outcomes quizzes assessment_question_banks folders
                  attachments wiki_pages discussion_topics calendar_events
                  context_external_tools learning_outcome_groups rubrics}.freeze

  # these are deprecated, but leaving them for a while so existing links get redirected
  def index
    redirect_to course_content_migrations_url(@context)
  end

  def intro
    redirect_to course_content_migrations_url(@context)
  end

  # current files UI uses this page for .zip uploads
  def files
    authorized_action(@context, @current_user, [:manage_content, :manage_files])
    js_env(return_or_context_url: return_or_context_url,
           return_to: params[:return_to])
  end

  # @API Get course copy status
  #
  # DEPRECATED: Please use the {api:ContentMigrationsController#create Content Migrations API}
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
      cm = ContentMigration.where(context_id: @context, id: params[:id]).first
      raise ActiveRecord::RecordNotFound unless cm

      respond_to do |format|
        format.json { render :json => copy_status_json(cm, @context, @current_user, session)}
      end
    end
  end


  # @API Copy course content
  #
  # DEPRECATED: Please use the {api:ContentMigrationsController#create Content Migrations API}
  #
  # Copies content from one course into another. The default is to copy all course
  # content. You can control specific types to copy by using either the 'except' option
  # or the 'only' option.
  #
  # @argument source_course [String]
  #   ID or SIS-ID of the course to copy the content from
  #
  # @argument except[] [String, "course_settings"|"assignments"|"external_tools"|"files"|"topics"|"calendar_events"|"quizzes"|"wiki_pages"|"modules"|"outcomes"]
  #   A list of the course content types to exclude, all areas not listed will
  #   be copied.
  #
  # @argument only[] [String, "course_settings"|"assignments"|"external_tools"|"files"|"topics"|"calendar_events"|"quizzes"|"wiki_pages"|"modules"|"outcomes"]
  #   A list of the course content types to copy, all areas not listed will not
  #   be copied.
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
          render :json => {"errors"=>t('errors.no_only_and_except', 'You can not use "only" and "except" options at the same time.')}, :status => :bad_request
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
      return render_unauthorized_action unless @source_course.grants_all_rights?(@current_user, :read, :read_as_admin)
      cm = ContentMigration.create!(:context => @context,
                                    :user => @current_user,
                                    :source_course => @source_course,
                                    :copy_options => copy_params,
                                    :migration_type => 'course_copy_importer',
                                    :initiated_source => api_request? ? :api : :manual)
      cm.queue_migration
      cm.workflow_state = 'created'
      render :json => copy_status_json(cm, @context, @current_user, session)
    end
  end

  private

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
    end
  end

  SELECTION_CONVERSIONS = {
          "external_tools" => "context_external_tools",
          "files" => "attachments",
          "topics" => "discussion_topics",
          "modules" => "context_modules",
          "outcomes" => "learning_outcomes"
  }.freeze
  # convert types selected in API to expected format
  def convert_to_table_name(selections)
    selections.map{|s| SELECTION_CONVERSIONS[s] || s}
  end

end
