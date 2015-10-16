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

    # Find `<a>` or `<img>` tags and update the resource path attr (href or src)
    # to replace WEB_CONTENT_TOKEN with CC::Exporter::Epub::FILE_PATH.
    #
    # Turns this:
    #
    # "$IMS-CC-FILEBASE$/image.jpg"
    #
    # into this:
    #
    # "media/image.jpg"
    #
    # which will match the directory the content is stored in in the ePub.
    def convert_media_paths!(html_node)
      { a: 'href', img: 'src' }.each do |tag, attr|
        html_node.search(tag).each do |match|
          unescaped = CGI.unescape(match[attr]).gsub(/\?.*/, '')
          match[attr] = File.join(
            File.dirname(unescaped).gsub(WEB_CONTENT_TOKEN, CC::Exporter::Epub::FILE_PATH),
            CGI.escape(File.basename(unescaped))
          )
        end
      end
    end

    # Find `<a>` tags with class `instructure_audio_link` and replaces it with
    # an audio tag, which is supported by ePub documents.
    #
    # Turns this:
    #
    # "<a class='instructure_audio_link' href='media/audio.mp3'>Here is your audio link</a>
    #
    # into this:
    #
    # "<audio src='media/audio.mp3' controls='controls' />
    def convert_audio_tags!(html_node)
      html_node.search('a.instructure_audio_link, a.audio_comment').each do |audio_link|
        audio_link.replace(<<-AUDIO_TAG)
          <audio src="#{audio_link['href']}" controls="controls">
            #{I18n.t('Audio content is not supported by your device or app.')}
          </audio>
        AUDIO_TAG
      end
    end

    # Find `<a>` tags with class `instructure_video_link` and replaces it with
    # a audio tag, which is supported by ePub documents.
    #
    # Turns this:
    #
    # "<a class='instructure_video_link' href='media/video.mp4'>Here is your video link</a>
    #
    # into this:
    #
    # "<video src='media/video.mp4' controls='controls' />
    def convert_video_tags!(html_node)
      html_node.search('a.instructure_video_link, a.video_comment').each do |video_link|
        video_link.replace(<<-VIDEO_TAG)
          <video src="#{video_link['href']}" controls="controls">
            #{I18n.t('Video content is not supported by your device or app.')}
          </video>
        VIDEO_TAG
      end
    end
  end
end
