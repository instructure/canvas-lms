LinkedIn::Connection.config = Proc.new do
  Canvas::Plugin.find(:linked_in).try(:settings) || ConfigFile.load('linked_in')
end
