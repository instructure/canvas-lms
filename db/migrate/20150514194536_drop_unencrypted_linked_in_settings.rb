class DropUnencryptedLinkedInSettings < ActiveRecord::Migration
  tag :postdeploy

  def up
    PluginSetting.where(name: 'linked_in').each do |ps|
      ps.settings.delete(:api_key)
      ps.settings.delete(:secret_key)
      ps.save!
    end
  end
end
