class DropUnencryptedGoogleDriveSettings < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    # the encryption callback automatically drops the unencrypted version
    PluginSetting.where(name: 'google_drive').each(&:save!)
  end
end
