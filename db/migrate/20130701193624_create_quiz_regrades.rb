class CreateQuizRegrades < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :quiz_regrades do |t|
      t.integer :user_id, limit: 8, null: false
      t.integer :quiz_id, limit: 8, null: false
      t.integer :quiz_version, null: false
      t.timestamps null: true
    end

    add_index :quiz_regrades, [:quiz_id, :quiz_version], unique: true
  end

  def self.down
    drop_table :quiz_regrades
  end
end
