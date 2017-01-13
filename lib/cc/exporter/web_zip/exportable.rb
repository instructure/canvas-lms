module CC::Exporter::WebZip
  module Exportable
    def content_cartridge
      self.attachment
    end

    def create_zip(exporter)
      CC::Exporter::WebZip::ZipPackage.new(exporter)
    end

    def convert_to_offline_web_zip
      exporter = CC::Exporter::WebZip::Exporter.new(content_cartridge.open, false)
      zip = create_zip(exporter)
      file_path = zip.create || zip.empty_zip_file

      exporter.cleanup_files
      zip.cleanup_files

      file_path
    end
  end
end