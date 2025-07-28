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

module Accessibility
  class Issue
    module AttachmentIssues
      def generate_attachment_resources(skip_scan: false)
        attachments = context
                      .attachments
                      .not_deleted
                      .where(content_type: "application/pdf")
                      .order(updated_at: :desc)
        return attachments.map { |attachment| attachment_attributes(attachment) } if skip_scan

        attachments.each_with_object({}) do |attachment, issues|
          result = check_pdf_accessibility(attachment)
          issues[attachment.id] = result.merge(attachment_attributes(attachment))
        end
      end

      private

      def attachment_attributes(attachment)
        {
          title: attachment.title,
          content_type: attachment.content_type,
          published: attachment.published?,
          updated_at: attachment.updated_at&.iso8601 || "",
          url: course_files_url(context, preview: attachment.id)
        }
      end
    end
  end
end
