module Canvas
  module MigrationWorker
    class QtiWorker < Struct.new(:migration_id)

      def perform
        cm = ContentMigration.find_by_id migration_id
        begin
          plugin = Canvas::Plugin.find(:qti_exporter)
          unless plugin && plugin.settings[:enabled]
            raise "Can't export QTI without the python converter tool installed."
          end
          settings = cm.migration_settings.clone
          settings[:content_migration_id] = migration_id
          settings[:user_id] = cm.user_id
          settings[:attachment_id] = cm.attachment.id rescue nil

          exporter = Qti::QtiExporter.new(settings)
          assessments = exporter.export
          export_folder_path = assessments[:export_folder_path]
          overview_file_path = assessments[:overview_file_path]

          if overview_file_path
            file = File.new(overview_file_path)
            Canvas::MigrationWorker::upload_overview_file(file, cm)
          end
          if export_folder_path
            Canvas::MigrationWorker::upload_exported_data(export_folder_path, cm)
            Canvas::MigrationWorker::clear_exported_data(export_folder_path)
          end

          cm.migration_settings[:migration_ids_to_import] = {:copy=>{:assessment_questions=>true}}.merge(cm.migration_settings[:migration_ids_to_import] || {})
          cm.save
          cm.import_content
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
