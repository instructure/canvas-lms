class CreateCustomData < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_table :custom_data do |t|
      t.text :data
      t.string :namespace
      t.references :user, :limit => 8
      t.timestamps null: true
    end
  end

  def self.down
    drop_table :custom_data
  end
end
