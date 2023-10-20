# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

module DataFixup
  class FixMaybeAttachments
    def self.run
      tag = "data_fixup_fix_maybe_attachments"
      attachments.find_each do |attachment|
        # This logic was taken almost verbatim from Attachment#build_media_object. The important distinction
        # is the added strand and max_concurrent variables to not overload Notorious or the jobs servers.
        progress = Progress.where(context_type: "Attachment", context_id: attachment, tag:).last
        progress ||= Progress.new(context: attachment, tag:)
        next unless progress.new_record? || !progress.pending?

        progress.reset!
        progress.process_job(
          MediaObject,
          :add_media_files,
          {
            priority: Delayed::LOWER_PRIORITY,
            preserve_method_args: true,
            max_attempts: 5,
            strand: "data_fixup_fix_maybe_attachments",
            max_concurrent: 5
          },
          attachment,
          false
        )
      end
    end

    def self.attachments
      Attachment.where(media_entry_id: "maybe", file_state: ["available", "hidden"])
                .where("content_type ILIKE ? OR content_type ILIKE ?", "%video%", "%audio%")
                .where.not(workflow_state: [:unattached, :unattached_temporary])
    end
  end
end
