module Canvas::Plugins::Validators::KalturaValidator
  def self.validate(settings, plugin_setting)
    if settings.map(&:last).all?(&:blank?)
      {}
    else
      if settings.map(&:last).any?(&:blank?)
        plugin_setting.errors.add_to_base('All fields are required')
        false
      else
        settings.slice(:domain, :resource_domain, :partner_id, :subpartner_id, :secret_key, :user_secret_key, :player_ui_conf, :kcw_ui_conf, :upload_ui_conf)
      end
    end
  end
end