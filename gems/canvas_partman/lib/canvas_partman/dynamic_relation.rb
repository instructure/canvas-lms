module CanvasPartman
  # Monkey patch for ActiveRecord::Relation to dynamically resolve the proper
  # partition table for a record.
  module DynamicRelation
    def insert(values)
      @table = @klass.arel_table_from_key_values(values)

      super
    end # insert
  end
end