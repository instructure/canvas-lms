class Canvas::Crocodoc
  def self.config
    PluginSetting.settings_for_plugin(:crocodoc)
  end

  def self.enabled?
    !!PluginSetting.settings_for_plugin(:crocodoc)
  end

  class TimeoutError < Exception
  end

  class CutoffError < Exception
  end
end
