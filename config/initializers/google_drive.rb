
GoogleDrive::Connection.config = proc do
  settings = Canvas::Plugin.find(:google_drive).try(:settings)
  if settings
    settings = settings.dup
    settings[:client_secret] = settings[:client_secret_dec]
  end
  settings || ConfigFile.load('google_drive')
end
