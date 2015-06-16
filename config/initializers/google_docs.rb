
GoogleDocs::DriveConnection.config = Proc.new do
  Canvas::Plugin.find(:google_drive).try(:settings) || ConfigFile.load('google_drive')
end

GoogleDocs::Connection.config = Proc.new do
  Canvas::Plugin.find(:google_docs).try(:settings) || ConfigFile.load('google_docs')
end

GoogleDocs::Entry.extension_looker_upper = ScribdMimeType
