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
class Canvas::Migration::Worker::CourseCopyWorker < Struct.new(:migration_id)
  def perform(cm=nil)
    cm ||= ContentMigration.find migration_id
    
    cm.workflow_state = :pre_processing
    cm.reset_job_progress
    cm.migration_settings[:skip_import_notification] = true
    cm.migration_settings[:import_immediately] = true
    cm.save
    cm.job_progress.start

    begin
      source = cm.source_course || Course.find(cm.migration_settings[:source_course_id])
      ce = ContentExport.new
      ce.context = source
      ce.content_migration = cm
      ce.selected_content = cm.copy_options
      ce.export_type = ContentExport::COURSE_COPY
      ce.user = cm.user
      ce.save!
      cm.content_export = ce

      ce.export_without_send_later

      if ce.workflow_state == 'exported_for_course_copy'
        # use the exported attachment as the import archive
        cm.attachment = ce.attachment
        cm.migration_settings[:migration_ids_to_import] ||= {:copy=>{}}
        cm.migration_settings[:migration_ids_to_import][:copy][:everything] = true
        # set any attachments referenced in html to be copied
        ce.selected_content['attachments'] ||= {}
        ce.referenced_files.values.each do |att_mig_id|
          ce.selected_content['attachments'][att_mig_id] = true
        end
        ce.save

        cm.save
        worker = Canvas::Migration::Worker::CCWorker.new
        worker.migration_id = cm.id
        worker.perform
        cm.reload
        if cm.workflow_state == 'exported'
          cm.workflow_state = :pre_processed
          cm.update_import_progress(10)

          cm.context.copy_attachments_from_course(source, :content_export => ce, :content_migration => cm)
          cm.update_import_progress(20)

          cm.import_content
          cm.workflow_state = :imported
          cm.save
          cm.update_import_progress(100)
        end
      else
        cm.workflow_state = :failed
        cm.migration_settings[:last_error] = "ContentExport failed to export course."
        cm.save
      end
    rescue => e
      cm.fail_with_error!(e)
      raise e
    end
  end

  def self.enqueue(content_migration)
    Delayed::Job.enqueue(new(content_migration.id),
                         :priority => Delayed::LOW_PRIORITY,
                         :max_attempts => 1,
                         :strand => content_migration.strand)
  end
end
