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

class SisBatch < ActiveRecord::Base
  include Workflow
  include CaptureJobIds
  belongs_to :account
  serialize :data
  serialize :options, type: Hash
  serialize :processing_errors, type: Array
  serialize :processing_warnings, type: Array
  belongs_to :attachment
  belongs_to :errors_attachment, class_name: "Attachment"
  has_many :parallel_importers, inverse_of: :sis_batch
  has_many :sis_batch_errors, inverse_of: :sis_batch, autosave: false
  has_many :roll_back_data, inverse_of: :sis_batch, class_name: "SisBatchRollBackData", autosave: false
  has_many :progresses, inverse_of: :sis_batch
  belongs_to :generated_diff, class_name: "Attachment"
  belongs_to :batch_mode_term, class_name: "EnrollmentTerm"
  belongs_to :user
  has_many :auditor_course_records,
           class_name: "Auditors::ActiveRecord::CourseRecord",
           dependent: :destroy,
           inverse_of: :course

  validates :account_id, :workflow_state, presence: true
  validates :diffing_data_set_identifier, length: { maximum: 128 }

  attr_accessor :zip_path

  def self.valid_import_types
    @valid_import_types ||= {
      "instructure_csv" => {
        name: -> { t(:instructure_csv, "Instructure formatted CSV or zipfile of CSVs") },
        callback: ->(batch) { batch.process_instructure_csv_zip },
        default: true
      }
    }
  end

  set_policy do
    given { |user| account.grants_any_right?(user, :manage_sis, :import_sis) }
    can :read
  end

  # If you are going to change any settings on the batch before it's processed,
  # do it in the block passed into this method, so that the changes are saved
  # before the batch is marked created and eligible for processing.
  def self.create_with_attachment(account, import_type, file_obj, user = nil)
    account.shard.activate do
      batch = SisBatch.new
      batch.account = account
      batch.progress = 0
      batch.workflow_state = :initializing
      batch.data = { import_type: }
      batch.user = user
      batch.save

      att = Attachment.create_data_attachment(batch, file_obj, file_obj.original_filename)
      batch.attachment = att

      yield batch if block_given?
      batch.workflow_state = :created
      batch.save!

      batch
    end
  end

  def self.add_error(csv, message, sis_batch:, row: nil, failure: false, backtrace: nil, row_info: nil)
    error = build_error(csv, message, row:, failure:, backtrace:, row_info:, sis_batch:)
    error.save!
  end

  def self.build_error(csv, message, sis_batch:, row: nil, failure: false, backtrace: nil, row_info: nil)
    file = csv ? csv[:file] : nil
    sis_batch.sis_batch_errors.build(root_account: sis_batch.account,
                                     file:,
                                     message:,
                                     failure:,
                                     backtrace:,
                                     row_info:,
                                     row:,
                                     created_at: Time.zone.now)
  end

  def self.bulk_insert_sis_errors(errors)
    errors.each_slice(1000) do |batch|
      SisBatchError.bulk_insert_objects(batch)
    end
  end

  def self.rows_for_parallel(rows)
    # Try to have N jobs but also bound the minimum and maximum number of rows a job will process.
    # Progress is calculated on the number of jobs remaining.
    num_jobs, min_rows, max_rows = Setting.get("sis_batch_rows_for_parallel",
                                               "99,100,1000").split(",").map(&:to_i)
    (rows / num_jobs.to_f).ceil.clamp(min_rows, max_rows)
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
    self.class.queue_job_for_account(account)
  end

  def enable_diffing(data_set_identifier, is_remaster)
    if data[:import_type] == "instructure_csv"
      self.diffing_data_set_identifier = data_set_identifier
      self.diffing_remaster = is_remaster
    end
  end

  class Aborted < RuntimeError; end

  def self.queue_job_for_account(account, run_at = nil)
    job_args = { priority: Delayed::LOW_PRIORITY,
                 max_attempts: 1,
                 singleton: strand_for_account(account) }

    if run_at
      job_args[:run_at] = run_at
    else
      process_delay = Setting.get("sis_batch_process_start_delay", "0").to_f
      if process_delay > 0
        job_args[:run_at] = process_delay.seconds.from_now
      end
    end

    work = SisBatch::Work.new(SisBatch, :process_all_for_account, args: [account])
    Delayed::Job.enqueue(work, **job_args)
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
      }
      account.delay(**job_args).update_account_associations
    end
  end

  # this method name is to stay backwards compatible with existing jobs when we deploy
  # once no SisBatch#process_without_send_later jobs are being created anymore, we
  # can rename this to something more sensible.
  def process_without_send_later
    return_after_transaction = false
    self.class.transaction do
      case workflow_state
      when "aborted"
        self.progress = 100
        save
        return_after_transaction = true
      when "created"
        self.workflow_state = :importing
        self.progress = 0
        self.started_at = Time.now.utc
        capture_job_id
        save
      else
        return_after_transaction = true
      end
    end
    return if return_after_transaction

    import_scheme = SisBatch.valid_import_types[data[:import_type]]
    if import_scheme.nil?
      data[:error_message] = t "errors.unrecorgnized_type", "Unrecognized import type"
      self.workflow_state = :failed
      save
      return
    end

    import_scheme[:callback].call(self)
  rescue => e
    reload # might have failed trying to save
    self.data ||= {}
    self.data[:error_message] = e.to_s
    self.data[:stack_trace] = "#{e}\n#{e.backtrace.join("\n")}"
    self.workflow_state = "failed"
    save
  end

  def abort_batch
    SisBatch.not_completed.where(id: self).update_all(workflow_state: "aborted", updated_at: Time.zone.now)
    self.class.queue_job_for_account(account, 10.minutes.from_now) if account.sis_batches.needs_processing.exists?
  end

  def batch_aborted(message)
    SisBatch.add_error(nil, message, sis_batch: self)
    raise SisBatch::Aborted
  end

  def self.abort_all_pending_for_account(account)
    transaction do
      account.sis_batches.not_started.lock(:no_key_update).order(:id).find_in_batches do |batch|
        SisBatch.where(id: batch).update_all(workflow_state: "aborted", progress: 100)
      end
    end
  end

  scope :not_started, -> { where(workflow_state: ["initializing", "created"]) }
  scope :needs_processing, -> { where(workflow_state: "created").order(:created_at) }
  scope :importing, -> { where(workflow_state: ["importing", "cleanup_batch"]) }
  scope :not_completed, -> { where(workflow_state: %w[initializing created importing cleanup_batch]) }
  scope :succeeded, -> { where(workflow_state: %w[imported imported_with_messages]) }

  def self.strand_for_account(account)
    "sis_batch:account:#{Shard.birth.activate { account.id }}"
  end

  def skip_deletes?
    !!options[:skip_deletes]
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

          next unless Time.zone.now - start_time > Setting.get("max_time_per_sis_batch", 60).to_i

          # requeue the job to continue processing more batches
          queue_job_for_account(account)
          return
        end
      end
    end
  end

  def fast_update_progress(val)
    return true if val == progress

    self.progress = val
    state = SisBatch.connection.select_value(sanitize_sql([<<~SQL.squish, val, id]))
      UPDATE #{SisBatch.quoted_table_name} SET progress=?, updated_at=NOW() WHERE id=? RETURNING workflow_state
    SQL
    raise SisBatch::Aborted if state == "aborted"
  end

  def importing?
    workflow_state == "importing" ||
      workflow_state == "created" ||
      workflow_state == "cleanup_batch"
  end

  def process_instructure_csv_zip
    require "sis"
    download_zip
    diff_result = generate_diff
    if diff_result == :empty_diff_file
      finish(true)
      return
    end

    SIS::CSV::ImportRefactored.process(account,
                                       files: [@data_file.path],
                                       batch: self,
                                       override_sis_stickiness: options[:override_sis_stickiness],
                                       add_sis_stickiness: options[:add_sis_stickiness],
                                       clear_sis_stickiness: options[:clear_sis_stickiness])
  end

  def compute_file_size(file)
    CanvasUnzip.compute_uncompressed_size(file.path)
  rescue CanvasUnzip::UnknownArchiveType
    # if it's not a zip file, just return the size of the file itself
    file.size
  end

  def generate_diff
    return if diffing_remaster # joined the chain, but don't actually want to diff this one
    return unless diffing_data_set_identifier

    # the previous batch may not have had diffing applied because of the change_threshold,
    # so look for the latest one with a generated_diff_id (or a remaster)
    previous_batch = account.sis_batches
                            .succeeded.where(diffing_data_set_identifier:)
                            .where("diffing_remaster = 't' OR generated_diff_id IS NOT NULL").order(:created_at).last
    # otherwise, the previous one may have been the first batch so fallback to the original query
    previous_batch ||= account.sis_batches
                              .succeeded.where(diffing_data_set_identifier:).order(:created_at).first

    previous_zip = previous_batch.try(:download_zip)
    return unless previous_zip

    current_file_size = compute_file_size(@data_file)
    previous_zip_size = compute_file_size(previous_zip)
    if change_threshold && file_diff_percent(current_file_size, previous_zip_size) > change_threshold
      self.diffing_threshold_exceeded = true
      SisBatch.add_error(nil, "Diffing not performed because file size difference exceeded threshold", sis_batch: self)
      return
    end

    diff = SIS::CSV::DiffGenerator.new(account, self).generate(previous_zip.path, @data_file.path)
    return :empty_diff_file unless diff # just end if there's nothing to import

    diffed_data_file = diff[:file_io]

    if diff_row_count_threshold && diff[:row_count] > diff_row_count_threshold
      diffed_data_file.close
      self.diffing_threshold_exceeded = true
      SisBatch.add_error(nil, "Diffing not performed because difference row count exceeded threshold", sis_batch: self)
      return
    end

    self.diffing_threshold_exceeded = false

    self.data[:diffed_against_sis_batch_id] = previous_batch.id

    self.generated_diff = Attachment.create_data_attachment(
      self,
      Canvas::UploadedFile.new(diffed_data_file.path, "application/zip"),
      t(:diff_filename, "sis_upload_diffed_%{id}.zip", id:)
    )
    save!
    # Success, swap out the original update for this new diff and continue.
    @data_file.try(:close)
    @data_file = diffed_data_file
  end

  def diff_row_count_threshold=(val)
    options[:diff_row_count_threshold] = val
  end

  def diff_row_count_threshold
    options[:diff_row_count_threshold]
  end

  def file_diff_percent(current_file_size, previous_zip_size)
    (1 - (current_file_size.to_f / previous_zip_size.to_f)).abs * 100
  end

  def download_zip
    @data_file = if self.data[:file_path]
                   File.open(self.data[:file_path], "rb")
                 else
                   attachment.open(integrity_check: true)
                 end
    @data_file
  end

  def finish(import_finished)
    @data_file&.close
    @data_file = nil
    return self if workflow_state == "aborted"

    if batch_mode? && import_finished && !self.data[:running_immediately]
      # in batch mode, there's still a lot of work left to do, and it needs to be done in a separate job
      # from the last ParallelImporter or a failed job will retry that bit of the import (and not the batch cleanup!)
      save!
      delay(
        priority: Delayed::LOW_PRIORITY,
        max_attempts: Setting.get("sis_import_cleanup_batch_attempts", "1").to_i
      )
        .do_batch_end_work(import_finished)
    else
      do_batch_end_work(import_finished)
    end
  end

  def do_batch_end_work(import_finished)
    remove_previous_imports if batch_mode? && import_finished
    @has_errors = sis_batch_errors.exists?
    import_finished = !(@has_errors && sis_batch_errors.failed.exists?) if import_finished
    finalize_workflow_state(import_finished)
    delay_if_production(max_attempts: 5).write_errors_to_file if @has_errors
    populate_old_warnings_and_errors
    statistics
    self.progress = 100 if import_finished
    self.ended_at = Time.now.utc
    save!
    InstStatsd::Statsd.increment("sis_batch_completed", tags: { failed: @has_errors })

    if !self.data[:running_immediately] && account.sis_batches.needs_processing.exists?
      self.class.queue_job_for_account(account) # check if there's anything that needs to be run
    end
  end

  def finalize_workflow_state(import_finished)
    if import_finished
      return if workflow_state == "aborted"

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
    # add statistics with all types but only query types that were imported.
    stats = add_zero_stats(stats)
    types = roll_back_data.distinct.order(:context_type).pluck(:context_type)
    types.each do |type|
      stats[type.to_sym] = {}
      stats[type.to_sym][:created] = roll_back_data.where(context_type: type)
                                                   .where(previous_workflow_state: ["non-existent", "creation_pending"],
                                                          updated_workflow_state: stat_active_state(type)).count

      stats[type.to_sym][:restored] = roll_back_data.where(context_type: type)
                                                    .where(previous_workflow_state: stat_restored_from(type),
                                                           updated_workflow_state: stat_active_state(type)).count
      if ["Course", "Enrollment"].include? type
        stats[type.to_sym][:concluded] = roll_back_data
                                         .where(context_type: type, updated_workflow_state: "completed").count
      end

      if type == "Enrollment"
        stats[type.to_sym][:deactivated] = roll_back_data
                                           .where(context_type: type, updated_workflow_state: "inactive").count
      end

      stats[type.to_sym][:deleted] = roll_back_data.where(context_type: type)
                                                   .where(updated_workflow_state: stat_deleted_state(type)).count
    end
    self.data ||= {}
    self.data[:statistics] = stats
  end

  def add_zero_stats(stats)
    SisBatchRollBackData::RESTORE_ORDER.each do |type|
      stats[type.to_sym] = {}
      stats[type.to_sym][:created] = 0
      stats[type.to_sym][:restored] = 0
      stats[type.to_sym][:concluded] = 0 if ["Course", "Enrollment"].include? type
      stats[type.to_sym][:deactivated] = 0 if type == "Enrollment"
      stats[type.to_sym][:deleted] = 0
    end
    stats
  end

  def stat_active_state(type)
    case type
    when "GroupMembership"
      "accepted"
    when "Group"
      "available"
    when "Course"
      %w[claimed created available]
    else
      "active"
    end
  end

  def stat_deleted_state(type)
    case type
    when "CommunicationChannel"
      "retired"
    else
      "deleted"
    end
  end

  def stat_restored_from(type)
    case type
    when "CommunicationChannel"
      ["retired", "unconfirmed"]
    when "Course"
      ["completed", "deleted"]
    when "Enrollment"
      %w[inactive completed rejected deleted]
    else
      "deleted"
    end
  end

  def batch_mode_terms
    if options[:multi_term_batch_mode]
      @terms ||= EnrollmentTerm.where(sis_batch_id: self)
      unless @terms.exists?
        abort_batch
        batch_aborted(t("Terms not found. Terms must be included with multi_term_batch_mode"))
      end
      @terms
    else
      batch_mode_term
    end
  end

  def term_course_scope
    if data[:supplied_batches].include?(:course)
      scope = account.all_courses.active.where.not(sis_batch_id: nil).where.not(sis_source_id: nil)
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
    course_count = 0
    current_row ||= 0
    courses.find_in_batches do |batch|
      count = Course.destroy_batch(batch, sis_batch: self, batch_mode: true)
      finish_course_destroy(batch)
      current_row += count
      course_count += count
      fast_update_progress(current_row.to_f / total_rows * 100)
    end

    self.data[:counts][:batch_courses_deleted] = course_count
    current_row
  end

  def finish_course_destroy(courses)
    courses.each do |course|
      Auditors::Course.record_deleted(course, user, source: :sis, sis_batch: self)
      og_sticky = course.stuck_sis_fields
      course.clear_sis_stickiness(:workflow_state)
      course.skip_broadcasts = true
      course.save! unless og_sticky == course.stuck_sis_fields
    end
  end

  def term_sections_scope
    if data[:supplied_batches].include?(:section)
      scope = account.course_sections.active.where(courses: { enrollment_term_id: batch_mode_terms })
      scope = scope.where.not(sis_batch_id: nil).where.not(sis_source_id: nil)
      scope.joins("INNER JOIN #{Course.quoted_table_name} ON courses.id=COALESCE(nonxlist_course_id, course_id)").readonly(false)
    end
  end

  def non_batch_sections_scope
    if data[:supplied_batches].include?(:section)
      term_sections_scope.where.not(sis_batch_id: self)
    end
  end

  def remove_non_batch_sections(sections, _total_rows, current_row)
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
      scope = account.enrollments.active
      if options[:batch_mode_enrollment_drop_status]
        scope = scope.where.not(workflow_state: options[:batch_mode_enrollment_drop_status])
      end
      scope = scope.joins(:course).readonly(false).where.not(sis_batch_id: nil)
      scope.where(courses: { enrollment_term_id: batch_mode_terms })
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
    batch_mode_drop_status = options[:batch_mode_enrollment_drop_status] || "deleted"
    # delete or update enrollments to batch_mode_drop_status for enrollments
    # that weren't in this batch in the batch_mode_term
    enrollments.find_in_batches do |batch|
      data = case batch_mode_drop_status
             when "deleted"
               Enrollment::BatchStateUpdater.destroy_batch(batch, sis_batch: self, batch_mode: true)
             when "completed"
               Enrollment::BatchStateUpdater.complete_batch(batch, sis_batch: self, batch_mode: true, root_account: account)
             when "inactive"
               Enrollment::BatchStateUpdater.inactivate_batch(batch, sis_batch: self, batch_mode: true, root_account: account)
             else
               raise NotImplementedError
             end

      SisBatchRollBackData.bulk_insert_roll_back_data(data)
      batch_count = data.count { |d| d.context_type == "Enrollment" } # data can include group membership deletions
      enrollment_count += batch_count
      current_row += batch_count
      fast_update_progress(current_row.to_f / total_rows * 100)
    end
    self.data[:counts][:batch_enrollments_deleted] = enrollment_count
    current_row
  end

  def remove_previous_imports
    # we should not try to cleanup if the batch didn't work out, we could delete
    # stuff we still need
    current_workflow_state = self.class.where(id:).pluck(:workflow_state).first.to_s
    # ^reloading the whole batch can be a problem because we might be tracking data
    # we haven't persisted yet on model attributes...
    if %w[failed failed_with_messages aborted].include?(current_workflow_state)
      Rails.logger.info("[SIS_BATCH] Refusing to cleanup after batch #{id} because workflow state is #{current_workflow_state}")
      return false
    end
    # we shouldn't be able to get here without a term, but if we do, skip
    return unless batch_mode_term || options[:multi_term_batch_mode]

    supplied_batches = data[:supplied_batches].dup.keep_if { |i| %i[course section enrollment].include? i }
    return unless supplied_batches.present?

    begin
      batch_mode_terms if options[:multi_term_batch_mode]
      SisBatch.where(id: self).update_all(workflow_state: "cleanup_batch")

      count = 0
      courses = non_batch_courses_scope
      sections = non_batch_sections_scope
      enrollments = non_batch_enrollments_scope

      count = detect_changes(count, courses, enrollments, sections)
      row = remove_non_batch_enrollments(enrollments, count, row) if enrollments
      row = remove_non_batch_sections(sections, count, row) if sections
      remove_non_batch_courses(courses, count, row) if courses
    rescue SisBatch::Aborted
      reload
    end
  end

  def detect_changes(count, courses, enrollments, sections)
    all_count = 0

    if courses
      count += courses.count
      all_count += term_course_scope.count
      detect_change_item(count, all_count, "courses")
    end

    if sections
      s_count = sections.count
      count += s_count
      s_all_count = term_sections_scope.count
      detect_change_item(s_count, s_all_count, "sections")
    end

    if enrollments
      e_count = enrollments.count
      count += e_count
      e_all_count = term_enrollments_scope.count
      detect_change_item(e_count, e_all_count, "enrollments")
    end

    count
  end

  def detect_change_item(count, all_count, type)
    if change_threshold && count.to_f / all_count * 100 > change_threshold
      abort_batch
      message = change_detected_message(count, type)
      batch_aborted(message)
    end
  end

  def change_detected_message(count, type)
    t("%{count} %{type} would be deleted and exceeds the set threshold of %{change_threshold}%",
      count:,
      type:,
      change_threshold:)
  end

  def as_json(*)
    data = {
      "id" => id,
      "created_at" => created_at,
      "started_at" => started_at,
      "ended_at" => ended_at,
      "updated_at" => updated_at,
      "progress" => progress,
      "workflow_state" => workflow_state,
      "data" => self.data,
      "batch_mode" => batch_mode,
      "batch_mode_term_id" => batch_mode_term&.id,
      "multi_term_batch_mode" => options[:multi_term_batch_mode],
      "override_sis_stickiness" => options[:override_sis_stickiness],
      "add_sis_stickiness" => options[:add_sis_stickiness],
      "update_sis_id_if_login_claimed" => options[:update_sis_id_if_login_claimed],
      "clear_sis_stickiness" => options[:clear_sis_stickiness],
      "diffing_data_set_identifier" => diffing_data_set_identifier,
      "diffing_remaster" => diffing_remaster,
      "diffed_against_import_id" => options[:diffed_against_sis_batch_id],
      "diffing_drop_status" => options[:diffing_drop_status],
      "diffing_user_remove_status" => options[:diffing_user_remove_status],
      "skip_deletes" => options[:skip_deletes],
      "change_threshold" => change_threshold,
      "diff_row_count_threshold" => options[:diff_row_count_threshold]
    }
    data["processing_errors"] = processing_errors if processing_errors.present?
    data["processing_warnings"] = processing_warnings if processing_warnings.present?
    data["diffing_threshold_exceeded"] = diffing_threshold_exceeded if diffing_data_set_identifier
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
    fail_count = sis_batch_errors.failed.count
    warning_count = sis_batch_errors.warnings.count
    self.processing_errors = sis_batch_errors.failed.limit(24).pluck(:file, :message)
    self.processing_warnings = sis_batch_errors.warnings.limit(24).pluck(:file, :message)
    if fail_count > 24
      processing_errors << ["and #{fail_count - 24} more errors that were not included",
                            "Download the error file to see all errors."]
    end
    if warning_count > 24
      processing_warnings << ["and #{warning_count - 24} more warnings that were not included",
                              "Download the error file to see all warnings."]
    end
    self.data[:counts][:error_count] = fail_count
    self.data[:counts][:warning_count] = warning_count
  end

  def write_errors_to_file
    file = temp_error_file_path
    CSV.open(file, "w") do |csv|
      csv << %w[sis_import_id file message row]
      sis_batch_errors.find_each do |error|
        row = []
        row << error.sis_batch_id
        row << error.file
        row << error.message
        row << error.row
        csv << row
      end
    end
    self.errors_attachment = Attachment.create_data_attachment(
      self,
      Canvas::UploadedFile.new(file, "csv"),
      "sis_errors_attachment_#{id}.csv"
    )
    save! if Rails.env.production?
  end

  def temp_error_file_path
    temp = Tempfile.open([global_id.to_s + "_processing_warnings_and_errors" + Time.zone.now.to_s, ".csv"])
    file = temp.path
    temp.close!
    file
  end

  def update_restore_progress(restore_progress, data, count, total)
    count += roll_back_data.active.where(id: data).update_all(workflow_state: "restored", updated_at: Time.zone.now)
    restore_progress&.calculate_completion!(count, total)
    count
  end

  def restore_states_for_type(type, scope, restore_progress, count, total)
    case type
    when "GroupCategory"
      restore_group_categories(scope, restore_progress, count, total)
    when "Enrollment"
      restore_enrollment_data(scope, restore_progress, count, total)
    else
      restore_workflow_states(scope, type, restore_progress, count, total)
    end
  end

  def restore_enrollment_data(scope, restore_progress, count, total)
    GuardRail.activate(:secondary) do
      scope.active.where(previous_workflow_state: "deleted").find_in_batches do |batch|
        GuardRail.activate(:primary) do
          Enrollment::BatchStateUpdater.destroy_batch(batch.map(&:context_id))
          count = update_restore_progress(restore_progress, batch, count, total)
        end
      end
      GuardRail.activate(:primary) do
        count = restore_workflow_states(scope, "Enrollment", restore_progress, count, total)
      end
    end
    count
  end

  def restore_group_categories(scope, restore_progress, count, total)
    GuardRail.activate(:secondary) do
      scope.active.where(previous_workflow_state: "active").find_in_batches do |gcs|
        GuardRail.activate(:primary) do
          GroupCategory.where(id: gcs.map(&:context_id)).update_all(deleted_at: nil, updated_at: Time.zone.now)
          count = update_restore_progress(restore_progress, gcs, count, total)
        end
      end
      scope.active.where.not(previous_workflow_state: "active").find_in_batches do |gcs|
        GuardRail.activate(:primary) do
          GroupCategory.where(id: gcs.map(&:context_id)).update_all(deleted_at: Time.zone.now, updated_at: Time.zone.now)
          count = update_restore_progress(restore_progress, gcs, count, total)
        end
      end
    end
    count
  end

  def restore_workflow_states(scope, type, restore_progress, count, total)
    GuardRail.activate(:secondary) do
      scope.active.order(:context_id).find_in_batches(batch_size: 5_000) do |data|
        GuardRail.activate(:primary) do
          ActiveRecord::Base.unique_constraint_retry do |retry_count|
            if retry_count == 0
              # restore the items and return the ids of the items that changed
              ids = type.constantize.connection.select_values(restore_sql(type, data.map(&:to_restore_array)))
              finalize_enrollments(ids) if type == "Enrollment"
              count += update_restore_progress(restore_progress, data, count, total)
            else
              # try to restore each row one at a time
              successful_ids = []
              failed_data = []
              data.each do |row|
                ActiveRecord::Base.unique_constraint_retry do |retry_count2|
                  if retry_count2 == 0
                    successful_ids += type.constantize.connection.select_values(restore_sql(type, [row.to_restore_array]))
                  else
                    failed_data << row
                    SisBatch.add_error(nil, "Couldn't rollback SIS batch data for row - #{row.inspect}", sis_batch: self)
                  end
                end
              end
              finalize_enrollments(successful_ids) if type == "Enrollment"
              count += update_restore_progress(restore_progress, data - failed_data, count, total)
              roll_back_data.active.where(id: failed_data).update_all(workflow_state: "failed", updated_at: Time.zone.now)
            end
          end
        end
      end
    end
    count
  end

  def finalize_enrollments(ids)
    ids.each_slice(1000) do |slice|
      Enrollment::BatchStateUpdater.delay(n_strand: ["restore_states_batch_updater", account.global_id])
                                   .run_call_backs_for(slice, root_account: account)
    end
    # we know enrollments are not deleted, but we don't know what the previous
    # state was, we will assume deleted and restore the scores and submissions
    # for students, if it was not deleted, it will not break anything.
    Enrollment.where(id: ids, type: "StudentEnrollment").order(:course_id).preload(:course).find_in_batches do |batch|
      StudentEnrollment.restore_submissions_and_scores_for_enrollments(batch)
    end
  end

  def restore_states_later(batch_mode: nil, undelete_only: false, unconclude_only: false)
    shard.activate do
      restore_progress = Progress.create! context: self, tag: "sis_batch_state_restore", completion: 0.0
      restore_progress.process_job(self,
                                   :restore_states_for_batch,
                                   { n_strand: ["restore_states_for_batch", account.global_id] },
                                   batch_mode:,
                                   undelete_only:,
                                   unconclude_only:)
      restore_progress
    end
  end

  def restore_states_for_batch(restore_progress = nil, batch_mode: false, undelete_only: false, unconclude_only: false)
    restore_progress&.start
    update_attribute(:workflow_state, "restoring")
    roll_back = roll_back_data
    roll_back = roll_back.where(updated_workflow_state: %w[retired deleted]) if undelete_only
    roll_back = roll_back.where(updated_workflow_state: %w[completed]) if unconclude_only
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
    self.workflow_state = (undelete_only || unconclude_only || batch_mode) ? "partially_restored" : "restored"
    tags = { undelete_only:, unconclude_only:, batch_mode: }
    InstStatsd::Statsd.increment("sis_batch_restored", tags:)
    save!
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
    data.map { |v| "(#{v.first},'#{v.last}')" }.join(",")
  end

  def restore_sql(type, data)
    <<~SQL.squish
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
    all_ids = batches.map { |sb| sb.data&.dig(:downloadable_attachment_ids) || [] }.flatten
    all_attachments = all_ids.any? ? Attachment.where(context_type: name, context_id: batches, id: all_ids).to_a.group_by(&:context_id) : {}
    batches.each do |b|
      b.downloadable_attachments = all_attachments[b.id] || []
    end
  end

  def downloadable_attachments(type = :all)
    return [] unless data

    shard.activate do
      @downloadable_attachments ||=
        begin
          ids = data[:downloadable_attachment_ids]
          if ids.present?
            Attachment.where(id: ids, context: self).to_a
          else
            []
          end
        end

      diff_att_ids = data[:diffed_attachment_ids] || []
      case type
      when :all
        @downloadable_attachments
      when :uploaded
        @downloadable_attachments.reject { |att| diff_att_ids.include?(att.id) }
      when :diffed
        @downloadable_attachments.select { |att| diff_att_ids.include?(att.id) }
      else
        raise "invalid attachment type"
      end
    end
  end
end
