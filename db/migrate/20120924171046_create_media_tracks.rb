class CreateMediaTracks < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :media_tracks do |t|
      t.integer :user_id,         :limit => 8
      t.integer :media_object_id, :limit => 8
      t.string :kind,             :default => "subtitles"
      t.string :locale,           :default => "en"
      t.text :content

      t.timestamps
    end

    add_index :media_tracks, [:media_object_id, :locale], :name => 'media_object_id_locale'

  end

  def self.down
    drop_table :media_tracks
  end
end
