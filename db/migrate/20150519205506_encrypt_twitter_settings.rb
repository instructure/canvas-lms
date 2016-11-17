class EncryptTwitterSettings < ActiveRecord::Migration[4.2]
  tag :predeploy

  def up
    PluginSetting.where(name: 'twitter').each do |ps|
      ps.settings[:consumer_key] = ps.settings[:api_key]
      ps.settings[:consumer_secret] = ps.settings[:secret_key]
      ps.save!
    end
  end
end
