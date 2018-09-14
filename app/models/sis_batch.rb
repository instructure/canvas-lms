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
  has_many :roll_back_data, inverse_of: :sis_batch, class_name: 'SisBatchRollBackData', autosave: false
  has_many :progresses, inverse_of: :sis_batch
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

  set_policy do
    given { |user| self.account.grants_any_right?(user, :manage_sis, :import_sis) }
    can :read
  end

  # If you are going to change any settings on the batch before it's processed,
  # do it in the block passed into this method, so that the changes are saved
  # before the batch is marked created and eligible for processing.
  def self.create_with_attachment(account, import_type, attachment, user = nil)
    account.shard.activate do
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
  end

  def self.create_data_attachment(batch, data, display_name)
    batch.shard.activate do
      Attachment.new.tap do |att|
        Attachment.skip_3rd_party_submits(true)
        att.context = batch
        att.display_name = display_name
        Attachments::Storage.store_for_attachment(att, data)
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
    state :restoring
    state :partially_restored
    state :restored
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
    job_args = {:priority => Delayed::LOW_PRIORITY, :max_attempts => 1,
      :singleton => strand_for_account(account)}

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
    self.reload # might have failed trying to save
    self.data ||= {}
    self.data[:error_message] = e.to_s
    self.data[:stack_trace] = "#{e}\n#{e.backtrace.join("\n")}"
    self.workflow_state = "failed"
    self.save
  end

  def abort_batch
    SisBatch.not_completed.where(id: self).update_all(workflow_state: 'aborted')
    self.class.queue_job_for_account(account, 10.minutes.from_now) if self.account.sis_batches.needs_processing.exists?
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

  def self.strand_for_account(account)
    "sis_batch:account:#{Shard.birth.activate { account.id }}"
  end

  def skip_deletes?
    self.options ||= {}
    !!self.options[:skip_deletes]
  end

  def self.process_all_for_account(account)
    account.shard.activate do
      return if account.sis_batches.importing.exists? # will requeue after the current batch finishes
      start_time = Time.zone.now
      loop do
        batches = account.sis_batches.needs_processing.limit(50).order(:created_at).preload(:attachment).to_a
        break if batches.empty?
        batches.each do |batch|
          batch.process_without_send_later
          return if batch.importing? # we'll requeue afterwards
          if Time.zone.now - start_time > Setting.get('max_time_per_sis_batch', 60).to_i
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
    diff_result = generate_diff
    if diff_result == :empty_diff_file
      self.finish(true)
      return
    end

    SIS::CSV::ImportRefactored.process(self.account,
                                       files: [@data_file.path],
                                       batch: self,
                                       override_sis_stickiness: options[:override_sis_stickiness],
                                       add_sis_stickiness: options[:add_sis_stickiness],
                                       clear_sis_stickiness: options[:clear_sis_stickiness])
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

    if change_threshold && (1-previous_zip.size.to_f/@data_file.size.to_f).abs > (0.01 * change_threshold)
      SisBatch.add_error(nil, "Diffing not performed because file size difference exceeded threshold", sis_batch: self)
      return
    end

    diffed_data_file = SIS::CSV::DiffGenerator.new(self.account, self).generate(previous_zip.path, @data_file.path)
    return :empty_diff_file unless diffed_data_file # just end if there's nothing to import

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
    @has_errors = self.sis_batch_errors.exists?
    import_finished = !(@has_errors && self.sis_batch_errors.failed.exists?) if import_finished
    finalize_workflow_state(import_finished)
    write_errors_to_file
    populate_old_warnings_and_errors
    statistics
    self.progress = 100 if import_finished
    self.ended_at = Time.now.utc
    self.save!

    if !self.data[:running_immediately] && self.account.sis_batches.needs_processing.exists?
      self.class.queue_job_for_account(account) # check if there's anything that needs to be run
    end
  end

  def finalize_workflow_state(import_finished)
    if import_finished
      return if workflow_state == 'aborted'
      self.workflow_state = :imported
      self.workflow_state = :imported_with_messages if @has_errors
    else
      self.workflow_state = :failed
      self.workflow_state = :failed_with_messages if @has_errors
    end
  end

  def statistics
    stats = {}
    stats[:total_state_changes] = roll_back_data.count
    SisBatchRollBackData::RESTORE_ORDER.each do |type|
      stats[type.to_sym] = {}
      deleted_state = case type
                      when CommunicationChannel
                        'retired'
                      else
                        'deleted'
                      end
      stats[type.to_sym][:created] = roll_back_data.where(context_type: type).where(previous_workflow_state: 'non-existent').count
      stats[type.to_sym][:deleted] = roll_back_data.where(context_type: type).where(updated_workflow_state: deleted_state).count
    end
    self.data ||= {}
    self.data[:statistics] = stats
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
    courses.find_in_batches do |batch|
      count = Course.destroy_batch(batch, sis_batch: self, batch_mode: true)
      finish_course_destroy(batch)
      current_row += count
      self.fast_update_progress(current_row.to_f / total_rows * 100)
    end

    self.data[:counts][:batch_courses_deleted] = current_row
    current_row
  end

  def finish_course_destroy(courses)
    courses.each do |course|
      Auditors::Course.record_deleted(course, self.user, source: :sis, sis_batch: self)
      og_sticky = course.stuck_sis_fields
      course.clear_sis_stickiness(:workflow_state)
      course.skip_broadcasts = true
      course.save! unless og_sticky == course.stuck_sis_fields
    end
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
    sections.find_in_batches do |batch|
      count = CourseSection.destroy_batch(batch, sis_batch: self, batch_mode: true)
      section_count += count
      current_row += count
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
      data = Enrollment::BatchStateUpdater.destroy_batch(batch, sis_batch: self, batch_mode: true)
      SisBatchRollBackData.bulk_insert_roll_back_data(data)
      batch_count = data.count{|d| d.context_type == "Enrollment"} # data can include group membership deletions
      enrollment_count += batch_count
      current_row += batch_count
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
    self.data ||= {}
    self.data[:counts] ||= {}
    unless @has_errors
      self.data[:counts][:error_count] = 0
      self.data[:counts][:warning_count] = 0
      return
    end
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
    self.data[:counts][:error_count] = fail_count
    self.data[:counts][:warning_count] = warning_count
  end

  def write_errors_to_file
    return unless @has_errors
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

  def update_restore_progress(restore_progress, data, count, total)
    count += roll_back_data.active.where(id: data).update_all(workflow_state: 'restored', updated_at: Time.zone.now)
    restore_progress&.calculate_completion!(count, total)
    count
  end

  def restore_states_for_type(type, scope, restore_progress, count, total)
    case type
    when 'GroupCategory'
      restore_group_categories(scope, restore_progress, count, total)
    when 'Enrollment'
      restore_enrollment_data(scope, restore_progress, count, total)
    else
      restore_workflow_states(scope, type, restore_progress, count, total)
    end
  end

  def restore_enrollment_data(scope, restore_progress, count, total)
    Shackles.activate(:slave) do
      scope.active.where(previous_workflow_state: 'deleted').find_in_batches do |batch|
        Shackles.activate(:master) do
          Enrollment::BatchStateUpdater.destroy_batch(batch.map(&:context_id))
          count = update_restore_progress(restore_progress, batch, count, total)
        end
      end
      Shackles.activate(:master) do
        count = restore_workflow_states(scope, 'Enrollment', restore_progress, count, total)
      end
    end
    count
  end

  def restore_group_categories(scope, restore_progress, count, total)
    Shackles.activate(:slave) do
      scope.active.where(previous_workflow_state: 'active').find_in_batches do |gcs|
        Shackles.activate(:master) do
          GroupCategory.where(id: gcs.map(&:context_id)).update_all(deleted_at: nil, updated_at: Time.zone.now)
          count = update_restore_progress(restore_progress, gcs, count, total)
        end
      end
      scope.active.where.not(previous_workflow_state: 'active').find_in_batches do |gcs|
        Shackles.activate(:master) do
          GroupCategory.where(id: gcs.map(&:context_id)).update_all(deleted_at: Time.zone.now, updated_at: Time.zone.now)
          count = update_restore_progress(restore_progress, gcs, count, total)
        end
      end
    end
    count
  end

  def restore_workflow_states(scope, type, restore_progress, count, total)
    count = 0
    Shackles.activate(:slave) do
      scope.active.order(:context_id).find_in_batches(batch_size: 5_000) do |data|
        Shackles.activate(:master) do
          ActiveRecord::Base.unique_constraint_retry do |retry_count|
            if retry_count == 0
              # restore the items and return the ids of the items that changed
              ids = type.constantize.connection.select_values(restore_sql(type, data.map(&:to_restore_array)))
              if type == 'Enrollment'
                ids.each_slice(1000) {|slice| Enrollment::BatchStateUpdater.send_later(:run_call_backs_for, slice)}
              end
              count += update_restore_progress(restore_progress, data, count, total)
            else
              # try to restore each row one at a time
              successful_ids = []
              failed_data = []
              data.each do |row|
                ActiveRecord::Base.unique_constraint_retry do |retry_count|
                  if retry_count == 0
                    successful_ids += type.constantize.connection.select_values(restore_sql(type, [row.to_restore_array]))
                  else
                    failed_data << row
                    SisBatch.add_error(nil, "Couldn't rollback SIS batch data for row - #{row.inspect}", sis_batch: self)
                  end
                end
              end
              successful_ids.each_slice(1000) {|slice| Enrollment::BatchStateUpdater.send_later(:run_call_backs_for, slice)}
              count += update_restore_progress(restore_progress, data - failed_data, count, total)
              roll_back_data.active.where(id: failed_data).update_all(workflow_state: 'failed', updated_at: Time.zone.now)
            end
          end
        end
      end
    end
    count
  end

  def restore_states_later(batch_mode: nil, undelete_only: false, unconclude_only: false)
    self.shard.activate do
      restore_progress = Progress.create! context: self, tag: "sis_batch_state_restore", completion: 0.0
      restore_progress.process_job(self, :restore_states_for_batch,
                                   {n_strand: "restore_states_for_batch:#{account.global_id}}"},
                                   {batch_mode: batch_mode, undelete_only: undelete_only, unconclude_only: unconclude_only})
      restore_progress
    end
  end

  def restore_states_for_batch(restore_progress=nil, batch_mode: nil, undelete_only: false, unconclude_only: false)
    restore_progress&.start
    self.update_attribute(:workflow_state, 'restoring')
    roll_back = self.roll_back_data
    roll_back = roll_back.where(updated_workflow_state: %w(retired deleted)) if undelete_only
    roll_back = roll_back.where(updated_workflow_state: %w(completed)) if unconclude_only
    roll_back = roll_back.where(batch_mode_delete: batch_mode) if batch_mode
    types = roll_back.active.distinct.order(:context_type).pluck(:context_type)
    total = roll_back.active.count if restore_progress
    count = 0
    SisBatchRollBackData::RESTORE_ORDER.each do |type|
      next unless types.include? type
      scope = roll_back.where(context_type: type)
      count = restore_states_for_type(type, scope, restore_progress, count, total)
    end
    add_restore_statistics
    restore_progress&.complete
    self.workflow_state = (undelete_only || unconclude_only || batch_mode) ? 'partially_restored' : 'restored'
    self.save!
  end

  def add_restore_statistics
    statistics unless self&.data&.key? :statistics
    stats = self.data[:statistics]
    stats ||= {}
    SisBatchRollBackData::RESTORE_ORDER.each do |type|
      stats[type.to_sym] ||= {}
      stats[type.to_sym][:restored] = roll_back_data.restored.where(context_type: type).count
    end
    self.data[:statistics] = stats
  end

  # returns values "(1,'deleted'),(2,'deleted'),(3,'other_state'),(4,'active')"
  def to_sql_values(data)
    data.map { |v| "(#{v.first},'#{v.last}')" }.join(',')
  end

  def restore_sql(type, data)
    <<-SQL
      UPDATE #{type.constantize.quoted_table_name} AS t
        SET workflow_state = x.workflow_state,
            updated_at = NOW()
        FROM (VALUES #{to_sql_values(data)}) AS x(id, workflow_state)
        WHERE t.id=x.id AND x.workflow_state IS DISTINCT FROM t.workflow_state
        RETURNING t.id
    SQL
  end

  attr_writer :downloadable_attachments
  def self.load_downloadable_attachments(batches)
    batches = Array(batches)
    all_ids = batches.map{|sb| sb.data&.dig(:downloadable_attachment_ids) || []}.flatten
    all_attachments = all_ids.any? ? Attachment.where(:context_type => self.name, :context_id => batches, :id => all_ids).to_a.group_by(&:context_id) : {}
    batches.each do |b|
      b.downloadable_attachments = all_attachments[b.id] || []
    end
  end

  def downloadable_attachments
    @downloadable_attachments ||=
      begin
        ids = data[:downloadable_attachment_ids]
        if ids.present?
          self.shard.activate { Attachment.where(:id => ids).polymorphic_where(:context => self).to_a }
        else
          []
        end
      end
  end
end
