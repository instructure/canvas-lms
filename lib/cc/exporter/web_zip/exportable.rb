module CC::Exporter::WebZip
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_offline_web_zip
      exporter = CC::Exporter::WebZip::Exporter.new(content_cartridge.open, false)
      zip = CC::Exporter::WebZip::ZipPackage.new(exporter)
      file_path = zip.create || zip.empty_zip_file
      exporter.cleanup_files
      file_path
    end
  end
end