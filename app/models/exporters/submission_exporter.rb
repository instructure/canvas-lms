# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Exporters
  class SubmissionExporter

    def self.export_user_submissions(user, base_folder, zipfile, files_in_zip)
      user.submissions.shard(user).each do |main_sub|
        base_path = File.join(*[base_folder, main_sub.context.name.presence, main_sub.assignment.name.presence].compact)

        main_sub.versions.each do |version|
          submission = version.model
          if submission.submission_type == "online_upload"
            # NOTE: not using #versioned_attachments or #attachments because
            # they do not include submissions for group assignments for anyone
            # but the original submitter of the group submission
            attachment_ids = submission.attachment_ids.try(:split, ",")
            attachments = attachment_ids.present? ? main_sub.shard.activate { Attachment.where(id: attachment_ids) } : []
            attachments.each do |attachment|
              # TODO handle missing attachments
              path = File.join(base_path, attachment.display_name)
              ExporterHelper.add_attachment_to_zip(attachment, zipfile, path, files_in_zip)
            end
          elsif submission.submission_type == "online_url" && submission.url
            path = File.join(base_path, "submission_link_#{version.number}.html")
            content = "<a href=\"#{submission.url}\">#{submission.url}</a>"
            zipfile.get_output_stream(path) {|f| f.puts content }
          elsif submission.submission_type == "online_text_entry" && submission.body
            path = File.join(base_path, "submission_text_#{version.number}.html")
            zipfile.get_output_stream(path) {|f| f.puts submission.body }
          end
        end
      end
    end
  end
end
