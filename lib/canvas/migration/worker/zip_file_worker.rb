# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
class Canvas::Migration::Worker::ZipFileWorker < Canvas::Migration::Worker::Base
  def perform(cm = nil)
    cm ||= ContentMigration.find migration_id
    cm.save if cm.capture_job_id

    cm.workflow_state = :importing
    cm.migration_settings[:skip_import_notification] = true
    cm.job_progress.start
    cm.save

    begin
      if cm.attachment
        zipfile = cm.attachment.open
      elsif cm.migration_settings[:file_url]
        att = Canvas::Migration::Worker.download_attachment(cm, cm.migration_settings[:file_url])
        zipfile = att.open
      elsif !settings[:no_archive_file]
        raise Canvas::Migration::Error, I18n.t(:no_migration_file, "File required for content migration.")
      end

      folder = cm.context.folders.find(cm.migration_settings[:folder_id])

      update_callback = lambda do |pct|
        percent_complete = pct * 100

        scaled = percent_complete

        if cm.import_immediately?
          scaled = (scaled / 2) + 50
        end

        # Only update if progress has incremented 1 percent
        if scaled - cm.progress >= 1
          cm.update_import_progress(percent_complete)
        end
      end

      UnzipAttachment.process(
        context: cm.context,
        root_directory: folder,
        filename: zipfile.path,
        callback: update_callback
      )

      zipfile.close

      cm.workflow_state = :imported
      cm.save
      cm.update_import_progress(100)
    rescue => e
      cm.fail_with_error!(e)
      raise e
    end
  end

  def self.enqueue(content_migration)
    Delayed::Job.enqueue(new(content_migration.id),
                         priority: Delayed::LOW_PRIORITY,
                         max_attempts: 1,
                         strand: content_migration.strand)
  end
end
