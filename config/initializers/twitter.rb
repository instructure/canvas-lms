class CanvasTwitterConfig

  def self.call
    settings = Canvas::Plugin.find(:twitter).try(:settings)
    if settings
      {
        api_key: settings[:consumer_key],
        secret_key: settings[:consumer_secret_dec]
      }.with_indifferent_access
    else
      ConfigFile.load('twitter')
    end

  end
end


Twitter::Connection.config = CanvasTwitterConfig
