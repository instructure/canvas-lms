module CC::Exporter::Epub::Converters
  module FilesConverter
    include CC::CCHelper
    include CC::Exporter

    def convert_files
      files = []
      @manifest.css("resource[type=#{WEBCONTENT}][href^=#{WEB_RESOURCES_FOLDER}]").each do |res|
        full_path = File.expand_path(get_full_path(res['href']))
        local_path = res['href'].sub(WEB_RESOURCES_FOLDER, CC::Exporter::Epub::FILE_PATH)
        files << {
          migration_id: res['identifier'],
          local_path: local_path,
          file_name: File.basename(local_path),
          full_path: full_path
        }
      end
      files
    end
  end
end
