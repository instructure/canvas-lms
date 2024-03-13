# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
#
# API for accessing content migrations and migration issues
# @model ContentMigration
#     {
#       "id": "ContentMigration",
#       "description": "",
#       "properties": {
#         "id": {
#           "description": "the unique identifier for the migration",
#           "example": 370663,
#           "type": "integer"
#         },
#         "migration_type": {
#           "description": "the type of content migration",
#           "example": "common_cartridge_importer",
#           "type": "string"
#         },
#         "migration_type_title": {
#           "description": "the name of the content migration type",
#           "example": "Canvas Cartridge Importer",
#           "type": "string"
#         },
#         "migration_issues_url": {
#           "description": "API url to the content migration's issues",
#           "example": "https://example.com/api/v1/courses/1/content_migrations/1/migration_issues",
#           "type": "string"
#         },
#         "attachment": {
#           "description": "attachment api object for the uploaded file may not be present for all migrations",
#           "example": "{\"url\"=>\"https://example.com/api/v1/courses/1/content_migrations/1/download_archive\"}",
#           "type": "string"
#         },
#         "progress_url": {
#           "description": "The api endpoint for polling the current progress",
#           "example": "https://example.com/api/v1/progress/4",
#           "type": "string"
#         },
#         "user_id": {
#           "description": "The user who started the migration",
#           "example": 4,
#           "type": "integer"
#         },
#         "workflow_state": {
#           "description": "Current state of the content migration: pre_processing, pre_processed, running, waiting_for_select, completed, failed",
#           "example": "running",
#           "type": "string",
#           "allowableValues": {
#             "values": [
#               "pre_processing",
#               "pre_processed",
#               "running",
#               "waiting_for_select",
#               "completed",
#               "failed"
#             ]
#           }
#         },
#         "started_at": {
#           "description": "timestamp",
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "finished_at": {
#           "description": "timestamp",
#           "example": "2012-06-01T00:00:00-06:00",
#           "type": "datetime"
#         },
#         "pre_attachment": {
#           "description": "file uploading data, see {file:file_uploads.html File Upload Documentation} for file upload workflow This works a little differently in that all the file data is in the pre_attachment hash if there is no upload_url then there was an attachment pre-processing error, the error message will be in the message key This data will only be here after a create or update call",
#           "example": "{\"upload_url\"=>\"\", \"message\"=>\"file exceeded quota\", \"upload_params\"=>{}}",
#           "type": "string"
#         }
#       }
#     }
#
# @model Migrator
#     {
#       "id": "Migrator",
#       "description": "",
#       "properties": {
#         "type": {
#           "description": "The value to pass to the create endpoint",
#           "example": "common_cartridge_importer",
#           "type": "string"
#         },
#         "requires_file_upload": {
#           "description": "Whether this endpoint requires a file upload",
#           "example": true,
#           "type": "boolean"
#         },
#         "name": {
#           "description": "Description of the package type expected",
#           "example": "Common Cartridge 1.0/1.1/1.2 Package",
#           "type": "string"
#         },
#         "required_settings": {
#           "description": "A list of fields this system requires",
#           "example": ["source_course_id"],
#           "type": "array",
#           "items": {"type": "string"}
#         }
#       }
#     }
#
class ContentMigrationsController < ApplicationController
  include Api::V1::ContentMigration
  include Api::V1::ExternalTools
  include NewQuizzesFeaturesHelper
  include K5Mode
  include GranularPermissionEnforcement

  before_action :require_context
  before_action :authorize_action

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
    Folder.root_folders(@context) # ensure course root folder exists so file imports can run

    if Account.site_admin.feature_enabled?(:instui_for_import_page) && !api_request?
      # Only js_env used for the redesign code
      js_env COURSE_ID: @context.id
      js_env UPLOAD_LIMIT: Attachment.quota_available(@context)
      js_env QUESTION_BANKS: @context.assessment_question_banks.except(:preload).select([:title, :id]).active
      js_env(SHOW_BP_SETTINGS_IMPORT_OPTION: MasterCourses::MasterTemplate.blueprint_eligible?(@context) &&
        @context.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin) &&
        @context.account.grants_right?(@current_user, :manage_master_courses))

      # These values are used based on the same logic as ui/features/content_migrations/setup.js do.
      js_env(QUIZZES_NEXT_ENABLED: new_quizzes_enabled?)
      js_env(NEW_QUIZZES_IMPORT: new_quizzes_import_enabled?)
      js_env(NEW_QUIZZES_MIGRATION: new_quizzes_migration_enabled?)
      js_env(NEW_QUIZZES_MIGRATION_DEFAULT: new_quizzes_migration_default)
    else
      scope = @context.content_migrations.where(child_subscription_id: nil).order("id DESC")
      @migrations = Api.paginate(scope, self, api_v1_course_content_migration_list_url(@context))
      @migrations.each(&:check_for_pre_processing_timeout)
      content_migration_json_hash = content_migrations_json(@migrations, @current_user, session)

      if api_request?
        render json: content_migration_json_hash
      else # Block below should be removed when instui_for_import_page FF stops begin a thing
        @plugins = ContentMigration.migration_plugins(true).sort_by { |p| [p.metadata(:sort_order) || CanvasSort::Last, p.metadata(:select_text)] }

        options = @plugins.map { |p| { label: p.metadata(:select_text), id: p.id } }

        external_tools = Lti::ContextToolFinder.all_tools_for(@context, placements: :migration_selection, root_account: @domain_root_account, current_user: @current_user)
        options.concat(external_tools.map do |et|
          {
            id: et.asset_string,
            label: et.label_for("migration_selection", I18n.locale)
          }
        end)

        js_env EXTERNAL_TOOLS: external_tools_json(external_tools, @context, @current_user, session)
        js_env UPLOAD_LIMIT: Attachment.quota_available(@context)
        js_env SELECT_OPTIONS: options
        js_env QUESTION_BANKS: @context.assessment_question_banks.except(:preload).select([:title, :id]).active
        js_env COURSE_ID: @context.id
        js_env CONTENT_MIGRATIONS: content_migration_json_hash
        js_env(OLD_START_DATE: datetime_string(@context.start_at, :verbose))
        js_env(OLD_END_DATE: datetime_string(@context.conclude_at, :verbose))

        js_env(SHOW_SELECT: should_show_course_copy_dropdown)
        js_env(CONTENT_MIGRATIONS_EXPIRE_DAYS: ContentMigration.expire_days)
        js_env(QUIZZES_NEXT_ENABLED: new_quizzes_enabled?)
        js_env(NEW_QUIZZES_IMPORT: new_quizzes_import_enabled?)
        js_env(NEW_QUIZZES_MIGRATION: new_quizzes_migration_enabled?)
        js_env(NEW_QUIZZES_MIGRATION_DEFAULT: new_quizzes_migration_default)
        js_env(SHOW_SELECTABLE_OUTCOMES_IN_IMPORT: @domain_root_account.feature_enabled?("selectable_outcomes_in_course_copy"))
        js_env(BLUEPRINT_ELIGIBLE_IMPORT: MasterCourses::MasterTemplate.blueprint_eligible?(@context))
        js_env(SHOW_BP_SETTINGS_IMPORT_OPTION: MasterCourses::MasterTemplate.blueprint_eligible?(@context) &&
          @context.account.grants_any_right?(@current_user, session, :manage_courses, :manage_courses_admin) &&
          @context.account.grants_right?(@current_user, :manage_master_courses))
        set_tutorial_js_env
      end
    end
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
    @content_migration.check_for_pre_processing_timeout
    render json: content_migration_json(@content_migration, @current_user, session, nil, params[:include])
  end

  def migration_plugin_supported?(plugin)
    Array(plugin.default_settings && plugin.default_settings[:valid_contexts]).include?(@context.class.to_s)
  end
  private :migration_plugin_supported?

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
  # @argument migration_type [Required, String]
  #   The type of the migration. Use the
  #   {api:ContentMigrationsController#available_migrators Migrator} endpoint to
  #   see all available migrators. Default allowed values:
  #   canvas_cartridge_importer, common_cartridge_importer,
  #   course_copy_importer, zip_file_importer, qti_converter, moodle_converter
  #
  # @argument pre_attachment[name] [String]
  #   Required if uploading a file. This is the first step in uploading a file
  #   to the content migration. See the {file:file_uploads.html File Upload
  #   Documentation} for details on the file upload workflow.
  #
  # @argument pre_attachment[*]
  #   Other file upload properties, See {file:file_uploads.html File Upload
  #   Documentation}
  #
  # @argument settings[file_url] [string] A URL to download the file from. Must not require authentication.
  #
  # @argument settings[content_export_id] [String]
  #   The id of a ContentExport to import. This allows you to import content previously exported from Canvas
  #   without needing to download and re-upload it.
  #
  # @argument settings[source_course_id] [String]
  #   The course to copy from for a course copy migration. (required if doing
  #   course copy)
  #
  # @argument settings[folder_id] [String]
  #   The folder to unzip the .zip file into for a zip_file_import.
  #  (required if doing .zip file upload)
  #
  # @argument settings[overwrite_quizzes] [Boolean]
  #   Whether to overwrite quizzes with the same identifiers between content
  #   packages.
  #
  # @argument settings[question_bank_id] [Integer]
  #   The existing question bank ID to import questions into if not specified in
  #   the content package.
  #
  # @argument settings[question_bank_name] [String]
  #   The question bank to import questions into if not specified in the content
  #   package, if both bank id and name are set, id will take precedence.
  #
  # @argument settings[insert_into_module_id] [Integer]
  #   The id of a module in the target course. This will add all imported items
  #   (that can be added to a module) to the given module.
  #
  # @argument settings[insert_into_module_type] [String,"assignment"|"discussion_topic"|"file"|"page"|"quiz"]
  #   If provided (and +insert_into_module_id+ is supplied),
  #   only add objects of the specified type to the module.
  #
  # @argument settings[insert_into_module_position] [Integer]
  #   The (1-based) position to insert the imported items into the course
  #   (if +insert_into_module_id+ is supplied). If this parameter
  #   is omitted, items will be added to the end of the module.
  #
  # @argument settings[move_to_assignment_group_id] [Integer]
  #   The id of an assignment group in the target course. If provided, all
  #   imported assignments will be moved to the given assignment group.
  #
  # @argument settings[importer_skips] [Optional,Array,"all_course_settings"|"visibility_settings"]
  #   Set of importers to skip, even if otherwise selected by migration settings.
  #
  # @argument settings[import_blueprint_settings] [Boolean]
  #   Import the "use as blueprint course" setting as well as the list of locked items
  #   from the source course or package. The destination course must not be associated
  #   with an existing blueprint course and cannot have any student or observer enrollments.
  #
  # @argument date_shift_options[shift_dates] [Boolean]
  #   Whether to shift dates in the copied course
  #
  # @argument date_shift_options[old_start_date] [Date]
  #   The original start date of the source content/course
  #
  # @argument date_shift_options[old_end_date] [Date]
  #   The original end date of the source content/course
  #
  # @argument date_shift_options[new_start_date] [Date]
  #   The new start date for the content/course
  #
  # @argument date_shift_options[new_end_date] [Date]
  #   The new end date for the source content/course
  #
  # @argument date_shift_options[day_substitutions][X] [Integer]
  #   Move anything scheduled for day 'X' to the specified day. (0-Sunday,
  #   1-Monday, 2-Tuesday, 3-Wednesday, 4-Thursday, 5-Friday, 6-Saturday)
  #
  # @argument date_shift_options[remove_dates] [Boolean]
  #   Whether to remove dates in the copied course. Cannot be used
  #   in conjunction with *shift_dates*.
  #
  # @argument selective_import [Boolean]
  #   If set, perform a selective import instead of importing all content.
  #   The migration will identify the contents of the package and then stop
  #   in the +waiting_for_select+ workflow state. At this point, use the
  #   {api:ContentMigrationsController#content_list List items endpoint}
  #   to enumerate the contents of the package, identifying the copy
  #   parameters for the desired content. Then call the
  #   {api:ContentMigrationsController#update Update endpoint} and provide these
  #   copy parameters to start the import.
  #
  # @argument select [Optional, Hash, "folders"|"files"|"attachments"|"quizzes"|"assignments"|"announcements"|"calendar_events"|"discussion_topics"|"modules"|"module_items"|"pages"|"rubrics"]
  #   For +course_copy_importer+ migrations, this parameter allows you to select
  #   the objects to copy without using the +selective_import+ argument and
  #   +waiting_for_select+ state as is required for uploaded imports (though that
  #   workflow is also supported for course copy migrations).
  #   The keys are object types like 'files', 'folders', 'pages', etc. The value
  #   for each key is a list of object ids. An id can be an integer or a string.
  #   Multiple object types can be selected in the same call.
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
    @plugin = find_migration_plugin params[:migration_type]

    unless @plugin
      return render(json: { message: t("bad_migration_type", "Invalid migration_type") }, status: :bad_request)
    end
    unless migration_plugin_supported?(@plugin)
      return render(json: { message: t("unsupported_migration_type", "Unsupported migration_type for context") }, status: :bad_request)
    end

    settings = @plugin.settings || {}
    if settings[:requires_file_upload] &&
       params.dig(:pre_attachment, :name).blank? &&
       params.dig(:settings, :file_url).blank? &&
       params.dig(:settings, :content_export_id).blank?
      return render(json: { message: t("File upload, file_url, or content_export_id is required") }, status: :bad_request)
    end

    source_course = lookup_sis_source_course
    if (validator = settings[:required_options_validator]) &&
       (res = validator.has_error(params[:settings], @current_user, @context))
      return render(json: { message: res.respond_to?(:call) ? res.call : res }, status: :bad_request)
    end

    @content_migration = @context.content_migrations.build(
      user: @current_user,
      context: @context,
      migration_type: params[:migration_type],
      initiated_source: (in_app? ? :api_in_app : :api)
    )
    @content_migration.workflow_state = "created"
    @content_migration.source_course = source_course if source_course

    update_migration
  end

  # @API Update a content migration
  #
  # Update a content migration. Takes same arguments as {api:ContentMigrationsController#create create} except that you
  # can't change the migration type. However, changing most settings after the
  # migration process has started will not do anything. Generally updating the
  # content migration will be used when there is a file upload problem, or when
  # importing content selectively. If the first upload has a problem you can
  # supply new _pre_attachment_ values to start the process again.
  #
  # @returns ContentMigration
  def update
    @content_migration = @context.content_migrations.find(params[:id])
    @content_migration.check_for_pre_processing_timeout
    @plugin = find_migration_plugin @content_migration.migration_type
    lookup_sis_source_course
    update_migration
  end

  def lookup_sis_source_course
    if params.key?(:settings) && params[:settings].key?(:source_course_id)
      course = api_find(Course, params[:settings][:source_course_id])
      params[:settings][:source_course_id] = course.id
      course
    end
  end
  private :lookup_sis_source_course

  # @API List Migration Systems
  #
  # Lists the currently available migration types. These values may change.
  #
  # @returns [Migrator]
  def available_migrators
    systems = ContentMigration.migration_plugins(true).select { |sys| migration_plugin_supported?(sys) }
    json = systems.map do |p|
      {
        type: p.id,
        requires_file_upload: !!p.settings[:requires_file_upload],
        name: p.meta["select_text"].call,
        required_settings: p.settings[:required_settings] || []
      }
    end

    render json:
  end

  # @API List items for selective import
  #
  # Enumerates the content available for selective import in a tree structure. Each node provides
  # a +property+ copy argument that can be supplied to the {api:ContentMigrationsController#update Update endpoint}
  # to selectively copy the content associated with that tree node and its children. Each node may also
  # provide a +sub_items_url+ or an array of +sub_items+ which you can use to obtain copy parameters
  # for a subset of the resources in a given node.
  #
  # If no +type+ is sent you will get a list of the top-level sections in the content. It will look something like this:
  #
  #   [{
  #     "type": "course_settings",
  #     "property": "copy[all_course_settings]",
  #     "title": "Course Settings"
  #   },
  #   {
  #     "type": "context_modules",
  #     "property": "copy[all_context_modules]",
  #     "title": "Modules",
  #     "count": 5,
  #     "sub_items_url": "http://example.com/api/v1/courses/22/content_migrations/77/selective_data?type=context_modules"
  #   },
  #   {
  #     "type": "assignments",
  #     "property": "copy[all_assignments]",
  #     "title": "Assignments",
  #     "count": 2,
  #     "sub_items_url": "http://localhost:3000/api/v1/courses/22/content_migrations/77/selective_data?type=assignments"
  #   }]
  #
  # When a +type+ is provided, nodes may be further divided via +sub_items+. For example, using +type=assignments+
  # results in a node for each assignment group and a sub_item for each assignment, like this:
  #
  #   [{
  #     "type": "assignment_groups",
  #     "title": "An Assignment Group",
  #     "property": "copy[assignment_groups][id_i855cf145e5acc7435e1bf1c6e2126e5f]",
  #     "sub_items": [{
  #         "type": "assignments",
  #         "title": "Assignment 1",
  #         "property": "copy[assignments][id_i2102a7fa93b29226774949298626719d]"
  #     }, {
  #         "type": "assignments",
  #         "title": "Assignment 2",
  #         "property": "copy[assignments][id_i310cba275dc3f4aa8a3306bbbe380979]"
  #     }]
  #   }]
  #
  #
  # To import the items corresponding to a particular tree node, use the +property+ as a parameter to the
  # {api:ContentMigrationsController#update Update endpoint} and assign a value of 1, for example:
  #
  #   copy[assignments][id_i310cba275dc3f4aa8a3306bbbe380979]=1
  #
  # You can include multiple copy parameters to selectively import multiple items or groups of items.
  #
  # @argument type ["context_modules"|"assignments"|"quizzes"|"assessment_question_banks"|"discussion_topics"|"wiki_pages"|"context_external_tools"|"tool_profiles"|"announcements"|"calendar_events"|"rubrics"|"groups"|"learning_outcomes"|"attachments"]
  #   The type of content to enumerate.
  #
  # @returns list of content items
  def content_list
    @content_migration = @context.content_migrations.find(params[:id])
    base_url = api_v1_course_content_migration_selective_data_url(@context, @content_migration)
    formatter = Canvas::Migration::Helpers::SelectiveContentFormatter.new(@content_migration,
                                                                          base_url,
                                                                          global_identifiers: @content_migration.use_global_identifiers?)

    unless formatter.valid_type?(params[:type])
      return render json: { message: "unsupported migration type" }, status: :bad_request
    end

    render json: formatter.get_content_list(params[:type])
  end

  # @API Get asset id mapping
  #
  # Given a complete course copy or blueprint import content migration, return a mapping of asset ids
  # from the source course to the destination course that were copied in this migration or an earlier one
  # with the same course pair and migration_type (course copy or blueprint).
  #
  # The returned object's keys are asset types as they appear in API URLs (+announcements+, +assignments+,
  # +discussion_topics+, +files+, +module_items+, +modules+, +pages+, and +quizzes+). The values are a mapping
  # from id in source course to id in destination course for objects of this type.
  #
  # @example_request
  #
  #     curl https://<canvas>/api/v1/courses/<course_id>/content_migrations/<id>/asset_id_mapping \
  #         -H 'Authorization: Bearer <token>'
  #
  # @example_response
  #
  #    {
  #      "assignments": {"13": "740", "14": "741"},
  #      "discussion_topics": {"15": "743", "16": "744"}
  #    }
  #
  def asset_id_mapping
    content_migration = @context.content_migrations.find(params[:id])
    return render json: { message: "Migration is incomplete" }, status: :bad_request unless content_migration.imported?
    return render json: { message: "Migration is not course copy or blueprint" }, status: :bad_request unless content_migration.source_course_id.present?

    render json: content_migration.asset_id_mapping
  end

  protected

  def authorize_action
    enforce_granular_permissions(
      @context,
      overrides: [:manage_content],
      actions: {
        index: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        show: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        available_migrators: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        content_list: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS,
        create: [:manage_course_content_add],
        update: [:manage_course_content_edit],
        asset_id_mapping: RoleOverride::GRANULAR_MANAGE_COURSE_CONTENT_PERMISSIONS
      }
    )
  end

  def find_migration_plugin(name)
    if name.include?("context_external_tool")
      plugin = Canvas::Plugin.new(name)
      plugin.meta[:settings] = { requires_file_upload: true, worker: "CCWorker", valid_contexts: %w[Course] }.with_indifferent_access
      plugin
    else
      Canvas::Plugin.find(name)
    end
  end

  def update_migration
    @content_migration.update_migration_settings(params[:settings]) if params[:settings]
    date_shift_params = params[:date_shift_options] ? params[:date_shift_options].to_unsafe_h : {}
    @content_migration.set_date_shift_options(date_shift_params)

    params[:selective_import] = false if @plugin.settings && @plugin.settings[:no_selective_import]
    if Canvas::Plugin.value_to_boolean(params[:selective_import])
      @content_migration.migration_settings[:import_immediately] = false
      if @plugin.settings[:skip_conversion_step]
        # Mark the migration as 'waiting_for_select' since it doesn't need a conversion
        # and is selective import
        @content_migration.workflow_state = "exported"
        params[:do_not_run] = true
      end
    elsif params[:select] && params[:migration_type] == "course_copy_importer"
      copy_options = ContentMigration.process_copy_params(params[:select]&.to_unsafe_h,
                                                          global_identifiers: @content_migration.use_global_identifiers?,
                                                          for_content_export: true)

      @content_migration.migration_settings[:migration_ids_to_import] ||= {}
      @content_migration.migration_settings[:migration_ids_to_import][:copy] = copy_options
      @content_migration.copy_options = copy_options
    elsif params[:copy]
      copy_options = ContentMigration.process_copy_params(params[:copy]&.to_unsafe_h,
                                                          global_identifiers: @content_migration.use_global_identifiers?)
      @content_migration.migration_settings[:migration_ids_to_import] ||= {}
      @content_migration.migration_settings[:migration_ids_to_import][:copy] = copy_options
      @content_migration.copy_options = copy_options
    else
      @content_migration.migration_settings[:import_immediately] = true
      @content_migration.copy_options = { everything: true }
      @content_migration.migration_settings[:migration_ids_to_import] = { copy: { everything: true } }
    end

    if @content_migration.save
      preflight_json = nil
      if params[:pre_attachment]
        @content_migration.workflow_state = "pre_processing"
        preflight_json = api_attachment_preflight(@content_migration, request, params: params[:pre_attachment], check_quota: true, return_json: true)
        if preflight_json[:error]
          @content_migration.workflow_state = "pre_process_error"
        end
        @content_migration.save!
        @content_migration.reset_job_progress
      else
        return false if params.dig(:settings, :content_export_id).present? && !link_content_export_attachment

        if !params.key?(:do_not_run) || !Canvas::Plugin.value_to_boolean(params[:do_not_run])
          @content_migration.shard.activate do
            @content_migration.queue_migration(@plugin)
          end
        end
      end

      render json: content_migration_json(@content_migration, @current_user, session, preflight_json)
    else
      render json: @content_migration.errors, status: :bad_request
    end
  end

  def should_show_course_copy_dropdown
    if @current_user.adminable_accounts.any?
      false # assume that if they're an account admin they're probably managing so many courses it's not worth it to even try the count
    else
      course_count = Shard.with_each_shard(@current_user.in_region_associated_shards) { @current_user.manageable_courses(true).count }.sum
      course_count <= 100
    end
  end

  def link_content_export_attachment
    ret = false
    export = ContentExport.find_by(id: params[:settings][:content_export_id])
    if export&.grants_right?(@current_user, session, :read)
      if export.workflow_state == "exported" && export.attachment
        @content_migration.attachment = export.attachment.clone_for(@content_migration)
        ret = true
      else
        render(json: { message: "content export is incomplete" }, status: :bad_request)
      end
    else
      render(json: { message: "invalid content export" }, status: :bad_request)
    end
    @content_migration.workflow_state = "pre_process_error" unless ret
    @content_migration.save!
    ret
  end
end
