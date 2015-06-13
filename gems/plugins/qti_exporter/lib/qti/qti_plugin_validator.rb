module Canvas::Plugins::Validators::QtiPluginValidator
  def self.validate(settings, plugin_setting)
    settings.with_indifferent_access.slice(:enabled)
  end
end