module CC::Exporter::Epub
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_epub(opts={})
      exporter = CC::Exporter::Epub::Exporter.new(content_cartridge.open, opts[:sort_by_content])
      epub = CC::Exporter::Epub::Book.new(exporter.templates)
      epub.create
    end
  end
end
