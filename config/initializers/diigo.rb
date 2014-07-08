Diigo::Connection.config = Proc.new do
  Canvas::Plugin.find(:diigo).try(:settings) || ConfigFile.load('diigo')
end
