Twitter::Connection.config = Proc.new do
  Canvas::Plugin.find(:twitter).try(:settings) || Setting.from_config('twitter')
end