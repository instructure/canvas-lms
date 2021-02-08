class CreateCanvasMetadata < ActiveRecord::Migration[5.2]
  tag :predeploy

  def change
    create_table :canvas_metadata do |t|
      t.string :key, null: false
      t.jsonb :payload, null: false
      t.timestamps
    end
    add_index :canvas_metadata, :key, unique: true
  end
end
