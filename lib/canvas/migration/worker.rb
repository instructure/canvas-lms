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

require 'action_controller_test_process'

module Canvas::Migration::Worker

  def self.get_converter(settings)
    Canvas::Migration::Archive.new(settings).get_converter
  end

  def self.upload_overview_file(file, content_migration)
    uploaded_data = Rack::Test::UploadedFile.new(file.path, Attachment.mimetype(file.path))
    
    att = Attachment.new
    att.context = content_migration
    att.uploaded_data = uploaded_data
    att.save
    begin
      uploaded_data.unlink
    rescue
      Rails.logger.warn "Couldn't unlink overview for content_migration #{content_migration.id}"
    end
    content_migration.overview_attachment = att
    content_migration.save
    att
  end

  def self.upload_exported_data(folder, content_migration)
    file_name = "exported_data_cm_#{content_migration.id}.zip"
    zip_file = File.join(folder, file_name)
    att = nil
    
    begin
      Zip::File.open(zip_file, 'w') do |zipfile|
        Dir["#{folder}/**/**"].each do |file|
          next if File.basename(file) == file_name
          file_path = file.sub(folder+'/', '')
          zipfile.add(file_path, file)
        end
      end

      upload_file = Rack::Test::UploadedFile.new(zip_file, "application/zip")
      att = Attachment.new
      att.context = content_migration
      att.uploaded_data = upload_file
      att.save
      upload_file.unlink
      content_migration.exported_attachment = att
      content_migration.save
    rescue => e
      Rails.logger.warn "Error while uploading exported data for content_migration #{content_migration.id} - #{e}"
      raise e
    end

    att
  end
  
  def self.clear_exported_data(folder)
    begin
      config = ConfigFile.load('external_migration')
      if !config || !config[:keep_after_complete]
        FileUtils::rm_rf(folder) if File.exist?(folder)
      end
    rescue
      Rails.logger.warn "Couldn't clear export data for content_migration #{content_migration.id}"
    end
  end

  def self.download_attachment(cm, url)
    att = Attachment.new
    att.context = cm
    att.file_state = 'deleted'
    att.workflow_state = 'unattached'
    att.clone_url(url, false, true, :quota_context => cm.context)

    if att.file_state == 'errored'
      raise Canvas::Migration::Error, att.upload_error_message
    end

    cm.attachment = att
    cm.save!
    att
  rescue Attachment::OverQuotaError
    raise Canvas::Migration::Error, $!.message
  end
end
