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
        attachment.uploaded_data = uploaded_data
        attachment.workflow_state = 'zipped'
        attachment.file_state = 'available'
        attachment.save!
      end

      attachment
    end
  end
end