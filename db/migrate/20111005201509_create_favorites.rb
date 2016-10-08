class CreateFavorites < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :favorites do |t|
      t.integer :user_id, :limit => 8
      t.integer :context_id, :limit => 8
      t.string :context_type

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :favorites
  end
end
