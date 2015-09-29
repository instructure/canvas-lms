module CC::Exporter::Epub
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_epub
      exporter = CC::Exporter::Epub::Exporter.new(content_cartridge.open)
      epub = CC::Exporter::Epub::Book.new(exporter.templates)
      epub.create
    end
  end
end
