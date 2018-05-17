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

class SisBatch < ActiveRecord::Base
  include Workflow
  belongs_to :account
  serialize :data
  serialize :options
  serialize :processing_errors, Array
  serialize :processing_warnings, Array
  belongs_to :attachment
  belongs_to :errors_attachment, class_name: 'Attachment'
  has_many :parallel_importers, inverse_of: :sis_batch
  has_many :sis_batch_errors, inverse_of: :sis_batch, autosave: false
  belongs_to :generated_diff, class_name: 'Attachment'
  belongs_to :batch_mode_term, class_name: 'EnrollmentTerm'
  belongs_to :user

  validates_presence_of :account_id, :workflow_state
  validates_length_of :diffing_data_set_identifier, maximum: 128

  attr_accessor :zip_path
  def self.max_attempts
    5
  end

  def self.valid_import_types
    @valid_import_types ||= {
      "instructure_csv" => {
        :name => lambda { t(:instructure_csv, "Instructure formatted CSV or zipfile of CSVs") },
        :callback => lambda { |batch| batch.process_instructure_csv_zip },
        :default => true
      }
    }
  end

  # If you are going to change any settings on the batch before it's processed,
  # do it in the block passed into this method, so that the changes are saved
  # before the batch is marked created and eligible for processing.
  def self.create_with_attachment(account, import_type, attachment, user = nil)
    batch = SisBatch.new
    batch.account = account
    batch.progress = 0
    batch.workflow_state = :initializing
    batch.data = {:import_type => import_type}
    batch.user = user
    batch.save

    att = create_data_attachment(batch, attachment, t(:upload_filename, "sis_upload_%{id}.zip", :id => batch.id))
    batch.attachment = att

    yield batch if block_given?
    batch.workflow_state = :created
    batch.save!

    batch
  end

  def self.create_data_attachment(batch, data, display_name)
    batch.shard.activate do
      Attachment.new.tap do |att|
        Attachment.skip_3rd_party_submits(true)
        att.context = batch
        att.uploaded_data = data
        att.display_name = display_name
        att.save!
      end
    end
  ensure
    Attachment.skip_3rd_party_submits(false)
  end

  def self.add_error(csv, message, sis_batch:, row: nil, failure: false, backtrace: nil, row_info: nil)
    error = build_error(csv, message, row: row, failure: failure, backtrace: backtrace, row_info: row_info, sis_batch: sis_batch)
    error.save!
  end

  def self.build_error(csv, message, sis_batch:, row: nil, failure: false, backtrace: nil, row_info: nil)
    file = csv ? csv[:file] : nil
    sis_batch.sis_batch_errors.build(root_account: sis_batch.account,
                                     file: file,
                                     message: message,
                                     failure: failure,
                                     backtrace: backtrace,
                                     row_info: row_info,
                                     row: row,
                                     created_at: Time.zone.now)
  end

  def self.bulk_insert_sis_errors(errors)
    errors.each_slice(1000) do |batch|
      errors_hash = batch.map do |error|
        {
          root_account_id: error.root_account_id,
          created_at: error.created_at,
          sis_batch_id: error.sis_batch_id,
          failure: error.failure,
          file: error.file,
          message: error.message,
          backtrace: error.backtrace,
          row: error.row,
          row_info: error.row_info
        }
      end
      SisBatchError.bulk_insert(errors_hash)
    end
  end

  def self.rows_for_parallel(rows)
    # Try to have 100 jobs but don't have a job that processes less than 25
    # rows but also not more than 1000 rows.
    # Progress is calculated on the number of jobs remaining.
    [[(rows/100.to_f).ceil, 25].max, 1000].min
  end

  workflow do
    state :initializing
    state :created
    state :importing
    state :cleanup_batch
    state :imported
    state :imported_with_messages
    state :aborted
    state :failed
    state :failed_with_messages
  end

  def process
    self.class.queue_job_for_account(self.account)
  end

  def enable_diffing(data_set_id, opts = {})
    if data[:import_type] == "instructure_csv"
      self.diffing_data_set_identifier = data_set_id
      if opts[:remaster]
        self.diffing_remaster = true
      end
    end
  end

  class Aborted < RuntimeError; end

  def self.queue_job_for_account(account, run_at=nil)
    job_args = {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1}

    key = use_parallel_importers?(account) ? :strand : :singleton
    job_args[key] = strand_for_account(account)

    if run_at
      job_args[:run_at] = run_at
    else
      process_delay = Setting.get('sis_batch_process_start_delay', '0').to_f
      if process_delay > 0
        job_args[:run_at] = process_delay.seconds.from_now
      end
    end

    work = SisBatch::Work.new(SisBatch, :process_all_for_account, [account])
    Delayed::Job.enqueue(work, job_args)
  end

  class Work < Delayed::PerformableMethod
    def on_permanent_failure(_error)
      account = args.first
      account.sis_batches.importing.each do |batch|
        batch.finish(false)
      end

      job_args = {
        singleton: "account:update_account_associations:#{Shard.birth.activate { account.id }}",
        priority: Delayed::LOW_PRIORITY,
        max_attempts: 1,
      }
      account.send_later_enqueue_args(:update_account_associations, job_args)
    end
  end

  # this method name is to stay backwards compatible with existing jobs when we deploy
  # once no SisBatch#process_without_send_later jobs are being created anymore, we
  # can rename this to something more sensible.
  def process_without_send_later
    self.class.transaction do
      self.options ||= {}
      if self.workflow_state == 'aborted'
        self.progress = 100
        self.save
        return
      end
      if self.workflow_state == 'created'
        self.workflow_state = :importing
        self.progress = 0
        self.started_at = Time.now.utc
        self.save
      else
        return
      end
    end

    import_scheme = SisBatch.valid_import_types[self.data[:import_type]]
    if import_scheme.nil?
      self.data[:error_message] = t 'errors.unrecorgnized_type', "Unrecognized import type"
      self.workflow_state = :failed
      self.save
      return
    end

    import_scheme[:callback].call(self)
  rescue => e
    self.data[:error_message] = e.to_s
    self.data[:stack_trace] = "#{e}\n#{e.backtrace.join("\n")}"
    self.workflow_state = "failed"
    self.save
  end

  def abort_batch
    SisBatch.not_completed.where(id: self).update_all(workflow_state: 'aborted')
  end

  def batch_aborted(message)
    SisBatch.add_error(nil, message, sis_batch: self)
    raise SisBatch::Aborted
  end

  def self.abort_all_pending_for_account(account)
    self.transaction do
      account.sis_batches.not_started.lock(:no_key_update).order(:id).find_in_batches do |batch|
        SisBatch.where(id: batch).update_all(workflow_state: 'aborted', progress: 100)
      end
    end
  end

  scope :not_started, -> { where(workflow_state: ['initializing', 'created']) }
  scope :needs_processing, -> { where(:workflow_state => 'created').order(:created_at) }
  scope :importing, -> { where(workflow_state: ['importing', 'cleanup_batch']) }
  scope :not_completed, -> { where(workflow_state: %w[initializing created importing cleanup_batch]) }
  scope :succeeded, -> { where(:workflow_state => %w[imported imported_with_messages]) }

  def self.use_parallel_importers?(account)
    account.feature_enabled?(:refactor_of_sis_imports)
  end

  def self.strand_for_account(account)
    "sis_batch:account:#{Shard.birth.activate { account.id }}"
  end

  def skip_deletes?
    self.options ||= {}
    !!self.options[:skip_deletes]
  end

  def self.process_all_for_account(account)
    if use_parallel_importers?(account)
      if account.sis_batches.importing.exists?
        delay = Setting.get('sis_batch_recheck_delay', 5.minutes).to_i
        queue_job_for_account(account, delay.seconds.from_now) # requeue another job to check a little later
      else
        batch_to_run = account.sis_batches.needs_processing.order(:created_at).first
        if batch_to_run
          batch_to_run.process_without_send_later
        end
      end
    else
      start_time = Time.now
      loop do
        batches = account.sis_batches.needs_processing.limit(50).order(:created_at).to_a
        break if batches.empty?
        batches.each do |batch|
          batch.process_without_send_later
          if Time.now - start_time > Setting.get('max_time_per_sis_batch', 60).to_i
            # requeue the job to continue processing more batches
            queue_job_for_account(account)
            return
          end
        end
      end
    end
  end

  def fast_update_progress(val)
    return true if val == self.progress
    self.progress = val
    state = SisBatch.connection.select_value(<<-SQL)
      UPDATE #{SisBatch.quoted_table_name} SET progress=#{val} WHERE id=#{self.id} RETURNING workflow_state
    SQL
    raise SisBatch::Aborted if state == 'aborted'
  end

  def importing?
    self.workflow_state == 'importing' ||
      self.workflow_state == 'created' ||
      self.workflow_state == 'cleanup_batch'
  end

  def process_instructure_csv_zip
    require 'sis'
    download_zip
    generate_diff

    use_parallel = self.class.use_parallel_importers?(self.account)
    import_class = use_parallel ? SIS::CSV::ImportRefactored : SIS::CSV::Import
    importer = import_class.process(self.account,
                                        files: [@data_file.path],
                                        batch: self,
                                        override_sis_stickiness: options[:override_sis_stickiness],
                                        add_sis_stickiness: options[:add_sis_stickiness],
                                        clear_sis_stickiness: options[:clear_sis_stickiness])
    finish importer.finished unless use_parallel
  end

  def generate_diff
    return if self.diffing_remaster # joined the chain, but don't actually want to diff this one
    return unless self.diffing_data_set_identifier

    # the previous batch may not have had diffing applied because of the change_threshold,
    # so look for the latest one with a generated_diff_id (or a remaster)
    previous_batch = self.account.sis_batches.
      succeeded.where(diffing_data_set_identifier: self.diffing_data_set_identifier).
      where("diffing_remaster = 't' OR generated_diff_id IS NOT NULL").order(:created_at).last
    # otherwise, the previous one may have been the first batch so fallback to the original query
    previous_batch ||= self.account.sis_batches.
      succeeded.where(diffing_data_set_identifier: self.diffing_data_set_identifier).order(:created_at).first

    previous_zip = previous_batch.try(:download_zip)
    return unless previous_zip

    return if change_threshold && (1-previous_zip.size.to_f/@data_file.size.to_f).abs > (0.01 * change_threshold)

    diffed_data_file = SIS::CSV::DiffGenerator.new(self.account, self).generate(previous_zip.path, @data_file.path)
    return unless diffed_data_file

    self.data[:diffed_against_sis_batch_id] = previous_batch.id

    self.generated_diff = SisBatch.create_data_attachment(
      self,
      Rack::Test::UploadedFile.new(diffed_data_file.path, 'application/zip'),
      t(:diff_filename, "sis_upload_diffed_%{id}.zip", :id => self.id)
    )
    self.save!
    # Success, swap out the original update for this new diff and continue.
    @data_file.try(:close)
    @data_file = diffed_data_file
  end

  def download_zip
    if self.data[:file_path]
      @data_file = File.open(self.data[:file_path], 'rb')
    else
      @data_file = self.attachment.open(:need_local_file => true)
    end
    @data_file
  end

  def finish(import_finished)
    @data_file&.close
    @data_file = nil
    return self if workflow_state == 'aborted'
    remove_previous_imports if self.batch_mode? && import_finished
    import_finished = !self.sis_batch_errors.failed.exists? if import_finished
    finalize_workflow_state(import_finished)
    write_errors_to_file
    populate_old_warnings_and_errors
    self.progress = 100 if import_finished
    self.ended_at = Time.now.utc
    self.save!

    if self.class.use_parallel_importers?(account)
      # set waiting jobs as available - or queue another job if there are none
      if Delayed::Job.where(:strand => self.class.strand_for_account(account), :locked_by => nil).update_all(:run_at => Time.now.utc) == 0
        self.class.queue_job_for_account(account)
      end
    end
  end

  def finalize_workflow_state(import_finished)
    if import_finished
      return if workflow_state == 'aborted'
      self.workflow_state = :imported
      self.workflow_state = :imported_with_messages if self.sis_batch_errors.exists?
    else
      self.workflow_state = :failed
      self.workflow_state = :failed_with_messages if self.sis_batch_errors.exists?
    end
  end

  def batch_mode_terms
    if self.options[:multi_term_batch_mode]
      @terms ||= EnrollmentTerm.where(sis_batch_id: self)
      unless @terms.exists?
        abort_batch
        batch_aborted(t('Terms not found. Terms must be included with multi_term_batch_mode'))
      end
      @terms
    else
      self.batch_mode_term
    end
  end

  def term_course_scope
    if data[:supplied_batches].include?(:course)
      scope = account.all_courses.active.where.not(sis_batch_id: nil, sis_source_id: nil)
      scope.where(enrollment_term_id: batch_mode_terms)
    end
  end

  def non_batch_courses_scope
    if data[:supplied_batches].include?(:course)
      term_course_scope.where.not(sis_batch_id: self)
    end
  end

  def remove_non_batch_courses(courses, total_rows, current_row)
    # delete courses that weren't in this batch, in the selected term
    current_row ||= 0
    courses.find_each do |course|
      course.clear_sis_stickiness(:workflow_state)
      course.skip_broadcasts = true
      course.destroy

      Auditors::Course.record_deleted(course, self.user, :source => :sis, :sis_batch => self)

      current_row += 1
      self.fast_update_progress(current_row.to_f/total_rows * 100)
    end
    self.data[:counts][:batch_courses_deleted] = current_row
    current_row
  end

  def term_sections_scope
    if data[:supplied_batches].include?(:section)
      scope = self.account.course_sections.active.where(courses: {enrollment_term_id: batch_mode_terms})
      scope = scope.where.not(sis_batch_id: nil, sis_source_id: nil)
      scope.joins("INNER JOIN #{Course.quoted_table_name} ON courses.id=COALESCE(nonxlist_course_id, course_id)").readonly(false)
    end
  end

  def non_batch_sections_scope
    if data[:supplied_batches].include?(:section)
      term_sections_scope.where.not(sis_batch_id: self)
    end
  end

  def remove_non_batch_sections(sections, total_rows, current_row)
    section_count = 0
    current_row ||= 0
    # delete sections who weren't in this batch, whose course was in the selected term
    sections.find_each do |section|
      section.destroy
      section_count += 1
      current_row += 1
      self.fast_update_progress(current_row.to_f/total_rows * 100)
    end
    self.data[:counts][:batch_sections_deleted] = section_count
    current_row
  end

  def term_enrollments_scope
    if data[:supplied_batches].include?(:enrollment)
      scope = self.account.enrollments.active.joins(:course).readonly(false).where.not(sis_batch_id: nil)
      scope.where(courses: {enrollment_term_id: batch_mode_terms})
    end
  end

  def non_batch_enrollments_scope
    if data[:supplied_batches].include?(:enrollment)
      term_enrollments_scope.where.not(sis_batch_id: self)
    end
  end

  def remove_non_batch_enrollments(enrollments, total_rows, current_row)
    enrollment_count = 0
    current_row ||= 0
    # delete enrollments for courses that weren't in this batch, in the selected term
    enrollments.find_in_batches do |batch|
      if account.feature_enabled?(:refactor_of_sis_imports)
        count = Enrollment::BatchStateUpdater.destroy_batch(batch)
        enrollment_count += count
        current_row += count
      else
        batch.each do |enrollment|
          enrollment.destroy
          enrollment_count += 1
          current_row += 1
        end
      end
      self.fast_update_progress(current_row.to_f/total_rows * 100)
    end
    self.data[:counts][:batch_enrollments_deleted] = enrollment_count
    current_row
  end

  def remove_previous_imports
    # we shouldn't be able to get here without a term, but if we do, skip
    return unless self.batch_mode_term || options[:multi_term_batch_mode]
    supplied_batches = data[:supplied_batches].dup.keep_if { |i| [:course, :section, :enrollment].include? i }
    return unless supplied_batches.present?
    begin
      batch_mode_terms if options[:multi_term_batch_mode]
      SisBatch.where(id: self).update_all(workflow_state: 'cleanup_batch')

      count = 0
      courses = non_batch_courses_scope
      sections = non_batch_sections_scope
      enrollments = non_batch_enrollments_scope

      count = detect_changes(count, courses, enrollments, sections)
      row = remove_non_batch_enrollments(enrollments, count, row) if enrollments
      row = remove_non_batch_sections(sections, count, row) if sections
      remove_non_batch_courses(courses, count, row) if courses
    rescue SisBatch::Aborted
      return self.reload
    end
  end

  def detect_changes(count, courses, enrollments, sections)
    all_count = 0

    if courses
      count += courses.count
      all_count += term_course_scope.count
      detect_change_item(count, all_count, 'courses')
    end

    if sections
      s_count = sections.count
      count += s_count
      s_all_count = term_sections_scope.count
      detect_change_item(s_count, s_all_count, 'sections')
    end

    if enrollments
      e_count = enrollments.count
      count += e_count
      e_all_count = term_enrollments_scope.count
      detect_change_item(e_count, e_all_count, 'enrollments')
    end

    count
  end

  def detect_change_item(count, all_count, type)
    if change_threshold && count.to_f/all_count*100 > change_threshold
      abort_batch
      message = change_detected_message(count, type)
      batch_aborted(message)
    end
  end

  def change_detected_message(count, type)
    t("%{count} %{type} would be deleted and exceeds the set threshold of %{change_threshold}%",
      count: count, type: type, change_threshold: change_threshold)
  end

  def as_json(options={})
    self.options ||= {} # set this to empty hash if it does not exist so options[:stuff] doesn't blow up
    data = {
      "id" => self.id,
      "created_at" => self.created_at,
      "started_at" => self.started_at,
      "ended_at" => self.ended_at,
      "updated_at" => self.updated_at,
      "progress" => self.progress,
      "workflow_state" => self.workflow_state,
      "data" => self.data,
      "batch_mode" => self.batch_mode,
      "batch_mode_term_id" => self.batch_mode_term ? self.batch_mode_term.id : nil,
      "multi_term_batch_mode" => self.options[:multi_term_batch_mode],
      "override_sis_stickiness" => self.options[:override_sis_stickiness],
      "add_sis_stickiness" => self.options[:add_sis_stickiness],
      "clear_sis_stickiness" => self.options[:clear_sis_stickiness],
      "diffing_data_set_identifier" => self.diffing_data_set_identifier,
      "diffed_against_import_id" => self.options[:diffed_against_sis_batch_id],
      "diffing_drop_status" => self.options[:diffing_drop_status],
      "skip_deletes" => self.options[:skip_deletes],
      "change_threshold" => self.change_threshold,
    }
    data["processing_errors"] = self.processing_errors if self.processing_errors.present?
    data["processing_warnings"] = self.processing_warnings if self.processing_warnings.present?
    data
  end

  def populate_old_warnings_and_errors
    fail_count = self.sis_batch_errors.failed.count
    warning_count = self.sis_batch_errors.warnings.count
    self.processing_errors = self.sis_batch_errors.failed.limit(24).pluck(:file, :message)
    self.processing_warnings = self.sis_batch_errors.warnings.limit(24).pluck(:file, :message)
    if fail_count > 24
      self.processing_errors << ["and #{fail_count - 24} more errors that were not included",
                                 "Download the error file to see all errors."]
    end
    if warning_count > 24
      self.processing_warnings << ["and #{warning_count - 24} more warnings that were not included",
                                   "Download the error file to see all warnings."]
    end
    self.data ||= {}
    self.data[:counts] ||= {}
    self.data[:counts][:error_count] = fail_count
    self.data[:counts][:warning_count] = warning_count
  end

  def write_errors_to_file
    return unless self.sis_batch_errors.exists?
    file = temp_error_file_path
    CSV.open(file, "w") do |csv|
      csv << %w(sis_import_id file message row)
      self.sis_batch_errors.find_each do |error|
        row = []
        row << error.sis_batch_id
        row << error.file
        row << error.message
        row << error.row
        csv << row
      end
    end
    self.errors_attachment = SisBatch.create_data_attachment(
      self,
      Rack::Test::UploadedFile.new(file, 'csv', true),
      "sis_errors_attachment_#{id}.csv"
    )
  end

  def temp_error_file_path
    temp = Tempfile.open([self.global_id.to_s + '_processing_warnings_and_errors' + Time.zone.now.to_s, '.csv'])
    file = temp.path
    temp.close!
    file
  end
end
