module CC::Exporter::WebZip
  module Exportable
    def content_cartridge
      self.attachment
    end

    def create_zip(exporter, progress_key)
      CC::Exporter::WebZip::ZipPackage.new(exporter, course, user, progress_key)
    end

    def convert_to_offline_web_zip(progress_key)
      exporter = CC::Exporter::WebZip::Exporter.new(content_cartridge.open, false, :web_zip)
      zip = create_zip(exporter, progress_key)
      file_path = zip.create

      exporter.cleanup_files
      zip.cleanup_files

      file_path
    end
  end
end