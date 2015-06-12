class CanvasPartmanTest::Animal < ActiveRecord::Base
  include CanvasPartman::Concerns::Partitioned

  self.table_name = 'partman_animals'

  belongs_to :zoo, class_name: 'CanvasPartmanTest::Zoo'

  def self.create_schema
    self.drop_schema

    CanvasPartmanTest::SchemaHelper.create_table :partman_animals do |t|
      t.string :race
      t.datetime :created_at
      t.references :zoo
    end
  end

  def self.drop_schema
    CanvasPartmanTest::SchemaHelper.drop_table :partman_animals, cascade: true
  end
end