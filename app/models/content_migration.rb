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
  require 'aws/s3'
  include AWS::S3
  include Workflow
  belongs_to :context, :polymorphic => true
  belongs_to :user
  belongs_to :attachment
  belongs_to :overview_attachment, :class_name => 'Attachment'
  belongs_to :exported_attachment, :class_name => 'Attachment'
  has_a_broadcast_policy
  serialize :migration_settings
  before_save :infer_defaults
  cattr_accessor :export_file_path
  DATE_FORMAT = "%m/%d/%Y"
  DEFAULT_TO_EXPORT = {
          'all_files' => false,
          'announcements' => false,
          'assessments' => false,
          'assignment_groups' => true,
          'assignments' => false,
          'calendar_events' => false,
          'calendar_start' => 1.year.ago.strftime(DATE_FORMAT),
          'calendar_end' => 1.year.from_now.strftime(DATE_FORMAT),
          'course_outline' => true,
          'discussions' => false,
          'discussion_responses' => false,
          'goals' => false,
          'groups' => false,
          'learning_modules' => false,
          'question_bank' => false,
          'rubrics' => false,
          'tasks' => false,
          'web_links' => false,
          'wikis' => false
  }

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

  set_broadcast_policy do |p|
    p.dispatch :migration_export_ready
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:exported)
    }
    
    p.dispatch :migration_import_finished
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:imported)
    }
    
    p.dispatch :migration_import_failed
    p.to { [user] }
    p.whenever {|record|
      record.changed_state(:failed)
    }
  end

  def migration_settings
    read_attribute(:migration_settings) || write_attribute(:migration_settings,{}.with_indifferent_access)
  end

  def update_migration_settings(new_settings)
    new_settings.each do |key, val|
      if key == 'only'
        process_to_scrape val
      else
        migration_settings[key] = val
      end
    end
  end
  
  def migration_ids_to_import=(val)
    migration_settings[:migration_ids_to_import] = val
  end
  
  def infer_defaults
    migration_settings[:to_scrape] ||= DEFAULT_TO_EXPORT
  end
  
  def process_to_scrape(hash)
    migrate_only = migration_settings[:to_scrape] || DEFAULT_TO_EXPORT
    hash.each do |key, arg|
      migrate_only[key] = arg == '1' ? true : false if arg 
      if key == 'calendar_events' && migrate_only[key]
        migrate_only['calendar_start'] = 1.year.ago.strftime(DATE_FORMAT)
        migrate_only['calendar_end'] = 1.year.from_now.strftime(DATE_FORMAT)
      end
    end
    migration_settings[:to_scrape] = migrate_only
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

  def course_archive_download_url=(url)
    migration_settings[:course_archive_download_url] = url
  end
  
  def root_account
    self.context.root_account rescue nil
  end
  
  def plugin_type
    if plugin = Canvas::Plugin.find(migration_settings['migration_type'])
      plugin.settings['select_text'] || plugin.name
    else
      migration_settings['migration_type'].titleize
    end
  end
  
  def export_content
    plugin = Canvas::Plugin.find(migration_settings['migration_type'])
    if plugin
      begin
        if Canvas::MigrationWorker.const_defined?(plugin.settings['worker'])
          self.workflow_state = :exporting
          Canvas::MigrationWorker.const_get(plugin.settings['worker']).enqueue(self)
          self.save
        else
          raise NameError
        end
      rescue NameError
        self.workflow_state = 'failed'
        message = "The migration plugin #{migration_settings['migration_type']} doesn't have a worker."
        migration_settings[:last_error] = message
        logger.error message
        self.save
      end
    else
      self.workflow_state = 'failed'
      message = "No migration plugin of type #{migration_settings['migration_type']} found."
      migration_settings[:last_error] = message
      logger.error message
      self.save
    end
  end

  def to_import(val)
    migration_settings[:migration_ids_to_import][:copy][val] rescue nil
  end
  
  def import_content
    self.workflow_state = :importing
    self.save
    
    begin
      @exported_data_zip = download_exported_data
      @zip_file = Zip::ZipFile.open(@exported_data_zip.path)
      data = JSON.parse(@zip_file.read('course_export.json'))
      data = data.with_indifferent_access if data.is_a? Hash
      data['all_files_export'] ||= {}
      
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
      self.context.import_from_migration(data, migration_settings[:migration_ids_to_import], self)
    rescue => e
      self.workflow_state = :failed
      message = "#{e.to_s}: #{e.backtrace.join("\n")}"
      migration_settings[:last_error] = message
      logger.error message
      self.save
      raise e
    ensure
      clear_migration_data
    end
  end
  handle_asynchronously :import_content, :priority => Delayed::LOW_PRIORITY
  
  named_scope :for_context, lambda{|context|
    {:conditions => {:context_id => context.id, :context_type => context.class.to_s} }
  }
  
  named_scope :successful, :conditions=>"workflow_state = 'imported'"
  named_scope :running, :conditions=>"workflow_state IN ('exporting', 'importing')"
  named_scope :waiting, :conditions=>"workflow_state IN ('exported')"
  named_scope :failed, :conditions=>"workflow_state IN ('failed', 'pre_process_error')"
  
  def download_exported_data
    raise "No exported data to import" unless self.exported_attachment
    config = Setting.from_config('external_migration')
    if config && config[:data_folder]
      @exported_data_zip = Tempfile.new("migration_#{self.id}_", config[:data_folder])
    else
      @exported_data_zip = Tempfile.new("migration_#{self.id}_")
    end
    
    if Attachment.local_storage?
      @exported_data_zip.write File.read(self.exported_attachment.full_filename)
    elsif Attachment.s3_storage?
      att = self.exported_attachment
      require 'aws/s3'
      AWS::S3::S3Object.stream(att.full_filename, att.bucket_name) do |chunk|
        @exported_data_zip.write chunk
      end
    end
    
    @exported_data_zip.close
    @exported_data_zip
  end
  
  def create_all_files_path(temp_path)
    "#{temp_path}_all_files.zip"
  end
  
  def clear_migration_data
    begin
      @zip_file.close if @zip_file
      @zip_file = nil
      if @exported_data_zip
        all_files_path = create_all_files_path(@exported_data_zip.path)
        FileUtils::rm_rf(all_files_path) if File.exists?(all_files_path)
        @exported_data_zip.unlink
      end
    rescue
      Rails.logger.warn "Couldn't delete files for content_migration #{self.id}"
    end
  end

  def fast_update_progress(val)
    self.progress = val
    ContentMigration.update_all({:progress=>val}, "id=#{self.id}")
  end
end
