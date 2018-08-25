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
  include TextHelper
  belongs_to :context, polymorphic: [:course, :account, :group, { context_user: 'User' }]
  validate :valid_date_shift_options
  belongs_to :user
  belongs_to :attachment
  belongs_to :overview_attachment, :class_name => 'Attachment'
  belongs_to :exported_attachment, :class_name => 'Attachment'
  belongs_to :source_course, :class_name => 'Course'
  has_one :content_export
  has_many :migration_issues
  has_one :job_progress, :class_name => 'Progress', :as => :context, :inverse_of => :context
  serialize :migration_settings
  cattr_accessor :export_file_path
  before_save :set_started_at_and_finished_at
  after_save :handle_import_in_progress_notice
  after_save :check_for_blocked_migration

  DATE_FORMAT = "%m/%d/%Y"

  attr_accessor :imported_migration_items, :outcome_to_id_map, :attachment_path_id_lookup, :attachment_path_id_lookup_lower, :last_module_position, :skipped_master_course_items

  has_a_broadcast_policy

  workflow do
    state :created
    state :queued
    #The pre_process states can be used by individual plugins as needed
    state :pre_processing
    state :pre_processed
    state :pre_process_error
    state :exporting
    state :exported
    state :importing
    state :imported
    state :failed
  end

  def self.migration_plugins(exclude_hidden=false)
    plugins = Canvas::Plugin.all_for_tag(:export_system)
    exclude_hidden ? plugins.select{|p|!p.meta[:hide_from_users]} : plugins
  end

  set_policy do
    given { |user, session| self.context.grants_right?(user, session, :manage_files) }
    can :manage_files and can :read
  end

  def set_started_at_and_finished_at
    if workflow_state_changed?
      if pre_processing? || exporting? || importing?
        self.started_at ||= Time.now.utc
      end
      if failed? || imported? || exported?
        self.finished_at ||= Time.now.utc
      end
    end
  end

  def quota_context
    self.context
  end

  def migration_settings
    read_or_initialize_attribute(:migration_settings, {}.with_indifferent_access)
  end

  def update_migration_settings(new_settings)
    new_settings.each do |key, val|
      migration_settings[key] = val
    end
  end

  def import_immediately?
    !!migration_settings[:import_immediately]
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
    ["migrations:import_content", self.root_account.try(:global_id) || "global"]
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
    if name && name.strip! != ''
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
    self.context.root_account rescue nil
  end

  def migration_type
    read_attribute(:migration_type) || migration_settings['migration_type']
  end

  def plugin_type
    if plugin = Canvas::Plugin.find(migration_type)
      plugin.metadata(:select_text) || plugin.name
    else
      t(:unknown, 'Unknown')
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
  def add_issue(user_message, type, opts={})
    mi = self.migration_issues.build(:issue_type => type.to_s, :description => user_message)
    if opts[:error_report_id]
      mi.error_report_id = opts[:error_report_id]
    elsif opts[:exception]
      er = Canvas::Errors.capture_exception(:content_migration, opts[:exception])[:error_report]
      mi.error_report_id = er
    end
    mi.error_message = opts[:error_message]
    mi.fix_issue_html_url = opts[:fix_issue_html_url]

    # prevent duplicates
    if self.migration_issues.where(mi.attributes.slice(
        "issue_type", "description", "error_message", "fix_issue_html_url")).any?
      mi.delete
    else
      mi.save!
    end

    mi
  end

  def add_todo(user_message, opts={})
    add_issue(user_message, :todo, opts)
  end

  def add_error(user_message, opts={})
    add_issue(user_message, :error, opts)
  end

  def add_warning(user_message, opts={})
    if !opts.is_a? Hash
      # convert deprecated behavior to new
      exception_or_info = opts
      opts={}
      if exception_or_info.is_a?(Exception)
        opts[:exception] = exception_or_info
      else
        opts[:error_message] = exception_or_info
      end
    end
    add_issue(user_message, :warning, opts)
  end

  def add_unique_warning(key, warning, opts={})
    @added_warnings ||= Set.new
    return if @added_warnings.include?(key) # only add it once
    @added_warnings << key
    add_warning(warning, opts)
  end

  def add_import_warning(item_type, item_name, warning)
    item_name = CanvasTextHelper.truncate_text(item_name || "", :max_length => 150)
    add_warning(t('errors.import_error', "Import Error:") + " #{item_type} - \"#{item_name}\"", warning)
  end

  def fail_with_error!(exception_or_info)
    opts={}
    if exception_or_info.is_a?(Exception)
      opts[:exception] = exception_or_info
    else
      opts[:error_message] = exception_or_info
    end
    add_error(t(:unexpected_error, "There was an unexpected error, please contact support."), opts)
    self.workflow_state = :failed
    job_progress.fail if job_progress && !skip_job_progress
    save
    self.update_master_migration('failed') if for_master_course_import?
    resolve_content_links! # don't leave placeholders
  end

  # deprecated warning format
  def old_warnings_format
    self.migration_issues.map do |mi|
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
      self.migration_issues.delete_all if self.migration_issues.any?
      self.workflow_state = :pre_processed
      self.save
      self.queue_migration
    else
      self.workflow_state = :pre_process_error
      self.add_warning(t('bad_attachment', "The file was not successfully uploaded."))
    end
  end

  def reset_job_progress(wf_state=:queued)
    return if skip_job_progress
    self.progress = 0
    if self.job_progress
      p = self.job_progress
    else
      p = Progress.new(:context => self, :tag => "content_migration")
      self.job_progress = p
    end
    p.workflow_state = wf_state
    p.completion = 0
    p.user = self.user
    p.save!
    p
  end

  def queue_migration(plugin=nil, retry_count: 0, expires_at: nil)
    reset_job_progress unless plugin && plugin.settings[:skip_initial_progress]

    expires_at ||= Setting.get('content_migration_job_expiration_hours', '48').to_i.hours.from_now
    return if blocked_by_current_migration?(plugin, retry_count, expires_at)

    set_default_settings

    plugin ||= Canvas::Plugin.find(migration_type)
    if plugin
      queue_opts = {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1,
                    :expires_at => expires_at}
      if self.strand
        queue_opts[:strand] = self.strand
      else
        queue_opts[:n_strand] = self.n_strand
      end

      if plugin.settings[:import_immediately] || (self.workflow_state == 'exported' && !plugin.settings[:skip_conversion_step])
        # it's ready to be imported
        self.workflow_state = :importing
        self.save
        self.send_later_enqueue_args(:import_content, queue_opts.merge(:on_permanent_failure => :fail_with_error!))
      else
        # find worker and queue for conversion
        begin
          worker_class = Canvas::Migration::Worker.const_get(plugin.settings['worker'])
          self.workflow_state = :exporting
          self.save
          Delayed::Job.enqueue(worker_class.new(self.id), queue_opts)
        rescue NameError
          self.workflow_state = 'failed'
          message = "The migration plugin #{migration_type} doesn't have a worker."
          migration_settings[:last_error] = message
          Canvas::Errors.capture_exception(:content_migration, $ERROR_INFO)
          logger.error message
          self.save
        end
      end
    else
      self.workflow_state = 'failed'
      message = "No migration plugin of type #{migration_type} found."
      migration_settings[:last_error] = message
      logger.error message
      self.save
    end
  end
  alias_method :export_content, :queue_migration

  def blocked_by_current_migration?(plugin, retry_count, expires_at)
    return false if self.migration_type == "zip_file_importer"
    running_cutoff = Setting.get('content_migration_job_block_hours', '4').to_i.hours.ago # at some point just let the jobs keep going

    if self.context && self.context.content_migrations.
      where(:workflow_state => %w{created queued pre_processing pre_processed exporting importing}).where("id < ?", self.id).
      where("started_at > ?", running_cutoff).exists?

      # there's another job already going so punt

      if retry_count > 5
        self.fail_with_error!(I18n.t("Blocked by running migration"))
      else
        self.workflow_state = :queued
        self.save

        run_at = Setting.get('content_migration_requeue_delay_minutes', '60').to_i.minutes.from_now
        # if everything goes right, we'll queue it right away after the currently running one finishes
        # but if something goes catastropically wrong, then make sure we recheck it eventually
        job = self.send_later_enqueue_args(:queue_migration, {:no_delay => true, :run_at => run_at},
          plugin, retry_count: retry_count + 1, expires_at: expires_at)

        if self.job_progress
          self.job_progress.delayed_job_id = job.id
          self.job_progress.save!
        end
      end

      return true
    else
      return false
    end
  end

  def set_default_settings
    if self.context && self.context.respond_to?(:root_account) && account = self.context.root_account
      if default_ms = account.settings[:default_migration_settings]
        self.migration_settings = default_ms.merge(self.migration_settings).with_indifferent_access
      end
    end

    if !self.migration_settings.has_key?(:overwrite_quizzes)
      self.migration_settings[:overwrite_quizzes] = for_course_copy? || for_master_course_import? || (self.migration_type && self.migration_type == 'canvas_cartridge_importer')
    end
    self.migration_settings.reverse_merge!(:prefer_existing_tools => true) if self.migration_type == 'common_cartridge_importer' # default to true

    check_quiz_id_prepender
  end

  def process_domain_substitutions(url)
    unless @domain_substitution_map
      @domain_substitution_map = {}
      (self.migration_settings[:domain_substitution_map] || {}).each do |k, v|
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
    return unless self.context.respond_to?(:assessment_questions)
    if !migration_settings[:id_prepender] && (!migration_settings[:overwrite_questions] || !migration_settings[:overwrite_quizzes])
      migration_settings[:id_prepender] = self.id
    end
  end

  def to_import(val)
    migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && migration_settings[:migration_ids_to_import][:copy][val]
  end

  def import_everything?
    return true unless migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && migration_settings[:migration_ids_to_import][:copy].length > 0
    return true if is_set?(to_import(:everything))
    return true if copy_options && is_set?(copy_options[:everything])
    false
  end

  def original_id_for(mig_id)
    return nil unless mig_id.is_a?(String)
    prefix = "#{migration_settings[:id_prepender]}_"
    return nil unless mig_id.start_with? prefix
    mig_id[prefix.length..-1]
  end

  def import_object?(asset_type, mig_id)
    return false unless mig_id
    return true if import_everything?

    return true if is_set?(to_import("all_#{asset_type}"))

    return false unless to_import(asset_type).present?

    if (orig_id = original_id_for(mig_id))
      return true if is_set?(to_import(asset_type)[orig_id])
    end
    is_set?(to_import(asset_type)[mig_id])
  end

  def import_object!(asset_type, mig_id)
    return if import_everything?
    migration_settings[:migration_ids_to_import][:copy][asset_type] ||= {}
    migration_settings[:migration_ids_to_import][:copy][asset_type][mig_id] = '1'
  end

  def is_set?(option)
    Canvas::Plugin::value_to_boolean option
  end

  def import_content
    reset_job_progress(:running) if !import_immediately?
    self.workflow_state = :importing
    self.save

    Lti::Asset.opaque_identifier_for(self.context)

    all_files_path = nil
    begin
      data = nil
      if self.for_master_course_import?
        self.master_course_subscription.load_tags! # load child content tags
        self.master_course_subscription.master_template.preload_restrictions!

        # copy the attachments
        source_export = ContentExport.find(self.migration_settings[:master_course_export_id])
        if source_export.selective_export?
          # load in existing attachments to path resolution map
          file_mig_ids = source_export.settings[:referenced_file_migration_ids]
          if file_mig_ids.present?
            # ripped from copy_attachments_from_course
            root_folder_name = Folder.root_folders(self.context).first.name + '/'
            self.context.attachments.where(:migration_id => file_mig_ids).each do |file|
              self.add_attachment_path(file.full_display_path.gsub(/\A#{root_folder_name}/, ''), file.migration_id)
            end
          end
        end
        self.context.copy_attachments_from_course(source_export.context, :content_export => source_export, :content_migration => self)
        MasterCourses::FolderHelper.recalculate_locked_folders(self.context)
        MasterCourses::FolderHelper.update_folder_names(self.context, source_export)

        data = JSON.parse(self.exported_attachment.open, :max_nesting => 50)
        data = prepare_data(data)
      else
        @exported_data_zip = download_exported_data
        @zip_file = Zip::File.open(@exported_data_zip.path)
        @exported_data_zip.close
        data = JSON.parse(@zip_file.read('course_export.json'), :max_nesting => 50)
        data = prepare_data(data)

        if @zip_file.find_entry('all_files.zip')
          # the file importer needs an actual file to process
          all_files_path = create_all_files_path(@exported_data_zip.path)
          @zip_file.extract('all_files.zip', all_files_path)
          data['all_files_export']['file_path'] = all_files_path
        else
          data['all_files_export']['file_path'] = nil
        end
        @zip_file.close
      end

      migration_settings[:migration_ids_to_import] ||= {:copy=>{}}
      import!(data)

      if !self.import_immediately?
        update_import_progress(100)
      end
      if self.for_master_course_import?
        process_master_deletions(data['deletions']) if data['deletions'].present?
        self.update_master_migration('completed')
      end
    rescue => e
      self.workflow_state = :failed
      er_id = Canvas::Errors.capture_exception(:content_migration, e)[:error_report]
      migration_settings[:last_error] = "ErrorReport:#{er_id}"
      logger.error e
      self.save
      self.update_master_migration('failed') if self.for_master_course_import?
      raise e
    ensure
      File.delete(all_files_path) if all_files_path && File.exists?(all_files_path)
      clear_migration_data
    end
  end
  alias_method :import_content_without_send_later, :import_content

  def import!(data)
    return import_quizzes_next!(data) if quizzes_next_migration?
    Importers.content_importer_for(self.context_type).
      import_content(
        self.context,
        data,
        self.migration_settings[:migration_ids_to_import],
        self
      )
  end

  def quizzes_next_migration?
    context.instance_of?(Course) && root_account &&
      root_account.feature_enabled?(:import_to_quizzes_next) &&
      migration_settings[:import_quizzes_next]
  end

  def import_quizzes_next!(data)
    quizzes2_importer =
      QuizzesNext::Importers::CourseContentImporter.new(data, self)
    quizzes2_importer.import_content(
      self.migration_settings[:migration_ids_to_import]
    )
  end

  def master_migration
    @master_migration ||= self.shard.activate { MasterCourses::MasterMigration.find(self.migration_settings[:master_migration_id]) }
  end

  def update_master_migration(state)
    master_migration.update_import_state!(self, state)
  end

  def master_course_subscription
    return unless self.for_master_course_import?
    @master_course_subscription ||= self.shard.activate { MasterCourses::ChildSubscription.find(self.child_subscription_id) }
  end

  def prepare_data(data)
    data = data.with_indifferent_access if data.is_a? Hash
    Utf8Cleaner.recursively_strip_invalid_utf8!(data, true)
    data['all_files_export'] ||= {}
    data
  end

  def copy_options
    self.migration_settings[:copy_options]
  end

  def copy_options=(options)
    self.migration_settings[:copy_options] = options
    set_date_shift_options options
  end

  def for_course_copy?
    self.migration_type == 'course_copy_importer' || for_master_course_import?
  end

  def for_master_course_import?
    self.migration_type == 'master_course_import'
  end

  def add_skipped_item(item)
    @skipped_master_course_items ||= Set.new
    item = item.migration_id if item.is_a?(MasterCourses::ChildContentTag)
    @skipped_master_course_items << item
  end

  def process_master_deletions(deletions)
    deletions.keys.each do |klass|
      next unless MasterCourses::CONTENT_TYPES_FOR_DELETIONS.include?(klass)
      mig_ids = deletions[klass]
      item_scope = case klass
      when 'Attachment'
        self.context.attachments.not_deleted.where(migration_id: mig_ids)
      else
        klass.constantize.where(context_id: self.context, context_type: 'Course', migration_id: mig_ids).
          where.not(workflow_state: 'deleted')
      end
      item_scope.each do |content|
        child_tag = master_course_subscription.content_tag_for(content)
        skip_item = child_tag.downstream_changes.any? && !content.editing_restricted?(:any)
        if content.is_a?(AssignmentGroup) && !skip_item && content.assignments.active.exists?
          skip_item = true # don't delete an assignment group if an assignment is left (either they added one or changed one so it was skipped)
        end

        if skip_item
          Rails.logger.debug("skipping deletion sync for #{content.asset_string} due to downstream changes #{child_tag.downstream_changes}")
          add_skipped_item(child_tag)
        else
          Rails.logger.debug("syncing deletion of #{content.asset_string} from master course")
          content.skip_downstream_changes! if content.respond_to?(:skip_downstream_changes!)
          content.destroy
        end
      end
    end
  end

  def check_cross_institution
    return unless self.context.is_a?(Course)
    data = self.context.full_migration_hash
    return unless data
    source_root_account_uuid = data[:course] && data[:course][:root_account_uuid]
    @cross_institution = source_root_account_uuid && source_root_account_uuid != self.context.root_account.uuid
  end

  def cross_institution?
    @cross_institution
  end

  def set_date_shift_options(opts)
    if opts && (Canvas::Plugin.value_to_boolean(opts[:shift_dates]) || Canvas::Plugin.value_to_boolean(opts[:remove_dates]))
      self.migration_settings[:date_shift_options] = opts.slice(:shift_dates, :remove_dates, :old_start_date, :old_end_date, :new_start_date, :new_end_date, :day_substitutions, :time_zone)
    end
  end

  def date_shift_options
    self.migration_settings[:date_shift_options]
  end

  def valid_date_shift_options
    if date_shift_options && Canvas::Plugin.value_to_boolean(date_shift_options[:shift_dates]) && Canvas::Plugin.value_to_boolean(date_shift_options[:remove_dates])
      errors.add(:date_shift_options, t('errors.cannot_shift_and_remove', "cannot specify shift_dates and remove_dates simultaneously"))
    end
  end

  scope :for_context, lambda { |context| where(:context_id => context, :context_type => context.class.to_s) }

  scope :successful, -> { where(:workflow_state => 'imported') }
  scope :running, -> { where(:workflow_state => ['exporting', 'importing']) }
  scope :waiting, -> { where(:workflow_state => 'exported') }
  scope :failed, -> { where(:workflow_state => ['failed', 'pre_process_error']) }

  def complete?
    %w[imported failed pre_process_error].include?(workflow_state)
  end

  def download_exported_data
    raise "No exported data to import" unless self.exported_attachment
    config = ConfigFile.load('external_migration') || {}
    @exported_data_zip = self.exported_attachment.open(
      :need_local_file => true,
      :temp_folder => config[:data_folder])
    @exported_data_zip
  end

  def create_all_files_path(temp_path)
    "#{temp_path}_all_files.zip"
  end

  def clear_migration_data
    @zip_file.close if @zip_file
    @zip_file = nil
  end

  def finished_converting
    #todo finish progress if selective
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
    return nil if self.workflow_state == 'created'
    mig_prog = read_attribute(:progress) || 0
    if self.for_course_copy?
      # this is for a course copy so it needs to combine the progress of the export and import
      # The export will count for 40% of progress
      # The importing step (so the value of progress on this object)will be 60%
      mig_prog = mig_prog * 0.6

      if self.content_export
        export_prog = self.content_export.progress || 0
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
        job_progress.workflow_state = 'completed'
        job_progress.save!
      else
        job_progress.update_completion!(val)
      end
    end
    # Until this progress is phased out
    self.progress = val
    ContentMigration.where(:id => self).update_all(:progress=>val)
  end

  def html_converter
    @html_converter ||= ImportedHtmlConverter.new(self)
  end

  def convert_html(*args)
    html_converter.convert(*args)
  end

  def convert_text(*args)
    html_converter.convert_text(*args)
  end

  def resolve_content_links!
    html_converter.resolve_content_links!
  end

  def add_warning_for_missing_content_links(type, field, missing_links, fix_issue_url)
    add_warning(t(:missing_content_links_title, "Missing links found in imported content") + " - #{type} #{field}",
      {:error_message => "#{type} #{field} - " + t(:missing_content_links_message,
        "The following references could not be resolved:") + " " + missing_links.join(', '),
        :fix_issue_html_url => fix_issue_url})
  end

  UPLOAD_TIMEOUT = 1.hour
  def check_for_pre_processing_timeout
    if self.pre_processing? && (self.updated_at.utc + UPLOAD_TIMEOUT) < Time.now.utc
      add_error(t(:upload_timeout_error, "The file upload process timed out."))
      self.workflow_state = :failed
      job_progress.fail if job_progress && !skip_job_progress
      self.save
    end
  end

  # maps the key in the copy parameters hash to the asset string prefix
  # (usually it's just .singularize; weird names needing special casing go here :P)
  def self.asset_string_prefix(key)
    case key
    when 'quizzes'
      'quizzes:quiz'
    when 'announcements'
      'discussion_topic'
    else
      key.singularize
    end
  end

  def self.collection_name(key)
    key = key.to_s
    case key
    when 'modules'
      'context_modules'
    when 'module_items'
      'content_tags'
    when 'pages'
      'wiki_pages'
    when 'files'
      'attachments'
    else
      key
    end
  end

  # strips out the "id_" prepending the migration ids in the form
  # also converts arrays of migration ids (or real ids for course exports) into the old hash format
  def self.process_copy_params(hash, for_content_export=false, return_asset_strings=false)
    return {} if hash.blank?
    process_key = if return_asset_strings
      ->(asset_string) { asset_string }
    else
      ->(asset_string) { CC::CCHelper.create_key(asset_string) }
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
            sub_hash[process_key.call("#{asset_type}_#{id}")] = '1'
          end
        else
          value.each do |id|
            sub_hash[id] = '1'
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

  def imported_migration_items_hash(klass=nil)
    @imported_migration_items_hash ||= {}
    return @imported_migration_items_hash unless klass
    @imported_migration_items_hash[klass.name] ||= {}
  end

  def imported_migration_items_by_class(klass)
    imported_migration_items_hash(klass).values
  end

  def find_imported_migration_item(klass, migration_id)
    imported_migration_items_hash(klass)[migration_id]
  end

  def add_imported_item(item, key: item.migration_id)
    imported_migration_items_hash(item.class)[key] = item
  end

  def add_attachment_path(path, migration_id)
    self.attachment_path_id_lookup ||= {}
    self.attachment_path_id_lookup_lower ||= {}
    self.attachment_path_id_lookup[path] = migration_id
    self.attachment_path_id_lookup_lower[path.downcase] = migration_id
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
    if (just_created || (saved_change_to_workflow_state? && %w{created queued}.include?(workflow_state_before_last_save))) &&
        %w(pre_processing pre_processed exporting importing).include?(workflow_state)
      context.add_content_notice(:import_in_progress, 4.hours)
    elsif saved_change_to_workflow_state? && %w(pre_process_error exported imported failed).include?(workflow_state)
      context.remove_content_notice(:import_in_progress)
    end
  end

  def check_for_blocked_migration
    if self.saved_change_to_workflow_state? && %w(pre_process_error exported imported failed).include?(workflow_state)
      if self.context && (next_cm = self.context.content_migrations.where(:workflow_state => 'queued').order(:id).first)
        job_id = next_cm.job_progress.try(:delayed_job_id)
        if job_id && (job = Delayed::Job.where(:id => job_id, :locked_at => nil).first)
          job.run_at = Time.now # it's okay to try it again now
          job.save
        end
      end
    end
  end

  def notification_link_anchor
    "!/blueprint/blueprint_subscriptions/#{self.child_subscription_id}/#{id}"
  end

  set_broadcast_policy do |p|
    p.dispatch :blueprint_content_added
    p.to { context.participating_admins }
    p.whenever { |record|
      record.changed_state_to(:imported) && record.for_master_course_import? &&
        record.master_migration && record.master_migration.send_notification?
    }
  end

  def self.expire_days
    Setting.get('content_migrations_expire_after_days', '30').to_i
  end

  def self.expire?
    ContentMigration.expire_days > 0
  end

  def expired?
    return false unless ContentMigration.expire?
    created_at < ContentMigration.expire_days.days.ago
  end

  scope :expired, -> {
    if ContentMigration.expire?
      where('created_at < ?', ContentMigration.expire_days.days.ago)
    else
      none
    end
  }
end
