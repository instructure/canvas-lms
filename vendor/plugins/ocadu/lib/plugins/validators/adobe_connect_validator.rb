module Canvas::Plugins::Validators::AdobeConnectValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      if settings.size != 4 || settings.map(&:last).any?(&:blank?)
        plugin_setting.errors.add_to_base(I18n.t('canvas.plugins.errors.all_fields_required', 'All fields are required'))
        false
      else
        settings.slice(:domain, :login, :password, :meeting_container)
      end
    end
  end
end