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
  class UserDataExporter
    def self.create_user_data_export(user)
      root_folder = Folder.root_folders(user).first

      sub_folder ||= root_folder.sub_folders.active.where(name: I18n.t(:data_exports, 'data exports')).first_or_initialize
      if sub_folder.new_record?
        sub_folder.context = user
        sub_folder.save!
      end

      time_zone = user.time_zone.presence || user.account.default_time_zone

      folder_name = "#{time_zone.today} data export"
      filename = "#{folder_name}.zip"
      attachment = sub_folder.file_attachments.build(:display_name => filename)
      attachment.user_id = user.id
      attachment.context = user
      attachment.folder_id = sub_folder.id

      Dir.mktmpdir do |dirname|
        zip_name = File.join(dirname, filename)
        files_in_zip = Set.new
        Zip::File.open(zip_name, Zip::File::CREATE) do |zipfile|
          # other user data will (hopefully) be included here in the future
          Exporters::SubmissionExporter.export_user_submissions(user, folder_name, zipfile, files_in_zip)
        end

        uploaded_data = Rack::Test::UploadedFile.new(zip_name, 'application/zip')
        Attachments::Storage.store_for_attachment(attachment, uploaded_data)
        attachment.workflow_state = 'zipped'
        attachment.file_state = 'available'
        attachment.save!
      end

      attachment
    end
  end
end