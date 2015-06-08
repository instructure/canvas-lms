LinkedIn::Connection.config = Proc.new do
  settings = Canvas::Plugin.find(:linked_in).try(:settings)
  if settings
    {
      api_key: settings[:client_id],
      secret_key: settings[:client_secret_dec]
    }
  else
    ConfigFile.load('linked_in')
  end
end
