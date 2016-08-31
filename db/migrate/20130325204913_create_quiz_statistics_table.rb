class CreateQuizStatisticsTable < ActiveRecord::Migration
  tag :predeploy

  def self.up
    create_table :quiz_statistics do |t|
      t.integer :quiz_id, :limit => 8
      t.boolean :includes_all_versions
      t.boolean :anonymous
      t.timestamps null: true
    end
    add_index :quiz_statistics, :quiz_id
  end

  def self.down
    drop_table :quiz_statistics
  end
end
