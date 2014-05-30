GoogleDocs::Connection.config = Proc.new do
  Canvas::Plugin.find(:google_docs).try(:settings) || Setting.from_config('google_docs')
end

GoogleDocs::Entry.extension_looker_upper = ScribdMimeType