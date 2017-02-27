module CanvasPartman::Concerns
  # Mix into a model to enforce partitioning behavior.
  #
  # @warn
  #  Normal CRUD operations will no longer work on the master table once a model
  #  becomes Partitioned; you are responsible for maintaining a valid partition
  #  for *every* record you try to create or modify.
  module Partitioned
    def self.included(base)
      base.singleton_class.include(ClassMethods)
      base.partitioning_strategy = :by_date
    end

    module ClassMethods
      # @attr [Symbol] parititioning_strategy
      #  How to partition the table. Allowed values are one of:
      #  [ :by_date, :by_id ]
      #
      # Default value is :by_date
      attr_reader :partitioning_strategy

      def partitioning_strategy=(value)
        raise ArgumentError unless [:by_date, :by_id].include?(value)

        if value == :by_date
          self.partitioning_field = "created_at"
          self.partitioning_interval = :months
        elsif value == :by_id
          self.partitioning_field = nil
          self.partition_size = 1_000_000
        end
        @partitioning_strategy = value
      end

      # @attr [String] partitioning_field
      #  Name of the database column which contains the data we'll use to
      #  locate the correct partition for the records. Only applies to
      #  :by_date partitioning_strategy
      #
      #  This should point to a Time field of some sorts.
      #
      #  Default value is "created_at" for :by_date partitioning,
      #  or unset for :by_id partitioning.
      attr_accessor :partitioning_field

      # @attr [Symbol] partitioning_interval
      #  A time interval to partition the table over. Only applies to
      #  :by_date partitioning_strategy
      #  Allowed values are one of: [ :months, :years ]
      #
      #  Default value is :months.
      #
      #  Note that only :months has been officially tested, YMMV for other
      #  intervals.
      attr_reader :partitioning_interval

      def partitioning_interval=(value)
        raise ArgumentError unless [:months, :years].include?(value)

        @partitioning_interval = value
      end

      # @attr [Integer]  partition_size
      #  How large each partition is. Only applies to
      #  :by_id partitioning_strategy
      #
      # Default value is 1_000_000
      attr_accessor :partition_size

      # Convenience method for configuring a :by_date Partitioned model.
      #
      # @param [String] on
      #   Partitioning field.
      #
      # @param [Symbol] over
      #   Partitioning interval.
      def partitioned(on: nil, over: nil)
        self.partitioning_strategy = :by_date
        self.partitioning_field = on.to_s if on
        self.partitioning_interval = over.to_sym if over
      end

      # :nodoc:
      #
      # @override ActiveRecord::Persistence#unscoped
      # @see CanvasPartman::DynamicRelation
      # @internal
      #
      # Monkey patch the relation we'll use for queries.
      def unscoped
        super.tap do |relation|
          relation.send :extend, CanvasPartman::DynamicRelation
        end
      end

      # :nodoc:
      def arel_table_from_key_values(attributes)
        partition_table_name = infer_partition_table_name(attributes)

        @arel_tables ||= {}
        @arel_tables[partition_table_name] ||= begin
          if ::ActiveRecord.version < Gem::Version.new('5')
            Arel::Table.new(partition_table_name, { engine: self.arel_engine })
          else
            Arel::Table.new(partition_table_name, type_caster: type_caster)
          end
        end
      end

      # @internal
      #
      # Come up with the table name for the partition the record with the given
      # attribute pairs should be placed in.
      #
      # @param [Array<Array<String, Mixed>>] attributes
      #  Attribute pairs the model is being created/updated with. You can use
      #  these to infer the partition name, e.g, based on :created_at.
      #
      # @return [String]
      #  The table name for the partition.
      def infer_partition_table_name(attributes)
        attr = attributes.detect { |(k, _v)| k.name == partitioning_field }

        if attr.nil? || attr[1].nil?
          raise ArgumentError.new <<-ERROR
            Partition resolution failure!!!
            Expected "#{partitioning_field}" attribute to be present in set and
            have a value, but was or did not:

            #{attributes}
          ERROR
        end

        if partitioning_strategy == :by_date
          date = attr[1]
          date = date.utc if ActiveRecord::Base.default_timezone == :utc

          case partitioning_interval
          when :months
            [ table_name, date.year, date.month ].join('_')
          when :years
            [ table_name, date.year ].join('_')
          end
        else
          id = attr[1]
          [ table_name, id / partition_size ].join('_')
        end
      end
    end
  end
end
