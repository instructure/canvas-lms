module Canvas::Migration
  module Worker
    class QtiWorker < Struct.new(:migration_id)

      def perform
        cm = ContentMigration.find_by_id migration_id
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
          settings[:attachment_id] = cm.attachment.id rescue nil
          settings[:content_migration] = cm

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
                             :max_attempts => 1)
      end
    end
  end
end
