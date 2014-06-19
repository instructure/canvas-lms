Twitter::Connection.config = Proc.new do
  Canvas::Plugin.find(:twitter).try(:settings) || ConfigFile.load('twitter')
end