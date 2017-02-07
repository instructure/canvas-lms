module CC::Exporter::WebZip
  class ZipPackage < CC::Exporter::Epub::FilesDirectory
    def initialize(exporter)
      @files = exporter.unsupported_files + exporter.cartridge_json[:files]
      @filename_prefix = exporter.filename_prefix
    end
    attr_reader :files

    def empty_zip_file
      zip_file = Zip::File.new(
        File.join(export_directory, filename),
        Zip::File::CREATE
      )
      tempfile = 'empty.txt'
      f = File.new(tempfile, "w+")
      zip_file.add(tempfile, f) { f.close }
      zip_file.close
      zip_file.name
    end

  end
end