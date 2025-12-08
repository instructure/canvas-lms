# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DataFixup
  class SetAttachmentIdOnMediaRecordingSubmissions < CanvasOperations::DataFixup
    self.mode = :individual_record
    self.progress_tracking = false

    scope do
      Submission
        .where(submission_type: "media_recording")
        .where(attachment_id: nil)
        .where.not(media_object_id: nil)
        .order(submitted_at: :desc)
        .preload(:media_object)
        .preload(:versions)
    end

    def process_record(submission)
      return unless submission.media_object&.attachment_id

      submission.update(attachment_id: submission.media_object.attachment_id)

      submission.versions.find_each do |version|
        model = version.model
        next if model.attempt == submission.attempt

        next if model.media_object&.attachment_id.nil?

        model.attachment_id = model.media_object.attachment_id
        version.model = model
        version.update_column(:yaml, version.yaml)
      end
    rescue => e
      log_message("Error processing submission #{submission.id}: #{e.message}", level: :error)
      log_message(e.backtrace.join("\n"), level: :error)
    end
  end
end
