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
class Canvas::Migration::Worker::CCWorker < Struct.new(:migration_id)
  def perform(cm=nil)
    cm ||= ContentMigration.where(id: migration_id).first
    cm.job_progress.start unless cm.skip_job_progress
    begin
      cm.update_conversion_progress(1)
      settings = cm.migration_settings.clone
      settings[:content_migration_id] = migration_id
      settings[:user_id] = cm.user_id
      settings[:content_migration] = cm

      if cm.attachment
        settings[:attachment_id] = cm.attachment.id
      elsif settings[:file_url]
        # create attachment and download file
        att = Canvas::Migration::Worker.download_attachment(cm, settings[:file_url])
        settings[:attachment_id] = att.id
      elsif !settings[:no_archive_file]
        raise Canvas::Migration::Error, I18n.t(:no_migration_file, "File required for content migration.")
      end

      converter_class = settings[:converter_class]
      unless converter_class
        if settings[:no_archive_file]
          raise ArgumentError, "converter_class required for content migration with no file"
        end
        settings[:archive] = Canvas::Migration::Archive.new(settings)
        converter_class = settings[:archive].get_converter
      end
      converter = converter_class.new(settings)

      course = converter.export
      export_folder_path = course[:export_folder_path]
      overview_file_path = course[:overview_file_path]

      if overview_file_path
        file = File.new(overview_file_path)
        Canvas::Migration::Worker::upload_overview_file(file, cm)
        cm.update_conversion_progress(95)
      end
      if export_folder_path
        Canvas::Migration::Worker::upload_exported_data(export_folder_path, cm)
        Canvas::Migration::Worker::clear_exported_data(export_folder_path)
      end

      cm.migration_settings[:worker_class] = converter_class.name
      if !cm.migration_settings[:migration_ids_to_import] || !cm.migration_settings[:migration_ids_to_import][:copy]
        cm.migration_settings[:migration_ids_to_import] = {:copy=>{:everything => true}}
      end
      cm.workflow_state = :exported
      saved = cm.save
      cm.update_conversion_progress(100)

      if cm.import_immediately? && !cm.for_course_copy?
         cm.import_content
         cm.update_import_progress(100)
         saved = cm.save
         if converter.respond_to?(:post_process)
           converter.post_process
         end
       end
      saved
    rescue Canvas::Migration::Error
      cm.add_error($!.message, :exception => $!)
      cm.workflow_state = :failed
      cm.job_progress.fail unless cm.skip_job_progress
      cm.save
    rescue => e
      cm.fail_with_error!(e) if cm
    end
  end

  def self.enqueue(content_migration)
    Delayed::Job.enqueue(new(content_migration.id),
                         :priority => Delayed::LOW_PRIORITY,
                         :max_attempts => 1,
                         :strand => content_migration.strand)
  end

end
