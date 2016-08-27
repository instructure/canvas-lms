module MathMan
  def self.base_url
    plugin_setting.settings[:base_url].sub(/\/$/, '')
  end

  def self.enabled?
    plugin_setting.present? && plugin_setting.enabled?
  end

  def self.plugin_setting
    PluginSetting.cached_plugin_setting('mathman')
  end

  def self.url_for(latex:, target:)
    "#{base_url}/#{target}?tex=#{latex}"
  end

  def self.use_for_mml?
    enabled? && Canvas::Plugin.value_to_boolean(
      plugin_setting.settings[:use_for_mml]
    )
  end

  def self.use_for_svg?
    enabled? && Canvas::Plugin.value_to_boolean(
      plugin_setting.settings[:use_for_svg]
    )
  end
end
