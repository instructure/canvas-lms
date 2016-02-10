class BeginPsychMigration < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::PsychMigration.run if CANVAS_RAILS4_0 || !Rails.env.test?
  end

  def down
  end
end
