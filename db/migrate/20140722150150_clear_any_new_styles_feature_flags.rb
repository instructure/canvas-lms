class ClearAnyNewStylesFeatureFlags < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    DataFixup::ClearFeatureFlags.run_async('new_styles')
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
