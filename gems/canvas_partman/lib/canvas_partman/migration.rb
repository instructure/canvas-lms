require 'active_record/migration'

module CanvasPartman
  class Migration < ActiveRecord::Migration
    class << self
      # @attr [CanvasPartman::Partitioned] base_class
      #  The partitioned ActiveRecord::Base model _class_ we're modifying
      attr_accessor :base_class
    end

    def with_each_partition(&block)
      find_partition_tables.each(&block)
    end

    # Bind the migration to apply only on a certain partition table. Routines
    # like #with_each_partition will yield only the specified table instead.
    #
    # @param [String] table_name
    #   Name of the **existing** partition table.
    def restrict_to_partition(table_name)
      @partition_scope = table_name
      yield
    ensure
      @partition_scope = nil
    end

    def self.connection
      (base_class || ActiveRecord::Base).connection
    end

    private

    def partition_manager
      @partition_manager ||= PartitionManager.new(self.class.base_class)
    end

    def find_partition_tables
      return [ @partition_scope ] if @partition_scope

      partition_manager.partition_tables
    end
  end
end
