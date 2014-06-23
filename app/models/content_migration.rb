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

class ContentMigration < ActiveRecord::Base
  include Workflow
  include TextHelper
  belongs_to :context, :polymorphic => true
  belongs_to :user
  belongs_to :attachment
  belongs_to :overview_attachment, :class_name => 'Attachment'
  belongs_to :exported_attachment, :class_name => 'Attachment'
  belongs_to :source_course, :class_name => 'Course'
  has_one :content_export
  has_many :migration_issues
  has_one :job_progress, :class_name => 'Progress', :as => :context
  serialize :migration_settings
  cattr_accessor :export_file_path
  DATE_FORMAT = "%m/%d/%Y"

  attr_accessible :context, :migration_settings, :user, :source_course, :copy_options, :migration_type, :initiated_source
  attr_accessor :imported_migration_items, :outcome_to_id_map

  EXPORTABLE_ATTRIBUTES = [
    :id, :context_id, :user_id, :workflow_state, :migration_settings, :started_at, :finished_at, :created_at, :updated_at, :context_type,
    :error_count, :error_data, :attachment_id, :overview_attachment_id, :exported_attachment_id, :source_course_id, :migration_type
  ]

  EXPORTABLE_ASSOCIATIONS = [:context, :user, :attachment, :overview_attachment, :exported_attachment, :content_export]

  workflow do
    state :created
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

  # the stream item context is decided by calling asset.context(user), i guess
  # to differentiate from the normal asset.context() call that may not give us
  # the context we want. in this case, they're one and the same.
  alias_method :original_context, :context
  def context(user = nil)
    self.original_context
  end

  def quota_context
    self.context
  end

  def migration_settings
    read_attribute(:migration_settings) || write_attribute(:migration_settings,{}.with_indifferent_access)
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
      er = ErrorReport.log_exception(:content_migration, opts[:exception])
      mi.error_report_id = er.id
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

  def add_import_warning(item_type, item_name, warning)
    item_name = CanvasTextHelper.truncate_text(item_name || "", :max_length => 150)
    add_warning(t('errors.import_error', "Import Error: ") + "#{item_type} - \"#{item_name}\"", warning)
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

  def queue_migration(plugin=nil)
    reset_job_progress

    set_default_settings
    plugin ||= Canvas::Plugin.find(migration_type)
    if plugin
      queue_opts = {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1}
      if self.strand
        queue_opts[:strand] = self.strand
      else
        queue_opts[:n_strand] = self.n_strand
      end

      if self.workflow_state == 'exported' && !plugin.settings[:skip_conversion_step]
        # it's ready to be imported
        self.workflow_state = :importing
        self.save
        self.send_later_enqueue_args(:import_content, queue_opts)
      else
        # find worker and queue for conversion
        begin
          if Canvas::Migration::Worker.const_defined?(plugin.settings['worker'])
            self.workflow_state = :exporting
            worker_class = Canvas::Migration::Worker.const_get(plugin.settings['worker'])
            job = Delayed::Job.enqueue(worker_class.new(self.id), queue_opts)
            self.save
            job
          else
            raise NameError
          end
        rescue NameError
          self.workflow_state = 'failed'
          message = "The migration plugin #{migration_type} doesn't have a worker."
          migration_settings[:last_error] = message
          ErrorReport.log_exception(:content_migration, $!)
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

  def set_default_settings
    if self.context && self.context.respond_to?(:root_account) && account = self.context.root_account
      if default_ms = account.settings[:default_migration_settings]
        self.migration_settings = default_ms.merge(self.migration_settings).with_indifferent_access
      end
    end

    if !self.migration_settings.has_key?(:overwrite_quizzes)
      self.migration_settings[:overwrite_quizzes] = for_course_copy? || (self.migration_type && self.migration_type == 'canvas_cartridge_importer')
    end

    check_quiz_id_prepender
  end

  def check_quiz_id_prepender
    return unless self.context.respond_to?(:assessment_questions)
    if !migration_settings[:id_prepender] && (!migration_settings[:overwrite_questions] || !migration_settings[:overwrite_quizzes])
      # only prepend an id if the course already has some migrated questions/quizzes
      if self.context.assessment_questions.where('assessment_questions.migration_id IS NOT NULL').exists? ||
         (self.context.respond_to?(:quizzes) && self.context.quizzes.where('quizzes.migration_id IS NOT NULL').exists?)
        migration_settings[:id_prepender] = self.id
      end
    end
  end

  def to_import(val)
    migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && migration_settings[:migration_ids_to_import][:copy][val]
  end

  def import_object?(asset_type, mig_id)
    return false unless mig_id
    return true unless migration_settings[:migration_ids_to_import] && migration_settings[:migration_ids_to_import][:copy] && migration_settings[:migration_ids_to_import][:copy].length > 0
    return true if is_set?(to_import(:everything))
    return true if copy_options && copy_options[:everything]

    return true if is_set?(to_import("all_#{asset_type}"))

    return false unless to_import(asset_type).present?

    is_set?(to_import(asset_type)[mig_id])
  end

  def is_set?(option)
    Canvas::Plugin::value_to_boolean option
  end

  def import_content
    reset_job_progress(:running) if !import_immediately?
    self.workflow_state = :importing
    self.save

    begin
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

      migration_settings[:migration_ids_to_import] ||= {:copy=>{}}

      Importers.content_importer_for(self.context_type).import_content(self.context, data, migration_settings[:migration_ids_to_import], self)

      if !self.import_immediately?
        update_import_progress(100)
      end
    rescue => e
      self.workflow_state = :failed
      er = ErrorReport.log_exception(:content_migration, e)
      migration_settings[:last_error] = "ErrorReport:#{er.id}"
      logger.error e
      self.save
      raise e
    ensure
      clear_migration_data
    end
  end
  alias_method :import_content_without_send_later, :import_content

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
    self.migration_type && self.migration_type == 'course_copy_importer'
  end

  def set_date_shift_options(opts)
    if opts && Canvas::Plugin.value_to_boolean(opts[:shift_dates])
      self.migration_settings[:date_shift_options] = opts.slice(:shift_dates, :old_start_date, :old_end_date, :new_start_date, :new_end_date, :day_substitutions, :time_zone)
    end
  end

  def date_shift_options
    self.migration_settings[:date_shift_options]
  end

  scope :for_context, lambda { |context| where(:context_id => context, :context_type => context.class.to_s) }

  scope :successful, where(:workflow_state => 'imported')
  scope :running, where(:workflow_state => ['exporting', 'importing'])
  scope :waiting, where(:workflow_state => 'exported')
  scope :failed, where(:workflow_state => ['failed', 'pre_process_error'])

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

  def add_missing_content_links(item)
    @missing_content_links ||= {}
    item[:field] ||= :text
    key = "#{item[:class]}_#{item[:id]}_#{item[:field]}"
    if item[:missing_links].present?
      @missing_content_links[key] = item
    else
      @missing_content_links.delete(key)
    end
  end

  def add_warnings_for_missing_content_links
    return unless @missing_content_links
    @missing_content_links.each_value do |item|
      if item[:missing_links].any?
        add_warning(t(:missing_content_links_title, "Missing links found in imported content") + " - #{item[:class]} #{item[:field]}",
          {:error_message => "#{item[:class]} #{item[:field]} - " + t(:missing_content_links_message,
            "The following references could not be resolved: ") + " " + item[:missing_links].join(', '),
            :fix_issue_html_url => item[:url]})
      end
    end
  end

  # returns a list of content for selective content migrations
  # If no section is specified the top-level areas with content are returned
  def get_content_list(type=nil, base_url=nil)
    Canvas::Migration::Helpers::SelectiveContentFormatter.new(self, base_url).get_content_list(type)
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

  # strips out the "id_" prepending the migration ids in the form
  def self.process_copy_params(hash)
    return {} if hash.blank? || !hash.is_a?(Hash)
    hash.values.each do |sub_hash|
      next unless sub_hash.is_a?(Hash) # e.g. second level in :copy => {:context_modules => {:id_100 => true, etc}}

      clean_hash = {}
      sub_hash.keys.each do |k|
        if k.is_a?(String) && k.start_with?("id_")
          clean_hash[k.sub("id_", "")] = sub_hash.delete(k)
        end
      end
      sub_hash.merge!(clean_hash)
    end
    hash
  end

  def imported_migration_items
    @imported_migration_items_hash ||= {}
    @imported_migration_items_hash.values.flatten
  end

  def imported_migration_items_by_class(klass)
    @imported_migration_items_hash ||= {}
    @imported_migration_items_hash[klass.name] ||= []
  end

  def add_imported_item(item)
    arr = imported_migration_items_by_class(item.class)
    arr << item unless arr.include?(item)
  end

  def add_external_tool_translation(migration_id, target_tool, custom_fields)
    @external_tool_translation_map ||= {}
    @external_tool_translation_map[migration_id] = [target_tool.id, custom_fields]
  end

  def find_external_tool_translation(migration_id)
    @external_tool_translation_map && migration_id && @external_tool_translation_map[migration_id]
  end
end
