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
  has_many :sis_batch_error_files
  belongs_to :generated_diff, class_name: 'Attachment'
  belongs_to :batch_mode_term, class_name: 'EnrollmentTerm'
  belongs_to :user

  before_save :limit_size_of_messages
  after_save :cleanup_error_files_when_finished

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
    Attachment.new.tap do |att|
      Attachment.skip_3rd_party_submits(true)
      att.context = batch
      att.uploaded_data = data
      att.display_name = display_name
      att.save!
    end
  ensure
    Attachment.skip_3rd_party_submits(false)
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

  def add_errors(messages)
    self.processing_errors = (self.processing_errors || []) + messages
  end

  def add_warnings(messages)
    self.processing_warnings = (self.processing_warnings || []) + messages
  end

  def self.queue_job_for_account(account)
    process_delay = Setting.get('sis_batch_process_start_delay', '0').to_f
    job_args = {:singleton => "sis_batch:account:#{Shard.birth.activate { account.id }}",
                :priority => Delayed::LOW_PRIORITY,
                :max_attempts => 1}
    if process_delay > 0
      job_args[:run_at] = process_delay.seconds.from_now
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
    add_errors([[message]])
    self.save!
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

  def self.process_all_for_account(account)
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

    importer = SIS::CSV::Import.process(self.account, :files => [@data_file.path], :batch => self, :override_sis_stickiness => options[:override_sis_stickiness], :add_sis_stickiness => options[:add_sis_stickiness], :clear_sis_stickiness => options[:clear_sis_stickiness])
    finish importer.finished
  end

  def generate_diff
    return if self.diffing_remaster # joined the chain, but don't actually want to diff this one
    return unless self.diffing_data_set_identifier
    previous_batch = self.account.sis_batches.
      succeeded.where(diffing_data_set_identifier: self.diffing_data_set_identifier).order(:created_at).last
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
    compile_all_errors
    finalize_workflow_state(import_finished)
    self.progress = 100
    self.ended_at = Time.now.utc
    self.save!
  end

  def finalize_workflow_state(import_finished)
    if import_finished
      return if workflow_state == 'aborted'
      self.workflow_state = :imported
      self.workflow_state = :imported_with_messages if messages?
    else
      self.workflow_state = :failed
      self.workflow_state = :failed_with_messages if messages?
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

  def remove_non_batch_courses(courses, total_rows)
    # delete courses that weren't in this batch, in the selected term
    current_row = 0
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
    current_row = 0 unless current_row
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
    current_row = 0 unless current_row
    # delete enrollments for courses that weren't in this batch, in the selected term
    enrollments.find_each do |enrollment|
      enrollment.destroy
      enrollment_count += 1
      current_row += 1
      self.fast_update_progress(current_row.to_f/total_rows * 100)
    end
    self.data[:counts][:batch_enrollments_deleted] = enrollment_count
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
      row = remove_non_batch_courses(courses, count) if courses
      row = remove_non_batch_sections(sections, count, row) if sections
      remove_non_batch_enrollments(enrollments, count, row) if enrollments
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
      "created_at" => self.created_at,
      "started_at" => self.started_at,
      "ended_at" => self.ended_at,
      "updated_at" => self.updated_at,
      "progress" => self.progress,
      "id" => self.id,
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
      "change_threshold" => self.change_threshold,
    }
    data["processing_errors"] = self.processing_errors if self.processing_errors.present?
    data["processing_warnings"] = self.processing_warnings if self.processing_warnings.present?
    data
  end

  def self.max_messages
    Setting.get('sis_batch_max_messages', '50').to_i
  end

  private

  def messages?
    self.errors_attachment_id?
  end

  def compile_all_errors
    write_warnings_and_errors_to_file
    all_errors = Set.new
    return unless self.sis_batch_error_files.exists?
    self.sis_batch_error_files.each do |errors|
      CSV.foreach(errors.attachment.open) do |row|
        next if row.first.start_with?('There were ')
        all_errors << row
      end
    end
    write_all_errors(all_errors)
  end

  def write_all_errors(errors)
    file = temp_error_file_path
    CSV.open(file, "w") do |csv|
      errors.to_a.each do |row|
        csv << row
      end
    end
    self.errors_attachment = SisBatch.create_data_attachment(
      self,
      Rack::Test::UploadedFile.new(file, 'csv', true),
      "sis_errors_attachment_#{id}.csv"
    )
  end

  def cleanup_error_files_when_finished
    return unless self.errors_attachment_id?
    cleanup_error_files
  end

  def cleanup_error_files
    atts = Attachment.where(id: self.sis_batch_error_files.select(:attachment_id)).to_a
    atts.each do |a|
      a.reload
      a.make_childless
      a.destroy_content unless a.root_attachment_id?
    end
    self.sis_batch_error_files.scope.delete_all
    Attachment.where(id: atts).delete_all
  end

  def write_warnings_and_errors_to_file
    error_count = processing_errors&.size || 0
    warning_count = processing_warnings&.size || 0
    return unless error_count > 0 || warning_count > 0
    file = temp_error_file_path
    CSV.open(file, "w") do |csv|
      processing_warnings.each {|row| csv << row}
      processing_errors.each {|row| csv << row}
    end
    self.sis_batch_error_files.create(
      attachment: SisBatch.create_data_attachment(
        self,
        Rack::Test::UploadedFile.new(file, 'csv', true),
        "errors_and_warnings.csv"
      )
    )
  end

  def temp_error_file_path
    temp = Tempfile.open([self.global_id.to_s + '_processing_warnings_and_errors' + Time.zone.now.to_s, '.csv'])
    file = temp.path
    temp.close!
    file
  end

  def limit_size_of_messages
    max_messages = SisBatch.max_messages
    %w[processing_warnings processing_errors].each do |field|
      write_warnings_and_errors_to_file unless messages?
      next unless self.send("#{field}_changed?") && (self.send(field).try(:size) || 0) > max_messages
      limit_message = case field
                      when "processing_warnings"
                        t 'errors.too_many_warnings', "There were %{count} more warnings",
                          count: (processing_warnings.size - max_messages + 1)
                      when "processing_errors"
                        t 'errors.too_many_errors', "There were %{count} more errors",
                          count: (processing_errors.size - max_messages + 1)
                      end
      self.send("#{field}=", self.send(field)[0, max_messages-1] + [['', limit_message]])
    end
    true
  end

end
