class BeginPsychMigration < ActiveRecord::Migration
  tag :postdeploy

  def self.runnable? # TODO: Remove when we're ready to run this everywhere
    if ApplicationController.respond_to?(:test_cluster?)
      ApplicationController.test_cluster?
    else
      true
    end
  end

  def up
    DataFixup::PsychMigration.run if CANVAS_RAILS4_0 || !Rails.env.test?
  end

  def down
  end
end
