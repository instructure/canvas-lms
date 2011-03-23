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
        "instructure_csv_zip" => {
            :name => "Instructure formatted CSV zip",
            :callback => lambda {|batch| batch.process_instructure_csv_zip},
            :default => true
          }
      }
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
  handle_asynchronously :process

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
    importer = SIS::SisCsv.process(self.account, :files => [ @temp_file.path ], :batch => self)
    finish importer.finished
  end

  def download_zip
    @temp_file = Tempfile.new("sis_data")
    if self.data[:file_path]
      @temp_file.write File.read(self.data[:file_path])
      if self.data[:file_path] =~ /(\.[^\.]*)\z/
        add_extension($1)
      end
    elsif Attachment.local_storage?
      @temp_file.write File.read(self.attachment.full_filename)
      add_extension(self.attachment.extension)
    else
      require 'aws/s3'
      AWS::S3::S3Object.stream(self.attachment.full_filename, self.attachment.bucket_name) do |chunk|
        @temp_file.write chunk
      end
      add_extension(self.attachment.extension)
    end
    @temp_file
  end

  def finish(import_finished)
    @temp_file.close
    File.delete(@temp_file.path) rescue nil
    if import_finished
      self.workflow_state = :imported
      self.progress = 100
      self.workflow_state = :imported_with_messages if messages?
    else
      self.workflow_state = :failed
      self.workflow_state = :failed_with_messages if messages?
    end
    self.save
  end
  private
  
  def messages?
    (self.processing_errors && self.processing_errors.length > 0) || (self.processing_warnings && self.processing_warnings.length > 0)
  end

  def add_extension(ext)
    @temp_file.close
    new_path = @temp_file.path + ext
      File.rename(@temp_file.path, new_path)
      @temp_file = File.new(new_path)
  end
  
end
