class CanvasPartmanTest::Trail < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned
  self.partitioning_strategy = :by_id
  self.partitioning_field = 'zoo_id'
  self.partition_size = 5

  self.table_name = 'partman_trails'

  belongs_to :zoo, class_name: 'CanvasPartmanTest::Zoo'

  def self.create_schema
    self.drop_schema

    CanvasPartmanTest::SchemaHelper.create_table :partman_trails do |t|
      t.string :name
      t.references :zoo
    end
  end

  def self.drop_schema
    CanvasPartmanTest::SchemaHelper.drop_table :partman_trails, cascade: true
  end
end