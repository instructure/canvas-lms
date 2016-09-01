module MathMan
  def self.url_for(latex:, target:)
    "#{base_url}/#{target}?tex=#{latex}"
  end

  def self.use_for_mml?
    with_plugin_settings do |plugin_settings|
      Canvas::Plugin.value_to_boolean(
        plugin_settings[:use_for_mml]
      )
    end
  end

  def self.use_for_svg?
    with_plugin_settings do |plugin_settings|
      Canvas::Plugin.value_to_boolean(
        plugin_settings[:use_for_svg]
      )
    end
  end

  private
  def self.base_url
    with_plugin_settings do |plugin_settings|
      plugin_settings[:base_url].sub(/\/$/, '')
    end
  end

  def self.with_plugin_settings
    plugin_settings = Canvas::Plugin.find(:mathman).settings
    yield plugin_settings
  end
end
