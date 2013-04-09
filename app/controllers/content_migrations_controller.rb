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

# @API Content Migrations
# @beta
#
# API for accessing content migrations and migration issues
# @object ContentMigration
#   {
#       // the unique identifier for the migration
#       id: 370663,
#
#       // the type of content migration
#       migration_type: common_cartridge_importer,
#
#       // the name of the content migration type
#       migration_type_title: "Canvas Cartridge Importer",
#
#       // API url to the content migration's issues
#       migration_issues_url: "https://example.com/api/v1/courses/1/content_migrations/1/migration_issues",
#
#       // attachment api object for the uploaded file
#       // may not be present for all migrations
#       attachment: {url:"https://example.com/api/v1/courses/1/content_migrations/1/download_archive"},
#
#       // The api endpoint for polling the current progress
#       progress_url: "https://example.com/api/v1/progress/4",
#
#       // The user who started the migration
#       user_id: 4,
#
#       // Current state of the content migration: pre_processing pre_processed running waiting_for_select completed failed
#       workflow_state: "running",
#
#       // timestamps
#       started_at: "2012-06-01T00:00:00-06:00",
#       finished_at: "2012-06-01T00:00:00-06:00",
#
#       // file uploading data, see {file:file_uploads.html File Upload Documentation} for file upload workflow
#       // This works a little differently in that all the file data is in the pre_attachment hash
#       // if there is no upload_url then there was an attachment pre-processing error, the error message will be in the message key
#       // This data will only be here after a create or update call
#       pre_attachment:{upload_url: "", message: "file exceeded quota", upload_params: {...}}
#
#   }
class ContentMigrationsController < ApplicationController
  include Api::V1::ContentMigration

  before_filter :require_context
  before_filter :require_auth

  # @API List content migrations
  #
  # Returns paginated content migrations
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [ContentMigration]
  def index
    return unless authorized_action(@context, @current_user, :manage_content)

    @migrations = Api.paginate(@context.content_migrations.order("id DESC"), self, api_v1_course_content_migration_list_url(@context))
    render :json => content_migrations_json(@migrations, @current_user, session)
  end

  # @API Get a content migration
  #
  # Returns data on an individual content migration
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations/<id> \ 
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns ContentMigration
  def show
    @content_migration = @context.content_migrations.find(params[:id])
    render :json => content_migration_json(@content_migration, @current_user, session)
  end

  # @API Create a content migration
  #
  # Create a content migration. If the migration requires a file to be uploaded
  # the actual processing of the file will start once the file upload process is completed.
  # File uploading works as described in the {file:file_uploads.html File Upload Documentation}
  # except that the values are set on a *pre_attachment* sub-hash.
  #
  # For migrations that don't require a file to be uploaded, like course copy, the
  # processing will begin as soon as the migration is created.
  #
  # You can use the {api:ProgressController#show Progress API} to track the
  # progress of the migration. The migration's progress is linked to with the
  # _progress_url_ value.
  #
  # The two general workflows are:
  #
  # If no file upload is needed:
  #
  # 1. POST to create
  # 2. Use the {api:ProgressController#show Progress} specified in _progress_url_ to monitor progress
  #
  # For file uploading:
  #
  # 1. POST to create with file info in *pre_attachment*
  # 2. Do {file:file_uploads.html file upload processing} using the data in the *pre_attachment* data
  # 3. {api:ContentMigrationsController#show GET} the ContentMigration
  # 4. Use the {api:ProgressController#show Progress} specified in _progress_url_ to monitor progress
  #
  # @argument migration_type [string] The type of the migration. Allowed values: canvas_cartridge_importer, common_cartridge_importer, course_copy_importer, zip_file_importer, qti_converter, moodle_converter
  #
  # @argument pre_attachment[name] [string] Required if uploading a file. This is the first step in uploading a file to the content migration. See the {file:file_uploads.html File Upload Documentation} for details on the file upload workflow.
  #
  # @argument pre_attachment[*] (optional) Other file upload properties, See {file:file_uploads.html File Upload Documentation}
  #
  # @argument settings[source_course_id] [string] (optional) The course to copy from for a course copy migration. (required if doing course copy)
  #
  # @argument settings[folder_id] [string] (optional) The folder to unzip the .zip file into for a zip_file_import. (required if doing .zip file upload)
  #
  # @argument settings[overwrite_quizzes] [boolean] (optional) Whether to overwrite quizzes with the same identifiers between content packages
  #
  # @argument settings[question_bank_id] [integer] (optional) The existing question bank ID to import questions into if not specified in the content package
  # @argument settings[question_bank_name] [string] (optional) The question bank to import questions into if not specified in the content package, if both bank id and name are set, id will take precedence.
  #
  # @argument date_shift_options[shift_dates] [boolean] (optional) Whether to shift dates
  # @argument date_shift_options[old_start_date] [yyyy-mm-dd] (optional) The original start date of the source content/course
  # @argument date_shift_options[old_end_date] [yyyy-mm-dd] (optional) The original end date of the source content/course
  # @argument date_shift_options[new_start_date] [yyyy-mm-dd] (optional) The new start date for the content/course
  # @argument date_shift_options[new_end_date] [yyyy-mm-dd] (optional) The new end date for the source content/course
  # @argument date_shift_options[day_substitutions][x] [integer] (optional) Move anything scheduled for day 'x' to the specified day. (0-Sunday, 1-Monday, 2-Tuesday, 3-Wednesday, 4-Thursday, 5-Friday, 6-Saturday)
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/courses/<course_id>/content_migrations' \ 
  #        -F 'migration_type=common_cartridge_importer' \ 
  #        -F 'settings[question_bank_name]=importquestions' \ 
  #        -F 'date_shift_options[old_start_date]=1999-01-01' \ 
  #        -F 'date_shift_options[new_start_date]=2013-09-01' \ 
  #        -F 'date_shift_options[old_end_date]=1999-04-15' \ 
  #        -F 'date_shift_options[new_end_date]=2013-12-15' \ 
  #        -F 'date_shift_options[day_substitutions][1]=2' \ 
  #        -F 'date_shift_options[day_substitutions][2]=3' \ 
  #        -F 'date_shift_options[shift_dates]=true' \ 
  #        -F 'pre_attachment[name]=mycourse.imscc' \ 
  #        -F 'pre_attachment[size]=12345' \ 
  #        -H 'Authorization: Bearer <token>' 
  # 
  # @returns ContentMigration
  def create
    @plugin = Canvas::Plugin.find(params[:migration_type])
    if !@plugin
      return render(:json => { :message => t('bad_migration_type', "Invalid migration_type") }, :status => :bad_request)
    end
    settings = @plugin.settings || {}
    if settings[:requires_file_upload]
      if !params[:pre_attachment] || params[:pre_attachment][:name].blank?
        return render(:json => { :message => t('must_upload_file', "File upload is required") }, :status => :bad_request)
      end
    end
    if validator = settings[:required_options_validator]
      if res = validator.has_error(params[:settings], @current_user, @context)
        return render(:json => { :message => res.respond_to?(:call) ? res.call : res }, :status => :bad_request)
      end
    end

    @content_migration = @context.content_migrations.build(:user => @current_user, :context => @context, :migration_type => params[:migration_type])
    @content_migration.workflow_state = 'created'

    update_migration
  end

  # @API Update a content migration
  #
  # Update a content migration. Takes same arguments as create except that you can't change the migration type.
  # However, changing most settings after the migration process has started will not do anything.
  # Generally updating the content migration will be used when there is a file upload problem.
  # If the first upload has a problem you can supply new _pre_attachment_ values to start the process again.
  #
  # @returns ContentMigration
  def update
    @content_migration = @context.content_migrations.find(params[:id])
    @plugin = Canvas::Plugin.find(@content_migration.migration_type)

    update_migration
  end


  protected

  def require_auth
    authorized_action(@context, @current_user, :manage_content)
  end

  def update_migration
    @content_migration.update_migration_settings(params[:settings]) if params[:settings]
    @content_migration.set_date_shift_options(params[:date_shift_options])

    params[:selective_import] = false if @plugin.settings && @plugin.settings[:no_selective_import]
    if Canvas::Plugin.value_to_boolean(params[:selective_import])
      #todo selective import options
    else
      @content_migration.migration_settings[:import_immediately] = true
      @content_migration.copy_options = {:everything => true}
      @content_migration.migration_settings[:migration_ids_to_import] = {:copy => {:everything => true}}
    end

    if @content_migration.save
      preflight_json = nil
      if params[:pre_attachment]
        @content_migration.workflow_state = 'pre_processing'
        preflight_json = api_attachment_preflight(@content_migration, request, :params => params[:pre_attachment], :check_quota => true, :do_submit_to_scribd => false, :return_json => true)
        if preflight_json[:error]
          @content_migration.workflow_state = 'pre_process_error'
        end
        @content_migration.save!
      elsif !params.has_key?(:do_not_run) || !Canvas::Plugin.value_to_boolean(params[:do_not_run])
        @content_migration.queue_migration
      end

      render :json => content_migration_json(@content_migration, @current_user, session, preflight_json)
    else
      render :json => @content_migration.errors, :status => :bad_request
    end
  end

end
