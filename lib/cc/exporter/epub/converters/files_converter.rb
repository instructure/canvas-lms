module CC::Exporter::Epub::Converters
  module FilesConverter
    include CC::CCHelper
    include CC::Exporter

    def convert_files
      files = []
      @manifest.css("resource[type=#{WEBCONTENT}][href^=#{WEB_RESOURCES_FOLDER}]").each do |res|
        full_path = File.expand_path(get_full_path(res['href']))
        local_path = File.join(
          File.dirname(res['href'].sub(WEB_RESOURCES_FOLDER, CC::Exporter::Epub::FILE_PATH)),
          CGI.escape(File.basename(res['href']))
        )
        files << {
          migration_id: res['identifier'],
          local_path: local_path,
          file_name: File.basename(local_path),
          full_path: full_path,
          media_type: media_type_for(File.basename(local_path))
        }
      end
      files
    end

    # According to the [ePub 3 spec on item elements][1], the media-type attribute
    # should be defined in accordance with [MIME document RFC2046][2].
    #
    # [1]: http://www.idpf.org/epub/30/spec/epub30-publications.html#elemdef-package-item
    # [2]: http://tools.ietf.org/html/rfc2046
    def media_type_for(file_name)
      case File.extname(file_name)
      when '.mp3'
        'audio/basic'
      when '.mov', '.mp4'
        'video/mpg'
      when '.jpg', '.png', '.gif'
        "image/#{File.extname(file_name).gsub('.', '')}"
      end
    end
  end
end
