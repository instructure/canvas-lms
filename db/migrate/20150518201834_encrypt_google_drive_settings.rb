class EncryptGoogleDriveSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    PluginSetting.where(name: 'google_drive').each do |ps|
      # do a dance so that we don't delete the unencrypted copy yet
      ps.encrypt_settings
      ps.initialize_plugin_setting
      ps.settings[:client_secret] = ps.settings[:client_secret_dec]
      PluginSetting.where(id: ps).update_all(settings: ps.settings.to_yaml)
    end
  end
end
