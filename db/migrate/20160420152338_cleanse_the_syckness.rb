class CleanseTheSyckness < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    if CANVAS_RAILS4_2
      DataFixup::SycknessCleanser.columns_hash.each do |model, columns|
        DataFixup::SycknessCleanser.send_later_if_production_enqueue_args(:run,
          {:strand => "syckness_cleanse_#{Shard.current.database_server.id}", :priority => Delayed::MAX_PRIORITY}, model, columns)
      end
    else
      if User.exists? # don't raise for a fresh install
        raise "WARNING:\n
          This migration needs to be run under Rails 4.2.\n"
      end
    end
  end

  def down
  end
end
