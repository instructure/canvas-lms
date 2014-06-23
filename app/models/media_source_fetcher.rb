class MediaSourceFetcher
  def initialize(api_client)
    @api_client = api_client
  end

  def fetch_preferred_source_url(options={})
    file_extension = options[:file_extension]
    media_type = options[:media_type]

    if file_extension && media_type
      raise ArgumentError.new("file_extension and media_type should not both be present. file_extension is only here to support legacy behavior.")
    end

    media_sources = @api_client.media_sources(options[:media_id])

    return nil if media_sources.empty?

    source = case media_type
             when 'video'
               find_by_file_extension(media_sources, 'mp4')
             when 'audio'
               find_by_file_extension(media_sources, 'mp3') || find_by_file_extension(media_sources, 'mp4')
             else
               find_by_file_extension(media_sources, file_extension)
             end

    source[:url]
  end

  private

  def find_by_file_extension(sources, file_extension)
    sources.find { |s| s[:fileExt] == file_extension }
  end
end
