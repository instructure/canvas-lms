require 'active_record/migration'

class CanvasPartman::Migration < ActiveRecord::Migration
  def initialize(table_name, schema_builder)
    @partition_table = table_name
    @schema_builder = schema_builder
  end

  def change
    change_table @partition_table do |t|
      @schema_builder.call(t, @partition_table)
    end
  end

  def exec_migration(conn, direction)
    @connection = conn

    if direction == :down
      revert { change }
    else
      change
    end
  ensure
    @connection = nil
  end
end