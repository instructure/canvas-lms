require 'canvas_partman/migration'

module CanvasPartman
  class PartitionManager
    attr_reader :base_class

    def initialize(base_class)
      unless base_class.respond_to?(:partitioned?)
        raise ArgumentError.new <<-ERROR
          PartitionManager can only work on models that are Partitioned.
          See CanvasPartman::Concerns::Partitioned.
        ERROR
      end

      @base_class = base_class
    end

    # Create a new partition table.
    #
    # @argument [Symbol, :months] precision
    #   The date "precision" by which to partition the table. Currently only
    #   month partitioning is supported.
    #
    #   Allowed values: [:months, :years]
    #
    # @argument [Proc] &block
    #  If you pass a block, it will be called with an instance of a migration
    #  runner that you can use to customize the schema of the partition table.
    #
    #  This is the place to define indices and constraints.
    #
    #  The DSL is similar to what you use in regular AR migrations.
    #
    # @return [String]
    #  The name of the newly created partition table.
    def create_partition(date, opts={}, &block)
      master_table = base_class.table_name
      partition_table = generate_name_for_partition(date)

      if opts[:graceful] == true
        return if partition_exists?(partition_table)
      end

      constraint_field = base_class.partitioning_field
      constraint_range = generate_date_constraint_range(date).map do |date|
        date.to_s(:db)
      end

      base_class.transaction do
        execute <<-SQL
          CREATE TABLE #{partition_table} (
            CONSTRAINT #{partition_table}_pkey PRIMARY KEY (id),
            CHECK (
              #{constraint_field} >= TIMESTAMP '#{constraint_range[0]}'
              AND
              #{constraint_field} < TIMESTAMP '#{constraint_range[1]}'
            )
          )
          INHERITS (#{master_table});
        SQL

        if schema_builder = (block || base_class.partitioning_schema_builder)
          migration = CanvasPartman::Migration.new(partition_table, schema_builder)
          migration.exec_migration(base_class.connection, :up)
        end

        partition_table
      end
    end

    def partition_exists?(date_or_name)
      table_name = if date_or_name.kind_of?(Time)
        generate_name_for_partition(date_or_name)
      else
        date_or_name
      end

      base_class.connection.table_exists?(table_name)
    end

    def drop_partition(date)
      partition_table = generate_name_for_partition(date)

      base_class.connection.drop_table(partition_table)
    end

    protected

    def generate_name_for_partition(date)
      date_attr = Arel::Attributes::Attribute.new(nil, base_class.partitioning_field)

      attributes = {}
      attributes[date_attr] = date

      base_class.infer_partition_table_name(attributes)
    end

    def generate_date_constraint_range(date)
      case base_class.partitioning_interval
      when :months
        [
          0.month.from_now(date).beginning_of_month,
          1.month.from_now(date).beginning_of_month
        ]
      when :years
        [
          0.year.from_now(date).beginning_of_year,
          1.year.from_now(date).beginning_of_year
        ]
      else
        raise NotImplementedError.new <<-ERROR
          Only [:months,:years] are currently supported as a partitioning
          interval.
        ERROR
      end
    end

    def execute(*args)
      base_class.connection.execute(*args)
    end
  end
end