# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative "base_operation"
require_relative "errors"

module CanvasOperations
  # DataFixup
  #
  # Operation class designed to perform data fixups in a performant way
  # across large datasets in a Canvas environment.
  #
  # DataFixup operations are intended to be run via `run_later` in a migration and can
  # process records either individually or in batches, depending on the
  # configuration.
  #
  # Subclasses should set the `.mode` property and invoke the `.scope` class method to define
  # the operation's processing mode and the ActiveRecord scope to iterate over.
  #
  # The `.mode` can be set to either `:individual_record` or `:batch`:
  #  - `:individual_record`: Each record is processed one at a time via the
  #     `process_record` method.
  #  - `:batch`: Records are processed in batches via the `process_batch` method.
  #
  # Either mode will still iterate over the Canvas data in a performant way.
  #
  # Subclasses must implement either `process_record` (for individual record mode)
  # or `process_batch` (for batch mode) to define the specific fixup logic.
  #
  # The operation will iterate over the defined scope in ID ranges, scheduling
  # background jobs to process each range according to the specified mode.
  class DataFixup < BaseOperation
    VALID_MODES = [:individual_record, :batch].freeze

    setting :range_batch_size, default: 5_000, type_cast: :to_i
    setting :job_scheduled_sleep_time, default: 0.25, type_cast: :to_f
    setting :processing_sleep_time, default: 0.1, type_cast: :to_f

    before_run :ensure_validate_environment
    before_run :ensure_valid_shard

    class << self
      # Get the current mode for this datafixup operation.
      #
      # @return [Symbol, nil] the current mode (:batch or :individual_record), or nil if not set
      attr_reader :mode

      # Set the mode in which the datafixup should operate.
      #
      # Must be one of the values defined in VALID_MODES.
      # Use `self.mode = :batch` or `self.mode = :individual_record` at the class level.
      #
      # @param mode_value [Symbol] the mode to set (:batch or :individual_record)
      def mode=(mode_value)
        raise CanvasOperations::Errors::InvalidPropertyValue, "Invalid mode: #{mode_value}" unless VALID_MODES.include?(mode_value)

        @mode = mode_value
      end

      # The ActiveRecord scope the datafixup should iterate over.
      #
      # Use `scope { Model.where(...) }` at the class level, or override this method
      # for more complex logic that requires instance variables or methods.
      def scope(&block)
        if block_given?
          @scope_block = block
        else
          @scope_block
        end
      end

      # Get the current batch strategy for this datafixup operation.
      #
      # Defaults to `:pluck_ids`, which performs a pluck on the scope (after range filtering),
      # and loads records into memory in batches based on those IDs.
      #
      # @return [Symbol] the current batch strategy
      def batch_strategy
        @batch_strategy || :pluck_ids
      end

      # Set the strategy used for batch loading records after applying range filtering.
      #
      # The DataFixup class always uses the batch size of 1000 in post range-filtering batch loading.
      #
      # @param strategy [Symbol] the batch strategy to use
      attr_writer :batch_strategy
    end

    protected

    # Processes a batch of records. Ideal for making bulk updates to
    # entire batches of rows that don't need to be individually loaded / processed.
    #
    # Subclasses must implement this method to define how to process a batch of records
    #
    # Only used when mode is set to :batch.
    def process_batch(batch); end

    # Processes an individual record. Ideal for when each record needs to be
    # loaded and processed separately.
    #
    # Subclasses must implement this method to define how to process an individual record.
    #
    # Only used when mode is set to :individual_record.
    def process_record(record); end

    # Determines if the current shard is a valid target for the DataFixup operation.
    #
    # By default this method halts the operation on the default shard. Subclasses can
    # override this method to implement custom shard validation logic.
    #
    # Be wary if overriding this method. The default shard contains shadow copies of all
    # root accounts, which may lead to unexpected fixup behavior.
    #
    # @return [Boolean] true if the current shard is not the default, false otherwise.
    def valid_shard?
      !switchman_shard.default?
    end

    private

    # Returns the scope for the current instance.
    # If a scope block is defined in the class, it evaluates and returns the result of that block.
    # Otherwise, raises a NotImplementedError indicating that subclasses must define a scope.
    #
    # This scope is ultimately used to determine the set of records the DataFixup will operate on.
    #
    # @return [Object] the result of the evaluated scope block
    # @raise [NotImplementedError] if no scope block is defined and the method is not overridden in a subclass
    def scope
      scope_block = self.class.scope
      return instance_eval(&scope_block) if scope_block

      raise NotImplementedError, "Subclasses must define scope using `scope { ... }` or implement #scope method"
    end

    # Executes a batch processing operation.
    #
    # Iterates over ID ranges determined by the scope's class, enqueuing jobs to process each range.
    #
    # The batch size for ID ranges can be configured via the `range_batch_size` setting and defaults to 5,000.
    #
    # If a different batch size is more appropriate for your specific data fixup, you can override the
    # `range_batch_size` setting in your subclass.
    #
    # For each batch:
    #   - Checks if any records exist in the current ID range to avoid unnecessary job enqueuing.
    #   - Enqueues a delayed job to process the range.
    #   - Waits between job enqueuing to keep Job DB clusters happy (sleep time configurable via setting).
    #
    # Iterating over ID ranges allows breaking up expensive queries (that may scan large tables) into
    # smaller chunks.
    #
    # Under the hood, this might mean a large query that results in this:
    # ```
    # Seq Scan on pseudonyms  (cost=0.00..5328581.08 rows=21785531 width=2162) (actual time=168.336..196849.531 rows=83613 loops=1)
    #   Filter: ...
    #   Rows Removed by Filter: 59437304
    # Planning Time: 43.621 ms
    # Execution Time: 196870.058 ms
    # ```
    #
    # Becomes many smaller queries like this:
    # ```
    # Index Scan using pseudonyms_pkey on pseudonyms  (cost=0.56..89.91 rows=60 width=2154) (actual time=0.547..0.547 rows=0 loops=1)
    #   Index Cond: ((id >= 1) AND (id <= 1000))
    #   Filter: ...
    #   Rows Removed by Filter: ...
    # Planning Time: 0.274 ms
    # Execution Time: 0.575 ms
    # ```
    #
    # Changing the range_batch_size as described above can help tune performance based on your fixup.
    #
    # @return [void]
    def execute
      GuardRail.activate(:report) do
        scope.klass.find_ids_in_ranges(batch_size: range_batch_size, loose: true) do |min_id, max_id|
          # Don't enqueue a bunch of no-op jobs (at the cost of an extra EXISTS query per batch)
          next unless scope.where(id: min_id..max_id).exists?

          GuardRail.activate(:primary) { delay(n_strand:).process_range(min_id, max_id) }

          wait_between_jobs
        end
      end
    end

    # Processes records within a specified ID range using the configured mode.
    #
    # This method is called asynchronously for each ID range determined during execution.
    #
    # @param min_id [Integer] The minimum ID of the records to process (inclusive).
    # @param max_id [Integer] The maximum ID of the records to process (inclusive).
    # @return [void]
    def process_range(min_id, max_id)
      log_message("Processing records with IDs between #{min_id} and #{max_id}")

      GuardRail.activate(:report) do
        scope.where(id: min_id..max_id).in_batches(strategy: batch_strategy) do |batch|
          case mode
          when :individual_record
            batch.each do |record|
              GuardRail.activate(:primary) { process_record(record) }
              wait_between_processing
            end
          when :batch
            GuardRail.activate(:primary) { process_batch(batch) }
            wait_between_processing
          end
        end
      end
    end

    # Returns a string representing the strand identifier for the current object,
    # composed of the object's name and cluster attribute.
    #
    # It is assumed that a data fixup could be hard on a Database, hence the
    # decision to use cluster IDs in the n_strand by default.
    #
    # @return [String] the strand identifier for the object
    def n_strand
      "#{name}/clusters/#{cluster}"
    end

    def ensure_validate_environment
      return unless in_test_environment_migration?

      raise Errors::InvalidOperationTarget, "DataFixup is being run in a test environment migration, which is not allowed to avoid leaving artifacts"
    end

    def ensure_valid_shard
      raise Errors::InvalidOperationTarget, "DataFixup is being run on an invalid target: #{Shard.current.id}" unless valid_shard?
    end

    def mode
      self.class.mode
    end

    def batch_strategy
      self.class.batch_strategy
    end

    def individual_record_mode?
      mode == :individual_record
    end

    def wait_between_jobs
      log_message("Sleeping between job scheduling for #{job_scheduled_sleep_time} seconds")
      sleep(job_scheduled_sleep_time) # rubocop:disable Lint/NoSleep
    end

    def wait_between_processing
      log_message("Sleeping between processing for #{processing_sleep_time} seconds")
      sleep(processing_sleep_time) # rubocop:disable Lint/NoSleep
    end
  end
end
