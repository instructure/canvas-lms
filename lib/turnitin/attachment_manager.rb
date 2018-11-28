#
# Copyright (C) 2016 - present Instructure, Inc.
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

module Turnitin
  class AttachmentManager

    def self.update_attachment(submission, attachment)
      assignment = submission.assignment
      user = submission.user
      tool = assignment.external_tool_tag.content
      tool ||= ContextExternalTool.find_external_tool(assignment.external_tool_tag.url, assignment.context)
        tii_client = TiiClient.new(
        user,
        assignment,
        tool,
        submission.turnitin_data[attachment.asset_string][:outcome_response]
      )
      save_attachment( tii_client, user, attachment)
    end

    def self.create_attachment(user, assignment, tool, outcomes_response_json)
      attachment = assignment.attachments.new
      tii_client = TiiClient.new(user, assignment, tool, outcomes_response_json)
      save_attachment(tii_client, user, attachment)
    end

    def self.save_attachment(turnitin_client, user, attachment)
      Dir.mktmpdir do |dirname|
        turnitin_client.original_submission do |response|
          content_disposition = response.headers['content-disposition']
          fail Errors::ScoreStillPendingError if content_disposition.nil?

          filename = content_disposition.match(/filename=(\"?)(.+)\1/)[2]
          filename.tr!('/','-')
          path = File.join(dirname, filename)
          File.open(path, 'wb') do |f|
            f.write(response.body)
          end
          attachment.uploaded_data = Rack::Test::UploadedFile.new(path, response.headers['content-type'], true)
          attachment.display_name = filename
          attachment.user ||= user
          attachment.save!
        end
        attachment
      end
    end
    private_class_method :save_attachment

  end
end
