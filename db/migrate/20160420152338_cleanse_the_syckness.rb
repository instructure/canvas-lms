class CleanseTheSyckness < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    DataFixup::SycknessCleanser.columns_hash.each do |model, columns|
      DataFixup::SycknessCleanser.send_later_if_production_enqueue_args(:run,
        {:strand => "syckness_cleanse_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, model, columns)
    end
  end

  def down
  end
end
