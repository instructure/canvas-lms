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
      def generate_attachment_issues
        context.attachments.not_deleted.order(updated_at: :desc).each_with_object({}) do |attachment, issues|
          result = if attachment.content_type == "application/pdf"
                     check_pdf_accessibility(attachment)
                   else
                     {}
                   end

          issues[attachment.id] = result.merge(
            title: attachment.title,
            content_type: attachment.content_type,
            published: attachment.published?,
            updated_at: attachment.updated_at&.iso8601 || "",
            url: course_files_url(context, preview: attachment.id)
          )
        end
      end
    end
  end
end
