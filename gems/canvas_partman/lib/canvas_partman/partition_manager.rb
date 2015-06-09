module CanvasPartman
  class PartitionManager
    attr_reader :base_class

    def initialize(base_class)
      unless base_class < Concerns::Partitioned
        raise ArgumentError.new <<-ERROR
          PartitionManager can only work on models that are Partitioned.
          See CanvasPartman::Concerns::Partitioned.
        ERROR
      end

      @base_class = base_class
    end

    # Ensure the current partition, and n future partitions exist
    #
    # @param [Fixnum] advance
    #   The number of partitions to create in advance
    def ensure_partitions(advance = 1)
      current = Time.now.utc.send("beginning_of_#{base_class.partitioning_interval.to_s.singularize}")
      (advance + 1).times do
        unless partition_exists?(current)
          create_partition(current)
        end
        current += 1.send(base_class.partitioning_interval)
      end
    end

    # Prune old partitions
    #
    # @param [Fixnum] number_to_keep
    #   The number of partitions to keep (excluding the current partition)
    def prune_partitions(number_to_keep = 6)
      min_to_keep = Time.now.utc.send("beginning_of_#{base_class.partitioning_interval.to_s.singularize}")
      # on 5/1, we want to drop 10/1
      # (keeping 11, 12, 1, 2, 3, and 4 - 6 months of data)
      min_to_keep -= number_to_keep.send(base_class.partitioning_interval)

      partition_tables.each do |table|
        partition_date = date_from_partition_name(table)
        base_class.connection.drop_table(table) if partition_date < min_to_keep
      end
    end

    # Create a new partition table.
    #
    # @param [Hash] options
    # @param [Boolean] options[:graceful]
    #   Do nothing if the partition table already exists.
    #
    # @return [String]
    #  The name of the newly created partition table.
    def create_partition(date, options={})
      master_table = base_class.table_name
      partition_table = generate_name_for_partition(date)

      if options[:graceful] == true
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

        find_and_load_migrations.each do |migration|
          migration.restrict_to_partition(partition_table) do
            migration.migrate(:up)
          end
        end

        partition_table
      end
    end

    def partition_tables
      base_class.connection.tables.grep(table_regex)
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

    def table_regex
      @table_regex ||= case base_class.partitioning_interval
                       when :months
                         /^#{Regexp.escape(base_class.table_name)}_(?<year>\d{4,})_(?<month>\d{1,2})$/.freeze
                       when :years
                         /^#{Regexp.escape(base_class.table_name)}_(?<year>\d{4,})$/.freeze
                       end
    end

    def generate_name_for_partition(date)
      date_attr = Arel::Attributes::Attribute.new(nil, base_class.partitioning_field)

      attributes = {}
      attributes[date_attr] = date

      base_class.infer_partition_table_name(attributes)
    end

    def date_from_partition_name(name)
      match = table_regex.match(name)
      return nil unless match
      Time.utc(*match[1..-1])
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

    def find_and_load_migrations
      ActiveRecord::Migrator.migrations(CanvasPartman.migrations_path).reduce([]) do |migrations, proxy|
        if proxy.scope == CanvasPartman.migrations_scope
          require(File.expand_path(proxy.filename))

          migration_klass = proxy.name.constantize

          if migration_klass.base_class == base_class
            migrations << migration_klass.new
          end
        end

        migrations
      end
    end

    def execute(*args)
      base_class.connection.execute(*args)
    end
  end
end