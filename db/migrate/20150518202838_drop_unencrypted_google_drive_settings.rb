class DropUnencryptedGoogleDriveSettings < ActiveRecord::Migration
  tag :postdeploy

  def up
    # the encryption callback automatically drops the unencrypted version
    PluginSetting.where(name: 'google_drive').each(&:save!)
  end
end
