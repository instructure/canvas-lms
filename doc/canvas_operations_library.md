
# CanvasOperations

A library for running common operations in deployed Canvas environments, with consistent logging, metric emission, progress tracking, and error handling, and more.

See [`lib/canvas_operations`](../lib/canvas_operations)

## Features
- **Operation Base Class**: All operations inherit from a common base, ensuring consistent behavior and features.
- **Shard Binding**: Operations are bound to a single Switchman shard for data consistency.
- **Progress Tracking**: Integrated with a `Progress` model for tracking and reporting.
- **Metric Emission**: Emits events to InstStatsd for monitoring operation lifecycle.
- **Configurable Settings**: Per-operation, per-cluster settings.
- **Callbacks**: Lifecycle hooks for before/after/around run and failure events.
- **Error Handling**: Standardized error classes for shard and mode validation.

## Usage

### Creating a New Operation

Subclass `CanvasOperations::BaseOperation` and override the `execute` method:

```ruby
class EnableCoolFeatures < CanvasOperations::BaseOperation
  # define callbacks for your operation
  before_run :validate_feature_prerequisites
  after_run :notify_stakeholders
  after_failure :notify_engineering_team

  # define settings that can be changed on-the-fly
  setting :feature_list, default: "feature_one"
  setting :stakeholder_notification_channel, default: "#releases"

  def execute
    log_message("Enabling features #{feature_list}!")
  end

  def validate_feature_prerequisites
    raise "Prerequisites not met!" unless ...
  end

  def notify_stakeholders
    SlackClient.post_message(
      channel: stakeholder_notification_channel,
      text: "The following features have been enabled: #{feature_list}"
    )
  end

  def notify_engineering_team
    SlackClient.post_message(
      channel: "#engineering-alerts",
      text: "#{name} failed! Please investigate."
    )
  end
end
```

Run the operation:

```ruby
MyOperation.new.run_later
```

Operations are run in an async job via the inst-jobs gem.

See [`lib/canvas_operations/base_operation.rb`](../lib/canvas_operations/base_operation.rb) for more details on available methods and features.

See [`lib/canvas_operations/base_concerns/settings.rb`](../lib/canvas_operations/base_concerns/settings.rb) for more details on using operation settings.

See [`lib/canvas_operations/base_concerns/callbacks.rb`](../lib/canvas_operations/base_concerns/callbacks.rb) for more details on using operation callbacks.

### DataFixup Operations

As described above, the base operation class can be subclassed for specific use cases. The `DataFixup` operation class serves as an example of this pattern, but is also a useful tool in its own right.

The `DataFixup` operation provides a standard framework for efficiently performing data fixups that require processing large numbers of records, either individually or in batches.

To use this operation, create a subclass of `CanvasOperations::DataFixup`:

```ruby
module DataFixup
  module InstructureIdentity
    class UnsetAuthlogicAttributesOnInstPseudonyms < CanvasOperations::DataFixup
      # Optionally override setting defaults (more details below)
      setting :range_batch_size, default: 10_000, type_cast: :to_i

      # Should records be yielded one at a time, or in batches? (more details below)
      self.mode = :batch

      # Define the scope of records to process (more details below)
      scope do
        Pseudonym.instructure_identity.where(
          "ABS(EXTRACT(EPOCH FROM (pseudonyms.last_request_at - pseudonyms.created_at))) <= 1"
        ).where(
          login_count: 1
        ).where.not(
          last_request_at: nil
        )
      end

      # Define how to process a batch of records (more details below)
      def process_batch(pseudonym_batch)
        pseudonym_batch.update_all(last_request_at: nil, current_login_at: nil, current_login_ip: nil)
      end
    end
  end
end
```

and then instantiate and call `run_later` on your fixup from a migration:

```ruby
# db/migrate/20250820214915_unset_authlogic_attributes_on_inst_pseudonyms.rb
class UnsetAuthlogicAttributesOnInstPseudonyms < ActiveRecord::Migration[7.2]
  tag :postdeploy

  def up
    DataFixup::InstructureIdentity::UnsetAuthlogicAttributesOnInstPseudonyms.new.run_later
  end
end
```


#### DataFixup Properties

| Property                | Description |
|-------------------------|-------------|
| `mode`                  | Controls how records are yielded to your processing logic. <br> - `:individual_record`: Each record is yielded one at a time to the `process_record` method.<br> - `:batch`: Records are yielded in batches to the `process_batch` method. <br> No matter which you choose, records are loaded efficiently in batches. |
| `scope`                 | The ActiveRecord scope that defines the set of records to be processed by the fixup. |
| `process_record(record)` | (For `:individual_record` mode) Define this method to specify how to process each individual record. |
| `process_batch(records)` | (For `:batch` mode) Define this method to specify how to process a batch of records. |

#### DataFixup Settings

| Setting                   | Description |
|---------------------------|-------------|
| `range_batch_size`        | How many IDs per chunk `find_ids_in_ranges` should yield. Larger numbers result in your `scope` query being run less often, but over a larger set of rows. |
| `job_scheduled_sleep_time`| How long, in seconds, to sleep between scheduling an async batch of work. Increasing this value can help if the jobs cluster primary is getting hit too hard. |
| `processing_sleep_time`   | How long, in seconds, to sleep between processing batches or individual records. Increasing this value can help if the cluster's primary node is getting hit too hard. |

These settings can be changed on-the-fly; just be sure to send SIGHUP to job hosts to ensure configuration is reloaded.

A data fixup operation and associated files can be generated with `rails g data_fixup <OperationName>`.

See [`lib/canvas_operations/base_concerns/settings.rb`](lib/canvas_operations/base_concerns/settings.rb) for more details on using operation settings.


