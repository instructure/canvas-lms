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

class SisBatch < ActiveRecord::Base
  include Workflow
  belongs_to :account
  has_many :sis_batch_log_entries, :order => :created_at
  serialize :data
  serialize :processing_errors, Array
  serialize :processing_warnings, Array
  belongs_to :attachment

  attr_accessor :zip_path
  
  def self.max_attempts
    5
  end
  
  def self.valid_import_types
    @valid_import_types ||= {
        "instructure_csv" => {
            :name => "Instructure formatted CSV or zipfile of CSVs",
            :callback => lambda {|batch| batch.process_instructure_csv_zip},
            :default => true
          }
      }
  end

  def self.create_with_attachment(account, import_type, attachment)
    batch = SisBatch.new
    batch.account = account
    batch.progress = 0
    batch.workflow_state = :created
    batch.data = {:import_type => import_type}
    batch.save

    att = Attachment.new
    att.context = batch
    att.uploaded_data = attachment
    att.display_name = "sis_upload_#{batch.id}.zip"
    att.save
    batch.attachment = att
    batch.save

    batch
  end

  workflow do
    state :created
    state :importing
    state :imported
    state :imported_with_messages
    state :failed
    state :failed_with_messages
  end

  def process
    if self.workflow_state == 'created'
      self.workflow_state = :importing
      self.progress = 0
      self.save

      import_scheme = SisBatch.valid_import_types[self.data[:import_type]]
      if import_scheme.nil?
        self.data[:error_message] = "Unrecognized import type"
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
  handle_asynchronously_with_queue :process, 'sis_imports'

  named_scope :needs_processing, lambda{
    {:conditions => ["sis_batches.workflow_state = 'needs_processing'"], :order => :created_at}
  }

  def fast_update_progress(val)
    self.progress = val
    SisBatch.update_all({:progress=>val}, "id=#{self.id}")
  end
  
  def importing?
    self.workflow_state == 'importing' || self.workflow_state == 'created'
  end

  def process_instructure_csv_zip
    require 'sis'
    download_zip
    importer = SIS::SisCsv.process(self.account, :files => [ @data_file.path ], :batch => self)
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
    @data_file.close
    if import_finished
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
  private
  
  def messages?
    (self.processing_errors && self.processing_errors.length > 0) || (self.processing_warnings && self.processing_warnings.length > 0)
  end
end
