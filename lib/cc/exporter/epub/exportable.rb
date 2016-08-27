module CC::Exporter::Epub
  module Exportable
    def content_cartridge
      self.attachment
    end

    def convert_to_epub
      exporter = CC::Exporter::Epub::Exporter.new(content_cartridge.open, sort_by_content_type?)
      epub = CC::Exporter::Epub::Book.new(exporter)
      files_directory = CC::Exporter::Epub::FilesDirectory.new(exporter)
      result = [ epub.create, files_directory.create ].compact
      exporter.cleanup_files
      result
    end

    def sort_by_content_type?
      false
    end
  end
end
