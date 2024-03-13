# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

class ContentMigration < ActiveRecord::Base
  include Workflow
  include HtmlTextHelper
  include Rails.application.routes.url_helpers
  include CanvasOutcomesHelper

  belongs_to :context, polymorphic: [:course, :account, :group, { context_user: "User" }]
  validate :valid_date_shift_options
  belongs_to :user
  belongs_to :attachment
  belongs_to :overview_attachment, class_name: "Attachment"
  belongs_to :exported_attachment, class_name: "Attachment"
  belongs_to :asset_map_attachment, class_name: "Attachment", optional: true
  belongs_to :source_course, class_name: "Course"
  belongs_to :root_account, class_name: "Account"
  has_one :content_export
  has_many :migration_issues, dependent: :destroy
  has_many :quiz_migration_alerts, as: :migration, inverse_of: :migration, dependent: :destroy
  has_one :job_progress, class_name: "Progress", as: :context, inverse_of: :context
  serialize :migration_settings, yaml: { permitted_classes: [Symbol, Class] }
  cattr_accessor :export_file_path
  before_save :assign_quiz_migration_limitation_alert
  before_save :set_started_at_and_finished_at
  after_save :handle_import_in_progress_notice
  after_save :check_for_blocked_migration
  before_create :set_root_account_id

  DATE_FORMAT = "%m/%d/%Y"

  attr_accessor :outcome_to_id_map,
                :attachment_path_id_lookup,
                :last_module_position,
                :skipped_master_course_items,
                :copied_external_outcome_map
  attr_writer :imported_migration_items

  has_a_broadcast_policy

  workflow do
    state :created
    state :queued
    # The pre_process states can be used by individual plugins as needed
    state :pre_processing
    state :pre_processed
    state :pre_process_error
    state :exporting
    state :exported
    state :importing
    state :imported
    state :failed
  end

  def self.migration_plugins(exclude_hidden = false)
    plugins = Canvas::Plugin.all_for_tag(:export_system)
    exclude_hidden ? plugins.reject { |p| p.meta[:hide_from_users] } : plugins
  end

  set_policy do
    given do |user, session|
      context.grants_any_right?(user, session, *RoleOverride::GRANULAR_FILE_PERMISSIONS)
    end
    can :read
  end

  def trigger_live_events!
    # Trigger live events for the source course and migration
    Canvas::LiveEventsCallbacks.after_update(context, context.saved_changes)
    Canvas::LiveEventsCallbacks.after_update(self, saved_changes)

    # Trigger live event for new quizzes if needed
    if initiated_source == :new_quizzes
      Canvas::LiveEvents.quizzes_next_migration_urls_complete(
        {
          original_course_uuid: source_course.uuid,
          new_course_uuid: context.uuid,
          domain: context.root_account&.domain(ApplicationController.test_cluster_name),
          resource_map_url: asset_map_url(generate_if_needed: true),
          migrated_urls_content_migration_id: global_id
        }
      )
    end

    # Trigger live events for all updated/created records
    imported_migration_items.each do |imported_item|
      next unless LiveEventsObserver.observed_classes.include? imported_item.class
      next if started_at.blank? || imported_item.created_at.blank?

      if imported_item.created_at > started_at
        Canvas::LiveEventsCallbacks.after_create(imported_item)
      else
        Canvas::LiveEventsCallbacks.after_update(imported_item, imported_item.saved_changes)
      end
    end
  end

  def set_started_at_and_finished_at
    if workflow_state_changed?
      if pre_processing? || exporting? || importing?
        self.started_at ||= Time.now.utc
      end
      if failed? || imported?
        self.finished_at ||= Time.now.utc
      end
    end
  end

  def assign_quiz_migration_limitation_alert
    if workflow_state_changed? && imported? && quizzes_next_migration? &&
       NewQuizzesFeaturesHelper.new_quizzes_bank_migrations_enabled?(context)
      context.create_or_update_quiz_migration_alert(user_id, self)
    end
  end

  def quota_context
    context
  end

  def migration_settings
    read_or_initialize_attribute(:migration_settings, {}.with_indifferent_access)
  end

  # this is needed by Attachment#clone_for, which is used to allow a ContentExport to be directly imported
  def attachments
    Attachment.where(id: attachment_id)
  end

  def update_migration_settings(new_settings)
    new_settings.each do |key, val|
      migration_settings[key] = val
    end
  end

  def import_immediately?
    !!migration_settings[:import_immediately]
  end

  def content_export
    if persisted? && !association(:content_export).loaded? && source_course_id && Shard.shard_for(source_course_id) != shard
      association(:content_export).target = Shard.shard_for(source_course_id).activate { ContentExport.where(content_migration_id: self).first }
    end
    super
  end

  def converter_class=(c_class)
    migration_settings[:converter_class] = c_class
  end

  def converter_class
    migration_settings[:converter_class]
  end

  def strand=(s)
    migration_settings[:strand] = s
  end

  def strand
    migration_settings[:strand]
  end

  def initiated_source
    migration_settings[:initiated_source] || :manual
  end

  def initiated_source=(value)
    migration_settings[:initiated_source] = value
  end

  def n_strand
    account_identifier = root_account.try(:global_id) || "global"
    type = for_master_course_import? ? "master_course" : initiated_source
    ["migrations:import_content", "#{type}_#{account_identifier}"]
  end

  def migration_ids_to_import=(val)
    migration_settings[:migration_ids_to_import] = val
    set_date_shift_options val[:copy]
  end

  def zip_path=(val)
    migration_settings[:export_archive_path] = val
  end

  def zip_path
    (migration_settings || {})[:export_archive_path]
  end

  def question_bank_name=(name)
    if (name = name&.strip) != ""
      migration_settings[:question_bank_name] = name
    end
  end

  def question_bank_name
    migration_settings[:question_bank_name]
  end

  def question_bank_id=(bank_id)
    migration_settings[:question_bank_id] = bank_id
  end

  def question_bank_id
    migration_settings[:question_bank_id]
  end

  def course_archive_download_url=(url)
    migration_settings[:course_archive_download_url] = url
  end

  def skip_job_progress=(val)
    if val
      migration_settings[:skip_job_progress] = true
    else
      migration_settings.delete(:skip_job_progress)
    end
  end

  def skip_job_progress
    !!migration_settings[:skip_job_progress]
  end

  def root_account
    return super if root_account_id

    context.root_account rescue nil
  end

  def migration_type
    read_attribute(:migration_type) || migration_settings["migration_type"]
  end

  def plugin_type
    if (plugin = Canvas::Plugin.find(migration_type))
      plugin.metadata(:select_text) || plugin.name
    else
      t(:unknown, "Unknown")
    end
  end

  def canvas_import?
    migration_settings[:worker_class] == CC::Importer::Canvas::Converter.name
  end

  # add todo/error/warning issue to the import. user_message is what will be
  # displayed to the end user.
  # type must be one of: :todo, :warning, :error
  #
  # The possible opts keys are:
  #
  # error_message - an admin-only error message
  # exception - an exception object
  # error_report_id - the id to an error report
  # fix_issue_html_url - the url to send the user to to fix problem
  #
  ISSUE_TYPE_TO_ERROR_LEVEL_MAP = {
    todo: :info,
    warning: :warn,
    error: :error
  }.freeze

  def add_issue(user_message, type, opts = {})
    mi = migration_issues.build(issue_type: type.to_s, description: user_message)
    if opts[:error_report_id]
      mi.error_report_id = opts[:error_report_id]
    elsif opts[:exception]
      level = ISSUE_TYPE_TO_ERROR_LEVEL_MAP[type]
      er = Canvas::Errors.capture_exception(:content_migration, opts[:exception], level)[:error_report]
      mi.error_report_id = er
    end
    mi.error_message = opts[:error_message]
    mi.fix_issue_html_url = opts[:fix_issue_html_url]

    # prevent duplicates
    if migration_issues.where(mi.attributes.slice(
                                "issue_type", "description", "error_message", "fix_issue_html_url"
                              )).any?
      mi.delete
    else
      mi.save!
    end

    mi
  end

  def add_todo(user_message, opts = {})
    add_issue(user_message, :todo, opts)
  end

  def add_error(user_message, opts = {})
    level = opts.fetch(:issue_level, :error)
    add_issue(user_message, level, opts)
  end

  def add_warning(user_message, opts = {})
    Rails.logger.warn("Migration warning: #{user_message}: #{opts.inspect}")
    unless opts.is_a? Hash
      # convert deprecated behavior to new
      exception_or_info = opts
      opts = {}
      if exception_or_info.is_a?(Exception)
        opts[:exception] = exception_or_info
      else
        opts[:error_message] = exception_or_info
      end
    end
    add_issue(user_message, :warning, opts)
  end

  def add_unique_warning(key, warning, opts = {})
    @added_warnings ||= Set.new
    return if @added_warnings.include?(key) # only add it once

    @added_warnings << key
    add_warning(warning, opts)
  end

  def add_import_warning(item_type, item_name, warning)
    item_name = CanvasTextHelper.truncate_text(item_name || "", max_length: 150)
    add_warning(t("errors.import_error", "Import Error:") + " #{item_type} - \"#{item_name}\"", warning)
  end

  def fail_with_error!(exception_or_info, error_message: nil, issue_level: :error)
    opts = { issue_level: }
    if exception_or_info.is_a?(Exception)
      opts[:exception] = exception_or_info
    else
      opts[:error_message] = exception_or_info
    end
    message = error_message || t(:unexpected_error, "There was an unexpected error, please contact support.")
    add_error(message, opts)
    self.workflow_state = :failed
    job_progress.fail if job_progress && !skip_job_progress
    save
    update_master_migration("failed") if for_master_course_import?
    resolve_content_links! # don't leave placeholders
  end

  # deprecated warning format
  def old_warnings_format
    migration_issues.map do |mi|
      message = mi.error_report_id ? "ErrorReport:#{mi.error_report_id}" : mi.error_message
      [mi.description, message]
    end
  end

  def warnings
    old_warnings_format.map(&:first)
  end

  # This will be called by the files api after the attachment finishes uploading
  def file_upload_success_callback(att)
    if att.file_state == "available"
      self.attachment = att
      migration_issues.delete_all if migration_issues.any?
      self.workflow_state = :pre_processed
      save
      queue_migration
    else
      self.workflow_state = :pre_process_error
      add_warning(t("bad_attachment", "The file was not successfully uploaded."))
    end
  end

  def reset_job_progress(wf_state = :queued)
    return if skip_job_progress

    self.progress = 0
    if job_progress
      p = job_progress
    else
      p = shard.activate { Progress.new(context: self, tag: "content_migration") }
      self.job_progress = p
    end
    p.workflow_state = wf_state
    p.completion = 0
    p.user = user
    p.save!
    p
  end

  def queue_migration(plugin = nil, retry_count: 0, expires_at: nil, priority: Delayed::LOW_PRIORITY)
    reset_job_progress unless plugin && plugin.settings[:skip_initial_progress]

    expires_at ||= Setting.get("content_migration_job_expiration_hours", "48").to_i.hours.from_now
    return if blocked_by_current_migration?(plugin, retry_count, expires_at)

    migration_issues.delete_all
    set_default_settings

    plugin ||= Canvas::Plugin.find(migration_type)
    if plugin
      queue_opts = { priority:,
                     max_attempts: 1,
                     expires_at: }
      if strand
        queue_opts[:strand] = strand
      else
        queue_opts[:n_strand] = n_strand
      end

      if plugin.settings[:import_immediately] || (workflow_state == "exported" && !plugin.settings[:skip_conversion_step])
        # it's ready to be imported
        self.workflow_state = :importing
        save
        delay(**queue_opts.merge(on_permanent_failure: :fail_with_error!)).import_content
      else
        # find worker and queue for conversion
        begin
          worker_class = Canvas::Migration::Worker.const_get(plugin.settings["worker"])
          self.workflow_state = :exporting
          save
          self.class.connection.after_transaction_commit do
            Delayed::Job.enqueue(worker_class.new(id), **queue_opts)
          end
        rescue NameError
          self.workflow_state = "failed"
          message = "The migration plugin #{migration_type} doesn't have a worker."
          migration_settings[:last_error] = message
          Canvas::Errors.capture_exception(:content_migration, $ERROR_INFO)
          logger.error message
          save
        end
      end
    else
      self.workflow_state = "failed"
      message = "No migration plugin of type #{migration_type} found."
      migration_settings[:last_error] = message
      logger.error message
      save
    end
  end
  alias_method :export_content, :queue_migration

  def blocked_by_current_migration?(plugin, retry_count, expires_at)
    return false if migration_type == "zip_file_importer"

    running_cutoff = Setting.get("content_migration_job_block_hours", "4").to_i.hours.ago # at some point just let the jobs keep going

    if context && context.content_migrations
                         .where(workflow_state: %w[created queued pre_processing pre_processed exporting importing]).where("id < ?", id)
                         .where("started_at > ?", running_cutoff).exists?

      # there's another job already going so punt

      if retry_count > 5
        fail_with_error!(I18n.t("Blocked by running migration"))
      else
        self.workflow_state = :queued
        save

        run_at = Setting.get("content_migration_requeue_delay_minutes", "60").to_i.minutes.from_now
        # if everything goes right, we'll queue it right away after the currently running one finishes
        # but if something goes catastropically wrong, then make sure we recheck it eventually
        job = delay(ignore_transaction: true, run_at:).queue_migration(
          plugin, retry_count: retry_count + 1, expires_at:
        )

        if job_progress
          job_progress.delayed_job_id = job.id
          job_progress.save!
        end
      end

      true
    else
      false
    end
  end

  def set_default_settings
    if context.respond_to?(:root_account) &&
       (account = context.root_account) &&
       (default_ms = account.settings[:default_migration_settings])
      self.migration_settings = default_ms.merge(migration_settings).with_indifferent_access
    end

    unless migration_settings.key?(:overwrite_quizzes)
      migration_settings[:overwrite_quizzes] = for_course_copy? || for_master_course_import? || (migration_type && migration_type == "canvas_cartridge_importer")
    end
    migration_settings.reverse_merge!(prefer_existing_tools: true) if migration_type == "common_cartridge_importer" # default to true

    check_quiz_id_prepender
  end

  def process_domain_substitutions(url)
    unless @domain_substitution_map
      @domain_substitution_map = {}
      (migration_settings[:domain_substitution_map] || {}).each do |k, v|
        @domain_substitution_map[k.to_s] = v.to_s # ensure strings
      end
    end

    @domain_substitution_map.each do |from_domain, to_domain|
      if url.start_with?(from_domain)
        return url.sub(from_domain, to_domain)
      end
    end

    url
  end

  def check_quiz_id_prepender
    return unless context.respond_to?(:assessment_questions)

    if !migration_settings[:id_prepender] && (!migration_settings[:overwrite_questions] || !migration_settings[:overwrite_quizzes])
      migration_settings[:id_prepender] = id
    end
  end

  def to_import(val)
    migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && migration_settings[:migration_ids_to_import][:copy][val]
  end

  def import_everything?
    return true unless migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && !migration_settings[:migration_ids_to_import][:copy].empty?
    return true if is_set?(to_import(:everything))
    return true if copy_options && is_set?(copy_options[:everything])

    false
  end

  def original_id_for(mig_id)
    return nil unless mig_id.is_a?(String)

    prefix = "#{migration_settings[:id_prepender]}_"
    return nil unless mig_id.start_with? prefix

    mig_id[prefix.length..]
  end

  def import_object?(asset_type, mig_id)
    return false unless mig_id
    return true if import_everything?

    return true if is_set?(to_import("all_#{asset_type}"))

    return false unless to_import(asset_type).present?

    return true if (orig_id = original_id_for(mig_id)) && is_set?(to_import(asset_type)[orig_id])

    is_set?(to_import(asset_type)[mig_id])
  end

  def import_object!(asset_type, mig_id)
    return if import_everything?

    migration_settings[:migration_ids_to_import][:copy][asset_type] ||= {}
    migration_settings[:migration_ids_to_import][:copy][asset_type][mig_id] = "1"
  end

  def is_set?(option)
    Canvas::Plugin.value_to_boolean option
  end

  def capture_job_id
    job = Delayed::Worker.current_job
    return false unless job

    migration_settings[:job_ids] ||= []
    return false if migration_settings[:job_ids].include?(job.id)

    migration_settings[:job_ids] << job.id
    true
  end

  def import_content
    reset_job_progress(:running) unless import_immediately?
    self.workflow_state = :importing
    capture_job_id
    save

    Lti::Asset.opaque_identifier_for(context)

    all_files_path = nil
    begin
      data = nil
      if for_master_course_import?
        master_course_subscription.load_tags! # load child content tags
        master_course_subscription.master_template.preload_restrictions!

        data = JSON.parse(exported_attachment.open, max_nesting: 50)
        data = prepare_data(data)

        # handle deletions before files are copied
        deletions = data["deletions"].presence
        process_master_deletions(deletions.except("LearningOutcome", "AssignmentGroup")) if deletions # wait until after the import to do LearningOutcomes and AssignmentGroups

        # copy the attachments
        source_export = ContentExport.find(migration_settings[:master_course_export_id])
        if source_export.selective_export?
          # load in existing attachments to path resolution map
          file_mig_ids = source_export.settings[:referenced_file_migration_ids]
          if file_mig_ids.present?
            # ripped from copy_attachments_from_course
            root_folder_name = Folder.root_folders(context).first.name + "/"
            context.attachments.where(migration_id: file_mig_ids).each do |file|
              add_attachment_path(file.full_display_path.gsub(/\A#{root_folder_name}/, ""), file.migration_id)
            end
          end
        end
        # sync the existing folders first in case someone did something weird like deleted and replaced a folder in the same sync
        MasterCourses::FolderHelper.update_folder_names_and_states(context, source_export)
        context.copy_attachments_from_course(source_export.context, content_export: source_export, content_migration: self)
        MasterCourses::FolderHelper.recalculate_locked_folders(context)
      else
        @exported_data_zip = download_exported_data
        @zip_file = Zip::File.open(@exported_data_zip.path)
        @exported_data_zip.close
        data = JSON.parse(@zip_file.read("course_export.json"), max_nesting: 50)
        data = prepare_data(data)

        if @zip_file.find_entry("all_files.zip")
          # the file importer needs an actual file to process
          all_files_path = create_all_files_path(@exported_data_zip.path)
          @zip_file.extract("all_files.zip", all_files_path)
          data["all_files_export"]["file_path"] = all_files_path
        else
          data["all_files_export"]["file_path"] = nil
        end
        @zip_file.close
      end

      migration_settings[:migration_ids_to_import] ||= { copy: {} }

      import!(data)

      process_master_deletions(deletions.slice("LearningOutcome", "AssignmentGroup")) if deletions

      unless import_immediately?
        update_import_progress(100)
      end
      if for_master_course_import?
        update_master_migration("completed")
      end
    rescue => e
      self.workflow_state = :failed
      er_id = Canvas::Errors.capture_exception(:content_migration, e)[:error_report]
      migration_settings[:last_error] = "ErrorReport:#{er_id}"
      logger.error e
      save
      update_master_migration("failed") if for_master_course_import?
      raise e
    ensure
      File.delete(all_files_path) if all_files_path && File.exist?(all_files_path)
      clear_migration_data
    end
  end
  alias_method :import_content_without_send_later, :import_content

  def import!(data)
    return import_quizzes_next!(data) if quizzes_next_migration?

    Importers.content_importer_for(context_type)
             .import_content(
               context,
               data,
               migration_settings[:migration_ids_to_import],
               self
             )
  end

  def quizzes_next_migration?
    context.instance_of?(Course) &&
      context.feature_enabled?(:quizzes_next) &&
      migration_settings[:import_quizzes_next]
  end

  def quizzes_next_banks_migration?
    quizzes_next_migration? && Account.site_admin.feature_enabled?(:new_quizzes_bank_migrations)
  end

  def import_quizzes_next!(data)
    quizzes2_importer =
      QuizzesNext::Importers::CourseContentImporter.new(data, self)
    quizzes2_importer.import_content(
      migration_settings[:migration_ids_to_import]
    )
  end

  def master_migration
    @master_migration ||= shard.activate { MasterCourses::MasterMigration.find(migration_settings[:master_migration_id]) }
  end

  def update_master_migration(state)
    master_migration.update_import_state!(self, state)
  end

  def master_course_subscription
    return unless for_master_course_import?

    @master_course_subscription ||= shard.activate { MasterCourses::ChildSubscription.find(child_subscription_id) }
  end

  def prepare_data(data)
    data = data.with_indifferent_access if data.is_a? Hash
    Utf8Cleaner.recursively_strip_invalid_utf8!(data, true)
    data["all_files_export"] ||= {}
    data
  end

  def copy_options
    migration_settings[:copy_options]
  end

  def copy_options=(options)
    migration_settings[:copy_options] = options
    set_date_shift_options options
  end

  def for_course_copy?
    migration_type == "course_copy_importer" || for_master_course_import?
  end

  def should_skip_import?(content_importer)
    migration_settings[:importer_skips]&.include?(content_importer)
  end

  def for_master_course_import?
    migration_type == "master_course_import"
  end

  def add_skipped_item(item)
    @skipped_master_course_items ||= Set.new
    item = item.migration_id if item.is_a?(MasterCourses::ChildContentTag)
    @skipped_master_course_items << item
  end

  def process_master_deletions(deletions)
    deletions.each_key do |klass|
      next unless MasterCourses::CONTENT_TYPES_FOR_DELETIONS.include?(klass)

      mig_ids = deletions[klass]
      item_scope = case klass
                   when "Attachment"
                     context.attachments.not_deleted.where(migration_id: mig_ids)
                   when "CoursePace"
                     context.course_paces.where(migration_id: mig_ids)
                   else
                     klass.constantize.where(context_id: context, context_type: "Course", migration_id: mig_ids)
                          .where.not(workflow_state: "deleted")
                   end
      item_scope.each do |content|
        child_tag = master_course_subscription.content_tag_for(content)
        skip_item = child_tag.downstream_changes.any? && !content.editing_restricted?(:any)
        outcome, link = get_outcome_and_link(content, context)
        content_is_outcome = !outcome.nil? && !link.nil?
        if content.is_a?(AssignmentGroup) && !skip_item && content.assignments.active.exists?
          skip_item = true # don't delete an assignment group if an assignment is left (either they added one or changed one so it was skipped)
        end

        if skip_item
          Rails.logger.debug("skipping deletion sync for #{content.asset_string} due to downstream changes #{child_tag.downstream_changes}")
          add_skipped_item(child_tag)
        elsif content_is_outcome && outcome_has_results?(outcome, context)
          Rails.logger.debug { "skipping deletion sync for #{content.asset_string} due to there are Learning Outcomes Results" }
          add_skipped_item(child_tag)
        elsif content_is_outcome && outcome_has_active_alignments?(link, outcome, context)
          Rails.logger.debug { "skipping deletion sync for #{content.asset_string} due to there are active Alignments to Content" }
          add_skipped_item(child_tag)
        else
          Rails.logger.debug("syncing deletion of #{content.asset_string} from master course")
          content.skip_downstream_changes! if content.respond_to?(:skip_downstream_changes!)
          content.destroy
        end
      end
    end
  end

  def get_outcome_and_link(content, context)
    outcome = nil
    link = nil
    if content.is_a?(LearningOutcome)
      outcome = content
      context_type = context.is_a?(Course) ? "Course" : "Account"
      link = ContentTag.find_by(content_id: outcome.id, content_type: "LearningOutcome", associated_asset_type: "LearningOutcomeGroup", context_id: context.id, context_type:)
    elsif content.is_a?(ContentTag) && content.content_type == "LearningOutcome"
      link = content
      outcome = LearningOutcome.find_by(id: content.content_id, context_type: "Account")
    end
    [outcome, link]
  end

  def outcome_has_active_alignments?(link, outcome, context)
    !link.can_destroy? || outcome_has_alignments?(outcome, context)
  end

  def outcome_has_results?(outcome, context)
    return true if outcome.learning_outcome_results.where("workflow_state <> 'deleted' AND context_type='Course' AND context_code='course_#{context.id}'").count > 0

    outcome_has_authoritative_results?(outcome, context)
  end

  def check_cross_institution
    return unless context.is_a?(Course)

    data = context.full_migration_hash
    return unless data

    source_root_account_uuid = data[:course] && data[:course][:root_account_uuid]
    @cross_institution = source_root_account_uuid && source_root_account_uuid != context.root_account.uuid
  end

  def cross_institution?
    @cross_institution
  end

  def find_source_course_for_import
    return unless context.is_a?(Course)

    data = context.full_migration_hash[:context_info]
    return unless data.is_a?(Hash)

    course_id = data[:course_id]
    account_global_id = data[:root_account_id]
    account_uuid = data[:root_account_uuid]
    return unless course_id && account_global_id && account_uuid

    possible_root_account = Account.find_by(id: account_global_id)
    real_root_account = possible_root_account if possible_root_account&.uuid == account_uuid
    if Object.const_defined?(:AccountDomain) && !real_root_account
      domain = data[:canvas_domain]
      possible_root_account = domain && AccountDomain.find_cached(domain)&.account
      real_root_account = possible_root_account if possible_root_account&.uuid == account_uuid
    end

    if real_root_account
      self.source_course_id = Shard.global_id_for(course_id, real_root_account.shard)
    end

    source_course_id
  end

  def set_date_shift_options(opts)
    if opts && (Canvas::Plugin.value_to_boolean(opts[:shift_dates]) || Canvas::Plugin.value_to_boolean(opts[:remove_dates]))
      migration_settings[:date_shift_options] = opts.slice(:shift_dates, :remove_dates, :old_start_date, :old_end_date, :new_start_date, :new_end_date, :day_substitutions, :time_zone)
    end
  end

  def date_shift_options
    migration_settings[:date_shift_options]
  end

  def valid_date_shift_options
    if date_shift_options && Canvas::Plugin.value_to_boolean(date_shift_options[:shift_dates]) && Canvas::Plugin.value_to_boolean(date_shift_options[:remove_dates])
      errors.add(:date_shift_options, t("errors.cannot_shift_and_remove", "cannot specify shift_dates and remove_dates simultaneously"))
    end
  end

  scope :for_context, ->(context) { where(context_id: context, context_type: context.class.to_s) }

  scope :successful, -> { where(workflow_state: "imported") }
  scope :running, -> { where(workflow_state: ["exporting", "importing"]) }
  scope :waiting, -> { where(workflow_state: "exported") }
  scope :failed, -> { where(workflow_state: ["failed", "pre_process_error"]) }

  def complete?
    %w[imported failed pre_process_error].include?(workflow_state)
  end

  def download_exported_data
    raise "No exported data to import" unless exported_attachment

    config = ConfigFile.load("external_migration") || {}
    @exported_data_zip = exported_attachment.open(
      temp_folder: config[:data_folder]
    )
    @exported_data_zip
  end

  def create_all_files_path(temp_path)
    "#{temp_path}_all_files.zip"
  end

  def clear_migration_data
    @zip_file&.close
    @zip_file = nil
  end

  def finished_converting
    # TODO: finish progress if selective
  end

  # expects values between 0 and 100 for the conversion process
  def update_conversion_progress(prog)
    if import_immediately?
      fast_update_progress(prog * 0.5)
    else
      fast_update_progress(prog)
    end
  end

  # expects values between 0 and 100 for the import process
  def update_import_progress(prog)
    if import_immediately?
      fast_update_progress(50 + (prog * 0.5))
    else
      fast_update_progress(prog)
    end
  end

  def progress
    return nil if workflow_state == "created"

    mig_prog = read_attribute(:progress) || 0
    if for_course_copy?
      # this is for a course copy so it needs to combine the progress of the export and import
      # The export will count for 40% of progress
      # The importing step (so the value of progress on this object)will be 60%
      mig_prog *= 0.6

      if content_export
        export_prog = content_export.progress || 0
        mig_prog += export_prog * 0.4
      end
    end

    mig_prog
  end

  def fast_update_progress(val)
    reset_job_progress unless job_progress
    unless skip_job_progress
      if val == 100
        job_progress.completion = 100
        job_progress.workflow_state = "completed"
        job_progress.save!
      else
        job_progress.update_completion!(val)
      end
    end
    # Until this progress is phased out
    self.progress = val
    ContentMigration.where(id: self).update_all(progress: val)
  end

  def html_converter
    @html_converter ||= CanvasImportedHtmlConverter.new(self)
  end

  def convert_html(*args, **keyword_args)
    html_converter.convert(*args, **keyword_args)
  end

  def convert_text(text)
    format_message(text || "")[0]
  end

  delegate :resolve_content_links!, to: :html_converter

  def add_warning_for_missing_content_links(type, field, missing_links, fix_issue_url)
    add_warning(t(:missing_content_links_title, "Missing links found in imported content") + " - #{type} #{field}",
                { error_message: "#{type} #{field} - " + t(:missing_content_links_message,
                                                           "The following references could not be resolved:") + " " + missing_links.join(", "),
                  fix_issue_html_url: fix_issue_url })
  end

  UPLOAD_TIMEOUT = 1.hour
  def check_for_pre_processing_timeout
    if pre_processing? && (updated_at.utc + UPLOAD_TIMEOUT) < Time.now.utc
      add_error(t(:upload_timeout_error, "The file upload process timed out."))
      self.workflow_state = :failed
      job_progress.fail if job_progress && !skip_job_progress
      save
    end
  end

  # maps the key in the copy parameters hash to the asset string prefix
  # (usually it's just .singularize; weird names needing special casing go here :P)
  def self.asset_string_prefix(key)
    case key
    when "quizzes"
      "quizzes:quiz"
    when "announcements"
      "discussion_topic"
    else
      key.singularize
    end
  end

  def self.collection_name(key)
    key = key.to_s
    case key
    when "modules"
      "context_modules"
    when "module_items"
      "content_tags"
    when "pages"
      "wiki_pages"
    when "files"
      "attachments"
    else
      key
    end
  end

  def use_global_identifiers?
    if content_export
      content_export.global_identifiers?
    elsif source_course
      source_course.content_exports.temp_record.can_use_global_identifiers?
    else
      false
    end
  end

  # strips out the "id_" prepending the migration ids in the form
  # also converts arrays of migration ids (or real ids for course exports) into the old hash format
  def self.process_copy_params(hash, for_content_export: false, return_asset_strings: false, global_identifiers: false)
    return {} if hash.blank?

    process_key = if return_asset_strings
                    ->(asset_string) { asset_string }
                  else
                    ->(asset_string) { CC::CCHelper.create_key(asset_string, global: global_identifiers) }
                  end
    new_hash = {}

    hash.each do |key, value|
      key = collection_name(key)
      case value
      when Hash # e.g. second level in :copy => {:context_modules => {:id_100 => true, etc}}
        new_sub_hash = {}

        value.each do |sub_key, sub_value|
          if for_content_export
            new_sub_hash[process_key.call(sub_key)] = sub_value
          elsif sub_key.is_a?(String) && sub_key.start_with?("id_")
            new_sub_hash[sub_key.sub("id_", "")] = sub_value
          else
            new_sub_hash[sub_key] = sub_value
          end
        end

        new_hash[key] = new_sub_hash
      when Array
        # e.g. :select => {:context_modules => [100, 101]} for content exports
        # or :select => {:context_modules => [blahblahblah, blahblahblah2]} for normal migration ids
        sub_hash = {}
        if for_content_export
          asset_type = asset_string_prefix(key.to_s)
          value.each do |id|
            sub_hash[process_key.call("#{asset_type}_#{id}")] = "1"
          end
        else
          value.each do |id|
            sub_hash[id] = "1"
          end
        end
        new_hash[key] = sub_hash
      else
        new_hash[key] = value
      end
    end
    new_hash
  end

  def imported_migration_items
    @imported_migration_items_hash ||= {}
    @imported_migration_items_hash.values.map(&:values).flatten
  end

  def imported_migration_items_hash(klass = nil)
    @imported_migration_items_hash ||= {}
    return @imported_migration_items_hash unless klass

    @imported_migration_items_hash[klass.name] ||= {}
  end

  def imported_migration_items_by_class(klass)
    imported_migration_items_hash(klass).values
  end

  def imported_migration_items_for_insert_type
    import_type = migration_settings[:insert_into_module_type]
    if import_type.present?
      class_name = self.class.import_class_name(import_type)
      imported_migration_items_hash[class_name] ||= {}
      imported_migration_items_hash[class_name].values
    else
      imported_migration_items
    end
  end

  def self.import_class_name(import_type)
    prefix = asset_string_prefix(collection_name(import_type.pluralize))
    ActiveRecord::Base.convert_class_name(prefix)
  end

  def find_imported_migration_item(klass, migration_id)
    imported_migration_items_hash(klass)[migration_id]
  end

  def add_imported_item(item, key: item.migration_id)
    imported_migration_items_hash(item.class)[key] = item
  end

  def add_attachment_path(path, migration_id)
    self.attachment_path_id_lookup ||= {}
    self.attachment_path_id_lookup[path] = migration_id
  end

  def add_external_tool_translation(migration_id, target_tool, custom_fields)
    @external_tool_translation_map ||= {}
    @external_tool_translation_map[migration_id] = [target_tool.id, custom_fields]
  end

  def find_external_tool_translation(migration_id)
    @external_tool_translation_map && migration_id && @external_tool_translation_map[migration_id]
  end

  def handle_import_in_progress_notice
    return unless context.is_a?(Course) && is_set?(migration_settings[:import_in_progress_notice])

    if (just_created || (saved_change_to_workflow_state? && %w[created queued].include?(workflow_state_before_last_save))) &&
       %w[pre_processing pre_processed exporting importing].include?(workflow_state)
      context.add_content_notice(:import_in_progress, 4.hours)
    elsif saved_change_to_workflow_state? && %w[pre_process_error exported imported failed].include?(workflow_state)
      context.remove_content_notice(:import_in_progress)
    end
  end

  def check_for_blocked_migration
    if saved_change_to_workflow_state? &&
       %w[pre_process_error exported imported failed].include?(workflow_state) &&
       context &&
       (next_cm = context.content_migrations.where(workflow_state: "queued").order(:id).first) &&
       (job_id = next_cm.job_progress.try(:delayed_job_id)) &&
       (job = Delayed::Job.where(id: job_id, locked_at: nil).first)
      job.run_at = Time.now # it's okay to try it again now
      job.save
    end
  end

  def set_root_account_id
    self.root_account_id ||=
      case context
      when Course, Group
        context.root_account_id
      when Account
        context.resolved_root_account_id
      when User
        0 # root account id unknown, use dummy root account id
      end
    Account.ensure_dummy_root_account if root_account_id == 0
  end

  def notification_link_anchor
    "!/blueprint/blueprint_subscriptions/#{child_subscription_id}/#{id}"
  end

  ASSET_ID_MAP_TYPES = %w[Assignment Announcement Attachment ContentTag ContextModule DiscussionTopic Quizzes::Quiz WikiPage].freeze

  MIGRATION_DATA_FIELDS = {
    "WikiPage" => %i[url current_lookup_id],
    "Attachment" => %i[media_entry_id]
  }.freeze

  def migration_data_fields_for(asset_type)
    MIGRATION_DATA_FIELDS[asset_type] || []
  end

  def add_asset_pair_to_mapping(mapping, key, mig_id, src_asset_fields, dest_asset_fields)
    # mig_ids are md5 hashes (eg they have 32 digits), so there should be zero overlap with
    # the src_ids which are DB primary keys or global_ids and they can safely be stored on the same
    # hash.
    #
    src_asset_fields[:id] = src_asset_fields[:id].to_s if src_asset_fields[:id]
    dest_asset_fields[:id] = dest_asset_fields[:id].to_s

    src_id = src_asset_fields[:id]
    dest_id = dest_asset_fields[:id]

    mapping[key][src_id] = dest_id if src_id.present?

    return unless asset_map_v2?

    mapping[key][mig_id] = {
      source: src_asset_fields,
      destination: dest_asset_fields
    }
  end

  def asset_id_mapping
    return nil unless imported? || importing?

    mapping = {}
    master_template = migration_type == "master_course_import" &&
                      master_course_subscription&.master_template
    global_ids = master_template.present? || use_global_identifiers?

    ASSET_ID_MAP_TYPES.each do |asset_type|
      mig_id_to_dest_id = {}
      scope = nil
      klass = asset_type.constantize
      next unless klass.column_names.include? "migration_id"

      key = Context.api_type_name(klass)

      has_attached_assignment = klass.column_names.include?("assignment_id")
      fields = [*migration_data_fields_for(asset_type)]
      fields.push(:assignment_id) if has_attached_assignment
      context.shard.activate do
        scope = klass.select(:id, :migration_id, *fields)
        scope = scope.where(context:).where.not(migration_id: nil)
        scope = scope.only_discussion_topics if asset_type == "DiscussionTopic"
      end

      scope.each do |o|
        mig_id_to_dest_id[o.migration_id.to_s] = {}
        mig_id_to_dest_id[o.migration_id.to_s][:id] = o.id
        mig_id_to_dest_id[o.migration_id.to_s][:shell_id] = o.assignment_id if has_attached_assignment && o.assignment_id

        migration_data_fields_for(asset_type).each do |field|
          mig_id_to_dest_id[o.migration_id.to_s][field] = o.send(field)
        end
      end

      next if mig_id_to_dest_id.empty?

      mapping[key] ||= {}
      unless source_course.present?
        mig_id_to_dest_id.each do |mig_id, mig_fields|
          add_asset_pair_to_mapping(mapping, key, mig_id, {}, mig_fields)
        end
        next
      end

      if master_template
        # migration_ids are complicated in blueprint courses; fortunately, we have a stored mapping
        # between source id and migration_id in the MasterContentTags (except for ContentTags, which
        # fortunately _aren't_ complicated)
        if asset_type == "ContentTag"
          src_ids = source_course.context_module_tags.pluck(:id)
          src_ids.each do |src_id|
            global_asset_string = klass.asset_string(Shard.global_id_for(src_id, source_course.shard))
            mig_id = master_template.migration_id_for(global_asset_string)

            add_asset_pair_to_mapping(mapping, key, mig_id, { id: src_id }, { id: mig_id_to_dest_id[mig_id][:id] }) if mig_id_to_dest_id[mig_id]
          end
        else
          association_name = MasterCourses::MasterContentTag.polymorphic_assoc_for(klass)
          src_fields = [:content_id, :migration_id, *fields]

          master_template.master_content_tags
                         .where(migration_id: mig_id_to_dest_id.keys)
                         .joins(association_name)
                         .pluck(*src_fields)
                         .each do |src_results|
            src = src_fields.zip(src_results).to_h
            src[:id] = src[:content_id]
            mig_id = src[:migration_id]
            next unless mig_id_to_dest_id[mig_id]

            add_asset_pair_to_mapping(mapping, key, mig_id, src, mig_id_to_dest_id[mig_id]) if mig_id_to_dest_id[mig_id][:id]
            src_assignment_id = mig_id_to_dest_id[mig_id][:shell_id] && src[:assignment_id]
            next unless src_assignment_id

            add_asset_pair_to_mapping(mapping, "assignments", mig_id, { id: src_assignment_id }, { id: mig_id_to_dest_id[mig_id][:shell_id] })
          end
        end
      else
        src_fields = [:id, *migration_data_fields_for(asset_type)]
        # with course copy, there is no stored mapping between source id and migration_id,
        # so we will need to recompute migration_ids to discover the mapping
        source_course.shard.activate do
          srcs = klass.where(context: source_course).pluck(*src_fields).map do |field_values|
            src_fields.zip(Array.wrap(field_values)).to_h
          end
          srcs.each do |src|
            asset_string = klass.asset_string(src[:id])
            mig_id = CC::CCHelper.create_key(asset_string, global: global_ids)

            add_asset_pair_to_mapping(mapping, key, mig_id, src, mig_id_to_dest_id[mig_id]) if mig_id_to_dest_id[mig_id]
          end
        end
      end
    end

    mapping
  end

  def asset_map_url(generate_if_needed: false)
    generate_asset_map if !asset_map_attachment && generate_if_needed
    asset_map_attachment && file_download_url(
      asset_map_attachment,
      {
        verifier: asset_map_attachment.uuid,
        download: "1",
        download_frd: "1",
        host: context.root_account.domain(ApplicationController.test_cluster_name)
      }
    )
  end

  def asset_map_v2?
    Account.site_admin.feature_enabled?(:content_migration_asset_map_v2)
  end

  def generate_asset_map
    data = asset_id_mapping
    return if data.nil?

    payload = {
      "source_host" => source_course&.root_account&.domain(ApplicationController.test_cluster_name),
      "source_course" => source_course_id&.to_s,
      "contains_migration_ids" => Account.site_admin.feature_enabled?(:content_migration_asset_map_v2),
      "resource_mapping" => data
    }

    if asset_map_v2?
      payload["destination_course"] = context.id.to_s
      payload["destination_hosts"] = destination_hosts
      root_folder = Folder.root_folders(context).first
      payload["destination_root_folder"] = root_folder.name + "/" if root_folder
      payload["attachment_path_id_lookup"] = migration_settings[:attachment_path_id_lookup].presence || attachment_path_id_lookup
    end

    self.asset_map_attachment = Attachment.new(context: self, filename: "asset_map.json")
    Attachments::Storage.store_for_attachment(asset_map_attachment, StringIO.new(payload.to_json))
    asset_map_attachment.save!
    save!
  end

  def destination_hosts
    return [] unless context

    HostUrl.context_hosts(context.root_account).map { |h| h.split(":").first }
  end

  set_broadcast_policy do |p|
    p.dispatch :blueprint_content_added
    p.to { context.participating_admins }
    p.whenever do |record|
      record.changed_state_to(:imported) && record.for_master_course_import? &&
        record.master_migration && record.master_migration.send_notification?
    end
  end

  def self.expire_days
    Setting.get("content_migrations_expire_after_days", "30").to_i
  end

  def self.expire?
    ContentMigration.expire_days > 0
  end

  def expired?
    return false unless ContentMigration.expire?

    created_at < ContentMigration.expire_days.days.ago
  end

  scope :expired, lambda {
    if ContentMigration.expire?
      where("created_at < ?", ContentMigration.expire_days.days.ago)
    else
      none
    end
  }

  def self.find_most_recent_by_course_ids(source_course_id, context_id)
    ContentMigration.where(source_course_id:, context_id:).order(finished_at: :desc).first
  end
end
