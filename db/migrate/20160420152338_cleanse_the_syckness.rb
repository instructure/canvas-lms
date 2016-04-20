class CleanseTheSyckness < ActiveRecord::Migration
  tag :postdeploy

  def up
    DataFixup::SycknessCleanser.send_later_if_production_enqueue_args(:run, {:strand => Shard.current.database_server.id.to_s})
  end

  def down
  end
end
