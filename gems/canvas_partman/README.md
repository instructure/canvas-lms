# CanvasPartman

> Work in progress.

Helpers for dynamically managing postgres partitions and an ActiveRecord::Base layer for managing partitioned models.

## Usage

Let's say we have a `Newsletter` model which we want to partition by periods of months. We will always be creating one partition in advance for the coming month's publishes, and initially we'll create one for the current month so we can start storing data.

First, we begin by making our model partitionable. We do that by including the concern `CanvasPartman::Concerns::Partitioned`.

```ruby
class Newsletter < ActiveRecord::Base
    include CanvasPartman::Concerns::Partitioned

    # self.partitioning_field = 'created_at'
    # self.partitioning_interval = :months
end
```

You can tune several partitioning parameters which you can find in the concern's source docs, and you can (and should) define a schema builder (more on that later.)

The next step is to set up our partitions so that we can start creating records.

```ruby
partman = CanvasPartman::PartitionManager.new(Newsletter)

# a partition for this month's data:
partman.create_partition(Time.now)

# and another for the coming month:
partman.create_partition(1.month.from_now)
```

That's actually all you need to get started. However, you should be aware that due to way inheritance (and by extension, partitioning) works in postgres, any indices or constraints you define on the master table **are not** inherited when we create a partition. This means, you can't really use the regular approach of a single, static migration to set up the necessary database schema, instead we have to define it "dynamically".

### Partition schema management

`canvas-partman` provides you with a "schema builder" that works just like a regular migration but is instead evaluated at partition-creation time (so there's no up/down, per se.) Keep in mind that the intent of this is separate from migrations; if you decide you need to change something in the schema of the *existing* partitions later on, you can still write a regular migration that would modify the existing tables, and you'd adjust the schema builder so that any newly created partitions will pick up those modifications.

There two equivalent ways to define the schema builder. The first defines the schema *inline* in the model, the other defines the schema via the PartitionManager API, which you will probably use in a rake task or something.

You can choose whichever style suits you. Here are two examples:

#### Inline schema builder

```ruby
class Newsletter
    partitioned do |t|
        t.index :title, name: 'newsletter_title_index'
        t.index :publisher_id, unique: false

        # if you're using the foreign_key gem, you can actually use it here:
        add_foreign_key :publisher_id
    end
end
```

#### External schema builder

Pass a block to `PartitionManager#create_partition`:

```ruby
partman = CanvasPartman::PartitionManager.new(Newsletter)
partman.create_partition(Time.now) do |t|
    t.index :title, name: 'newsletter_title_index'
    t.index :publisher_id, unique: false

    add_foreign_key :publisher_id
end
```

# TODO

- We need to configure postgres's constraint_exclusion to be `partition` - see: http://www.postgresql.org/docs/9.1/static/runtime-config-query.html#GUC-CONSTRAINT-EXCLUSION [**Update**: this is not necessary as it is the default setting]
- Need to come up with a way to use regular, multiple/successive migrations for partition schemas instead of a single "snapshot" of how the latest version of the schema looks like