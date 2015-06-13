module Exporters
  module ExporterHelper
    def self.add_attachment_to_zip(attachment, zipfile, filename = nil, files_in_zip=[])
      filename ||= attachment.filename

      # we allow duplicate filenames in the same folder. it's a bit silly, but we
      # have to handle it here or people might not get all their files zipped up.
      filename = Attachment.make_unique_filename(filename, files_in_zip)
      files_in_zip << filename

      handle = nil
      begin
        handle = attachment.open(:need_local_file => true)
        zipfile.get_output_stream(filename){|zos| Zip::IOExtras.copy_stream(zos, handle)}
      rescue => e
        return false
      ensure
        handle.close if handle
      end

      true
    end
  end
end