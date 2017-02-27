module CC::Exporter::Epub::Converters
  module FilesConverter
    include CC::CCHelper
    include CC::Exporter

    class FlvToMp4
      def initialize(flv_path)
        @flv_path = flv_path
      end
      attr_reader :flv_path

      def convert!
        begin
          return flv_path unless mp4_url.present?
        # Maybe a weird exception to catch, but that's what ends up being thrown
        # if we pass a media_id that doesn't have a corresponding set of assets.
        rescue NoMethodError => e
          return flv_path
        end

        f = File.open(mp4_path, 'wb')
        CanvasHttp.get(mp4_url) do |response|
          f.write(response.body)
        end
        f.close

        mp4_path
      end

      private
      def flv_filename
        File.basename(flv_path)
      end

      def media_id
        flv_filename.gsub('.flv', '')
      end

      def media_source_fetcher
        @_media_source_fetcher ||= MediaSourceFetcher.new(CanvasKaltura::ClientV3.new)
      end

      def mp4_path
        flv_path.gsub('.flv', '.mp4')
      end

      def mp4_url
        @_mp4_url ||= media_source_fetcher.fetch_preferred_source_url({
          media_id: media_id,
          file_extension: 'mp4'
        })
      end
    end

    class FilePresenter
      include CC::CCHelper

      def initialize(original_path, data, export_type)
        @original_path = original_path
        @data = data
        @export_type = export_type
      end
      attr_reader :data, :original_path

      def to_h
        return {
          identifier: data['identifier'],
          local_path: local_path,
          file_name: File.basename(local_path),
          path_to_file: path_to_file,
          media_type: media_type,
          exists: File.exist?(path_to_file)
        }
      end

      private
      def flv?
        File.extname(original_path) == '.flv'
      end

      # The path for the file in the ePub itself. This method removes the
      # path up to (and including) the standard export placeholder
      # (WEB_RESOURCES_FOLDER) and replaces it with the root folder for media
      # in the ePub (CC::Exporter::Epub::FILE_PATH), while maintaining folder
      # structure beyond the export root.
      #
      # (Note that the path we're working with in this class is the full path
      # to the file, not the path relative to the unzipped export.
      #
      # Changes this:
      #
      # /Users/username/Documents/canvas-lms/exports/d20150930-26055-1wlhczz/web_resources/media_objects/m-ArYKbPPdLwtbhcHPjxYsQvMeDCPZKZp.mp3
      #
      # into this:
      #
      # media/media_objects/m-ArYKbPPdLwtbhcHPjxYsQvMeDCPZKZp.mp3
      #
      # Or this:
      #
      # /Users/username/Documents/canvas-lms/exports/d20150930-26055-1wlhczz/web_resources/m-ArYKbPPdLwtbhcHPjxYsQvMeDCPZKZp.mp3
      #
      # into this:
      #
      # media/m-ArYKbPPdLwtbhcHPjxYsQvMeDCPZKZp.mp3
      def local_path
        unless @_local_path
          file_basename = File.basename(path_to_file)
          file_basename = CGI.escape(file_basename) unless @export_type == :web_zip
          path_args = [
            CC::Exporter::Epub::FILE_PATH,
            File.dirname(original_path.match(/#{WEB_RESOURCES_FOLDER}\/(.+)$/)[1]),
            file_basename
          ].reject do |path_part|
            path_part.match(/^\.$/)
          end
          @_local_path = File.join(path_args)
        end
        @_local_path
      end

      # According to the [ePub 3 spec on item elements][1], the media-type attribute
      # should be defined in accordance with [MIME document RFC2046][2].
      #
      # [1]: http://www.idpf.org/epub/30/spec/epub30-publications.html#elemdef-package-item
      # [2]: http://tools.ietf.org/html/rfc2046
      def media_type
        case File.extname(path_to_file)
        when '.mp3'
          'audio/basic'
        when '.m4v', '.mp4'
          'video/mpg'
        when '.jpg', '.png', '.gif', '.jpeg'
          "image/#{File.extname(path_to_file).delete('.')}"
        else
          nil
        end
      end

      def path_to_file
        @_path_to_file ||= flv? ? FlvToMp4.new(original_path).convert! : original_path
      end
    end

    def convert_files(export_type)
      all_files = @manifest.css("resource[type=#{WEBCONTENT}][href^=#{WEB_RESOURCES_FOLDER}]").map do |res|
        original_path = File.expand_path(get_full_path(res['href']))
        FilePresenter.new(original_path, res, export_type).to_h
      end

      # Unsupported file types will end up with a `nil` media_type, and they
      # should be returned as a separate collection, as the ePub exporter
      # handles unsupported file types differently.
      all_files.partition do |file|
        file[:media_type].present? && file[:exists]
      end
    end
  end
end
