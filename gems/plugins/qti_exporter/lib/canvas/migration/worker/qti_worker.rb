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

module Canvas::Migration
  module Worker
    class QtiWorker < Base

      def perform
        cm = ContentMigration.where(id: migration_id).first
        begin
          cm.reset_job_progress
          cm.job_progress.start
          cm.update_conversion_progress(1)
          plugin = Canvas::Plugin.find(:qti_converter)
          unless plugin && plugin.settings[:enabled]
            raise "Can't export QTI without the python converter tool installed."
          end
          settings = cm.migration_settings.clone
          settings[:content_migration_id] = migration_id
          settings[:user_id] = cm.user_id
          settings[:content_migration] = cm

          if cm.attachment
            settings[:attachment_id] = cm.attachment.id
          elsif settings[:file_url]
            att = Canvas::Migration::Worker.download_attachment(cm, settings[:file_url])
            settings[:attachment_id] = att.id
          elsif !settings[:no_archive_file]
            raise Canvas::Migration::Error, I18n.t(:no_migration_file, "File required for content migration.")
          end

          converter = Qti::Converter.new(settings)
          assessments = converter.export
          export_folder_path = assessments[:export_folder_path]
          overview_file_path = assessments[:overview_file_path]
          cm.update_conversion_progress(50)

          if overview_file_path
            file = File.new(overview_file_path)
            Canvas::Migration::Worker::upload_overview_file(file, cm)
          end
          if export_folder_path
            Canvas::Migration::Worker::upload_exported_data(export_folder_path, cm)
            Canvas::Migration::Worker::clear_exported_data(export_folder_path)
          end
          cm.update_conversion_progress(100)

          cm.migration_settings[:migration_ids_to_import] = {:copy=>{:everything=>true}}.merge(cm.migration_settings[:migration_ids_to_import] || {})
          if path = converter.course[:files_import_root_path]
            cm.migration_settings[:files_import_root_path] = path
          end
          cm.save
          cm.import_content_without_send_later
          cm.workflow_state = :imported
          cm.save
          cm.update_import_progress(100)
        rescue => e
          cm.fail_with_error!(e) if cm
        end
      end

      def self.enqueue(content_migration)
        Delayed::Job.enqueue(new(content_migration.id),
                             :priority => Delayed::LOW_PRIORITY,
                             :max_attempts => 1)
      end
    end
  end
end
