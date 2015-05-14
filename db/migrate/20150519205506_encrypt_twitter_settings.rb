class EncryptTwitterSettings < ActiveRecord::Migration
  tag :predeploy

  def up
    PluginSetting.where(name: 'twitter').each do |ps|
      ps.settings[:client_id] = ps.settings[:api_key]
      ps.settings[:client_secret] = ps.settings[:secret_key]
      ps.save!
    end
  end
end
