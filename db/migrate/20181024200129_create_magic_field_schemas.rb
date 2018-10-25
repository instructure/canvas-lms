class CreateMagicFieldSchemas < ActiveRecord::Migration
  tag :predeploy
  def change
    create_table :magic_field_schemas do |t|
      t.string :field_key
      t.text :schema_json

      t.timestamps

      t.index :field_key
    end
  end
end
