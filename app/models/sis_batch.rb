#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  belongs_to :batch_mode_term, :class_name => 'EnrollmentTerm'
  belongs_to :user

  EXPORTABLE_ATTRIBUTES = [
    :id, :account_id, :batch_id, :ended_at, :errored_attempts, :workflow_state, :data, :created_at, :updated_at, :attachment_id, :processing_errors,
    :processing_warnings, :batch_mode, :options, :user_id
  ]

  EXPORTABLE_ASSOCIATIONS = [:account, :attachment, :user]

  before_save :limit_size_of_messages

  validates_presence_of :account_id, :workflow_state

  attr_accessor :zip_path
  attr_accessible :batch_mode, :batch_mode_term

  def self.max_attempts
    5
  end

  def self.valid_import_types
    @valid_import_types ||= {
        "instructure_csv" => {
            :name => lambda { t(:instructure_csv, "Instructure formatted CSV or zipfile of CSVs") },
            :callback => lambda {|batch| batch.process_instructure_csv_zip},
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

    Attachment.skip_3rd_party_submits(true)
    att = Attachment.new
    att.context = batch
    att.uploaded_data = attachment
    att.display_name = t :upload_filename, "sis_upload_%{id}.zip", :id => batch.id
    att.save!
    Attachment.skip_3rd_party_submits(false)
    batch.attachment = att

    yield batch if block_given?
    batch.workflow_state = :created
    batch.save!

    batch
  end

  workflow do
    state :initializing
    state :created
    state :importing
    state :imported
    state :imported_with_messages
    state :failed
    state :failed_with_messages
  end

  def process
    process_delay = Setting.get('sis_batch_process_start_delay', '0').to_f
    job_args = { :singleton => "sis_batch:account:#{Shard.birth.activate { self.account_id }}",
                 :priority => Delayed::LOW_PRIORITY,
                 :max_attempts => 1 }
    if process_delay > 0
      job_args[:run_at] = process_delay.seconds.from_now
    end

    work = SisBatch::Work.new(SisBatch, :process_all_for_account, [self.account])
    Delayed::Job.enqueue(work, job_args)
  end

  class Work < Delayed::PerformableMethod
    def on_permanent_failure(error)
      account = args.first
      account.sis_batches.importing.each do |batch|
        batch.finish(false)
      end
    end
  end

  # this method name is to stay backwards compatible with existing jobs when we deploy
  # once no SisBatch#process_without_send_later jobs are being created anymore, we
  # can rename this to something more sensible.
  def process_without_send_later
    self.options ||= {}
    if self.workflow_state == 'created'
      self.workflow_state = :importing
      self.progress = 0
      self.save

      import_scheme = SisBatch.valid_import_types[self.data[:import_type]]
      if import_scheme.nil?
        self.data[:error_message] = t 'errors.unrecorgnized_type', "Unrecognized import type"
        self.workflow_state = :failed
        self.save
      else
        import_scheme[:callback].call(self)
      end
    end
  rescue => e
    self.data[:error_message] = e.to_s
    self.data[:stack_trace] = "#{e.to_s}\n#{e.backtrace.join("\n")}"
    self.workflow_state = "failed"
    self.save
  end

  scope :needs_processing, -> { where(:workflow_state => 'created').order(:created_at) }
  scope :importing, -> { where(:workflow_state => 'importing') }

  def self.process_all_for_account(account)
    loop do
      batches = account.sis_batches.needs_processing.limit(1000).order(:created_at).all
      break if batches.empty?
      batches.each { |batch| batch.process_without_send_later }
    end
  end

  def fast_update_progress(val)
    self.progress = val
    SisBatch.where(:id => self).update_all(:progress=>val)
  end

  def importing?
    self.workflow_state == 'importing' || self.workflow_state == 'created'
  end

  def process_instructure_csv_zip
    require 'sis'
    download_zip
    importer = SIS::CSV::Import.process(self.account, :files => [ @data_file.path ], :batch => self, :override_sis_stickiness => options[:override_sis_stickiness], :add_sis_stickiness => options[:add_sis_stickiness], :clear_sis_stickiness => options[:clear_sis_stickiness])
    finish importer.finished
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
    @data_file.close if @data_file
    @data_file = nil
    if import_finished
      remove_previous_imports if self.batch_mode?
      self.workflow_state = :imported
      self.progress = 100
      self.workflow_state = :imported_with_messages if messages?
    else
      self.workflow_state = :failed
      self.workflow_state = :failed_with_messages if messages?
    end
    self.ended_at = Time.now
    self.save
  end

  def remove_previous_imports
    # we shouldn't be able to get here without a term, but if we do, skip
    return unless self.batch_mode_term
    return unless data[:supplied_batches]

    if data[:supplied_batches].include?(:course)
      # delete courses that weren't in this batch, in the selected term
      scope = Course.active.for_term(self.batch_mode_term).where(:root_account_id => self.account)
      scope.where("sis_batch_id IS NOT NULL AND sis_batch_id<>?", self).find_each do |course|
        course.clear_sis_stickiness(:workflow_state)
        course.skip_broadcasts = true
        course.destroy
      end
    end

    if data[:supplied_batches].include?(:section)
      # delete sections who weren't in this batch, whose course was in the selected term
      scope = CourseSection.where("course_sections.workflow_state='active' AND course_sections.root_account_id=? AND course_sections.sis_batch_id IS NOT NULL AND course_sections.sis_batch_id<>?", self.account, self)
      scope = scope.joins("INNER JOIN courses ON courses.id=COALESCE(nonxlist_course_id, course_id)").readonly(false)
      scope = scope.where(:courses => { :enrollment_term_id => self.batch_mode_term })
      scope.find_each do |section|
        section.destroy
      end
    end

    if data[:supplied_batches].include?(:enrollment)
      # delete enrollments for courses that weren't in this batch, in the selected term

      scope = Enrollment.active.joins(:course).readonly(false)
      params = {root_account: self.account, batch: self, term: self.batch_mode_term}
      scope = scope.where("courses.root_account_id=:root_account
                           AND enrollments.sis_batch_id IS NOT NULL
                           AND enrollments.sis_batch_id<>:batch
                           AND courses.enrollment_term_id=:term", params)

      scope.find_each do |enrollment|
        enrollment.destroy
      end
    end
  end

  def as_json(options={})
    self.options ||= {} # set this to empty hash if it does not exist so options[:stuff] doesn't blow up
    data = {
      "created_at" => self.created_at,
      "ended_at" => self.ended_at,
      "updated_at" => self.updated_at,
      "progress" => self.progress,
      "id" => self.id,
      "workflow_state" => self.workflow_state,
      "data" => self.data,
      "batch_mode" => self.batch_mode,
      "batch_mode_term_id" => self.batch_mode_term ? self.batch_mode_term.id : nil,
      "override_sis_stickiness" => self.options[:override_sis_stickiness],
      "add_sis_stickiness" => self.options[:add_sis_stickiness],
      "clear_sis_stickiness" => self.options[:clear_sis_stickiness],
    }
    data["processing_errors"] = self.processing_errors if self.processing_errors.present?
    data["processing_warnings"] = self.processing_warnings if self.processing_warnings.present?
    data
  end

  private

  def messages?
    (self.processing_errors && self.processing_errors.length > 0) || (self.processing_warnings && self.processing_warnings.length > 0)
  end

  def self.max_messages
    Setting.get('sis_batch_max_messages', '1000').to_i
  end

  def limit_size_of_messages
    max_messages = SisBatch.max_messages
    %w[processing_warnings processing_errors].each do |field|
      if self.send("#{field}_changed?") && (self.send(field).try(:size) || 0) > max_messages
        limit_message = case field
        when "processing_warnings"
          t 'errors.too_many_warnings', "There were %{count} more warnings", count: (processing_warnings.size - max_messages + 1)
        when "processing_errors"
          t 'errors.too_many_errors', "There were %{count} more errors", count: (processing_errors.size - max_messages + 1)
        end
        self.send("#{field}=", self.send(field)[0, max_messages-1] + [['', limit_message]])
      end
    end
    true
  end
end
