class CanvasLinkedInConfig

  def self.call
    settings = Canvas::Plugin.find(:linked_in).try(:settings)
    if settings
      {
        api_key: settings[:client_id],
        secret_key: settings[:client_secret_dec]
      }.with_indifferent_access
    else
      ConfigFile.load('linked_in')
    end

  end
end

LinkedIn::Connection.config = CanvasLinkedInConfig
