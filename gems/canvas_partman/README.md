# CanvasPartman

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

You can tune several partitioning parameters which you can find in the concern's source docs.

The next step is to set up our partitions so that we can start creating records.

```ruby
partman = CanvasPartman::PartitionManager.new(Newsletter)

# a partition for this month's data:
partman.create_partition(Time.now)

# and another for the coming month:
partman.create_partition(1.month.from_now)
```

That's actually all you need to get started. However, you should be aware that due to way inheritance (and by extension, partitioning) works in postgres, any indices or constraints you define on the master table **are not** inherited when we create a partition. This means our migrations can not solely deal with the master table if we're doing anything other than adding/changing/dropping columns.

We'll see how to manage the partition schema in the next section.


### Partition schema management

`canvas-partman` defines a custom migration type you can use to manage the schema of all existing (and to-be-created) partition tables. The migrations work, and read, just like regular ActiveRecord migrations but are run in two different ways depending on the context. Basically:

1. all *partition migrations* are run along with the regular ones when using `rake db:migrate`
2. all *partition migrations* for a specific master table are run when a new partition of that master table is created (this is handled implicitly by the PartitionManager)

Item #2 ensures that all newly-created partitions have a consistent schema with their predecessors which may have been migrated over time into their current schema.

#### Writing partition migrations

A custom Rails generator `partition_migration` is made available for generating skeleton partition migrations. Let's create a migration that adds an index on `created_at` for sorting to all existing partitions as well as ones to be created in the future:

```shell
rails generate partition_migration AddCreatedAtIndexToNewsletters newsletters
# create  db/migrate/20141115282317_add_created_at_index_to_newsletters.partitions.rb
```

> Note the `.partitions.rb` part of the generated migration filename;
> more on this in the notes below, at the end of the section.

The generator requires 1 parameter which is similar to the stock `migration` generator and that is the name of the migration. The second optional argument is a string denoting the master table for the partitions. If you leave this unspecified, you will have to manually specify it in the migration itself.

Let's actually write the migration. Follow the inline comments:

```ruby
# db/migrate/20141115282317_add_created_at_index_to_newsletters.partitions.rb

# We must subclass from CanvasPartman::Migration
# instead of ActiveRecord::Migration
class AddCreatedAtIndexToNewsletters < CanvasPartman::Migration
  self.master_table = :newsletters

  # If the base class can not be infered from the master table name
  # because, for example, it is namespaced, you may explicitly specify
  # it here:
  # self.base_class = MyApp::Newsletter

  def up
    # #with_each_partition() is a helper available to the migration
    # that allows you iterate over all existing partition tables.
    #
    # The passed block receives the name of the partition table as
    # the only parameter:
    with_each_partition do |partition|
      add_index partition, :created_at
    end
  end

  def down
    with_each_partition do |partition|
      remove_index partition, :created_at
    end
  end
end
```

Alternatively, you can define a reversible `change` runner using a `change_table` block which will be yielded with a table for every partition as you would expect:

```ruby
class AddCreatedAtIndexToNewsletters < CanvasPartman::Migration
  self.master_table = :newsletters

  def change
    with_each_partition do |partition|
      change_table(partition) do |t|
        t.index :created_at
      end
    end
  end
end
```

A few notes:

- Partition migration files *must* be "scoped" for `canvas-partman` to identify them and pick them up when creating new partitions. A scope is an identifier that comes after the name of the migration file and right before the `rb` extension, prefixed by a dot. In the example above, the scope is `partitions`. You can customize this by overriding `CanvasPartman.migrations_scope = 'my_scope'` but **DO NOT LEAVE IT EMPTY.**

#### Cascading changes

Adding, modifying, or removing columns do not need to be applied to each partition; instead we can rely on PG inheritance to take care of cascading those changes down to all partitions (and future ones.)

Because of this, we don't have to use `CanvasPartman::Migration` migrations at all; just use the regular ActiveRecord ones. Let's add a new column called `publisher` of type `string` to our newsletters table:

```shell
rails g migration AddPublisherToNewsletters
# create  db/migrate/20141115282318_add_publisher_to_newsletters.rb
```

And the migration:

```ruby
# db/migrate/20141115282318_add_publisher_to_newsletters.rb

class AddPublisherToNewsletters < ActiveRecord::Migration
  def change
    change_table('newsletters') do |t|
      t.string :name
    end

    # Done! No need to worry about handling each partition,
    # pg inheritance will add this column to the master
    # table as well as the existing partition tables.
  end
end
```

# TODO

- We need to configure postgres's constraint_exclusion to be `partition` - see: http://www.postgresql.org/docs/9.1/static/runtime-config-query.html#GUC-CONSTRAINT-EXCLUSION [**Update**: this is not necessary as it is the default setting]
- Need to come up with a way to use regular, multiple/successive migrations for partition schemas instead of a single "snapshot" of how the latest version of the schema looks like [**Done** as of 11/15/2014]