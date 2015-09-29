module CC::Exporter::Epub::Converters
  module MediaConverter
    include CC::CCHelper

    def convert_media_from_node!(html_node)
      html_node.tap do |node|
        convert_media_paths!(node)
        convert_audio_tags!(node)
        convert_video_tags!(node)
      end
    end

    def convert_media_from_string!(html_string)
      html_node = Nokogiri::HTML::DocumentFragment.parse(html_string)
      convert_media_from_node!(html_node).to_s
    end

    def convert_media_paths!(html_node)
      { a: 'href', img: 'src' }.each do |tag, attr|
        html_node.search(tag).each do |match|
          match[attr] = CGI.unescape(match[attr]).gsub(WEB_CONTENT_TOKEN, CC::Exporter::Epub::FILE_PATH)
        end
      end
    end

    def convert_audio_tags!(html_node)
      html_node.search('a.instructure_audio_link, a.audio_comment').each do |audio_link|
        audio_link.replace(<<-AUDIO_TAG)
          <audio src="#{audio_link['href']}" controls="controls" />
        AUDIO_TAG
      end
    end

    def convert_video_tags!(html_node)
      html_node.search('a.instructure_video_link, a.video_comment').each do |video_link|
        video_link.replace(<<-VIDEO_TAG)
          <video src="#{video_link['href']}" controls="controls" />
        VIDEO_TAG
      end
    end
  end
end
