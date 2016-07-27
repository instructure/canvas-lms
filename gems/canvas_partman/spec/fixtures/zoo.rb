class CanvasPartmanTest::Zoo < ActiveRecord::Base
  self.table_name = 'partman_zoos'

  has_many :animals,
    class_name: 'CanvasPartmanTest::Animal',
    dependent: :destroy

  has_many :trails,
           class_name: 'CanvasPartmanTest::Trail',
           dependent: :destroy

  def self.create_schema
    self.drop_schema

    SchemaHelper.create_table :partman_zoos do |t|
      t.timestamps null: false
    end
  end

  def self.drop_schema
    SchemaHelper.drop_table :partman_zoos
  end
end
