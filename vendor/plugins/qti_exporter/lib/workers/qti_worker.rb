module Canvas
  module MigrationWorker
    class QtiWorker < Struct.new(:migration_id)

      def perform
        plugin = Canvas::Plugin.find(:qti_exporter)
        unless plugin && plugin.settings[:enabled]
          raise "Can't export QTI without the python converter tool installed."
        end
        cm = ContentMigration.find migration_id
        settings = cm.migration_settings
        settings[:content_migration_id] = migration_id
        settings[:user_id] = cm.user_id
        settings[:attachment_id] = cm.attachment.id rescue nil
        settings[:id_prepender] = cm.id 
        
        exporter = Qti::QtiExporter.new(settings)
        assessments = exporter.export
        export_folder_path = assessments[:export_folder_path]
        overview_file_path = assessments[:overview_file_path]

        if overview_file_path
          file = File.new(overview_file_path)
          Canvas::MigrationWorker::upload_overview_file(file, cm)
        end

        cm.migration_settings[:export_folder_path] = export_folder_path
        cm.migration_settings[:migration_ids_to_import] = {:copy=>{:assessment_questions=>true}}
        cm.save
        cm.import_content
      end

      def self.enqueue(content_migration)
        Delayed::Job.enqueue(new(content_migration.id), :priority => Delayed::LOW_PRIORITY)
      end
    end
  end
end
