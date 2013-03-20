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
  def perform
    cm = ContentMigration.find_by_id migration_id
    begin
      cm.fast_update_progress(1)
      settings = cm.migration_settings.clone
      settings[:content_migration_id] = migration_id
      settings[:user_id] = cm.user_id
      settings[:attachment_id] = cm.attachment.id rescue nil
      settings[:content_migration] = cm

      converter_class = settings[:converter_class] || Canvas::Migration::Worker::get_converter(settings)
      converter = converter_class.new(settings)

      course = converter.export
      export_folder_path = course[:export_folder_path]
      overview_file_path = course[:overview_file_path]

      if overview_file_path
        file = File.new(overview_file_path)
        Canvas::Migration::Worker::upload_overview_file(file, cm)
        cm.fast_update_progress(95)
      end
      if export_folder_path
        Canvas::Migration::Worker::upload_exported_data(export_folder_path, cm)
        Canvas::Migration::Worker::clear_exported_data(export_folder_path)
        cm.fast_update_progress(100)
      end

      cm.migration_settings[:worker_class] = converter_class.name
      if !cm.migration_settings[:migration_ids_to_import] || !cm.migration_settings[:migration_ids_to_import][:copy]
        cm.migration_settings[:migration_ids_to_import] = {:copy=>{:everything => true}}
      end
      cm.workflow_state = :exported
      cm.progress = 0
      saved = cm.save

      if cm.import_immediately?
        cm.import_content_without_send_later
        cm.progress = 100
        saved = cm.save
        if converter.respond_to?(:post_process)
          converter.post_process
        end
      end

      saved
    rescue => e
      report = ErrorReport.log_exception(:content_migration, e)
      if cm
        cm.workflow_state = :failed
        cm.migration_settings[:last_error] = "ErrorReport:#{report.id}"
        cm.save
      end
    end
  end

  def self.enqueue(content_migration)
    Delayed::Job.enqueue(new(content_migration.id),
                         :priority => Delayed::LOW_PRIORITY,
                         :max_attempts => 1,
                         :strand => content_migration.strand)
  end
end
