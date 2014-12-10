require 'active_record/migration'

class CanvasPartman::Migration < ActiveRecord::Migration
  class << self
    # @attr [String] master_table
    #   Name of the master table which partitions this migration will modify.
    attr_accessor :master_table

    # @attr [CanvasPartman::Partitioned] base_class
    #  The partitioned ActiveRecord::Base model _class_ we're modifying (which is
    #  stored in the master_table we specified earlier.)
    #
    #  If left unspecified, we try to infer the class from the master table name.
    attr_accessor :base_class

    # :nodoc:
    attr_reader :partition_table_matcher
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
    (self.base_class || ActiveRecord::Base).connection
  end

  private

  def self.master_table=(name)
    @master_table = name.to_s.freeze
    @partition_table_matcher = /^#{Regexp.escape(@master_table)}_/.freeze
  end

  def find_partition_tables
    return [ @partition_scope ] if @partition_scope

    self.class.connection.tables.grep(self.class.partition_table_matcher)
  end
end