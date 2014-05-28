LinkedIn::Connection.config = Proc.new do
  Canvas::Plugin.find(:linked_in).try(:settings) || Setting.from_config('linked_in')
end
