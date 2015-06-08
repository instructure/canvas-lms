Twitter::Connection.config = Proc.new do
  settings = Canvas::Plugin.find(:twitter).try(:settings)
  if settings
    {
        api_key: settings[:consumer_key],
        secret_key: settings[:consumer_secret_dec]
    }
  else
    ConfigFile.load('twitter')
  end
end