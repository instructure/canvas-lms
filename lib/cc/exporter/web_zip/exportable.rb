module CC::Exporter::WebZip
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_offline_web_zip
      exporter = CC::Exporter::WebZip::Exporter.new(content_cartridge.open, false)
      zip = CC::Exporter::WebZip::ZipPackage.new(exporter)
      result = zip.create
      exporter.cleanup_files
      result
    end
  end
end