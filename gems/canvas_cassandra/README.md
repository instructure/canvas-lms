# Canvas Cassandra

A fairly small library for opinionated conversation with the [Cassandra database](https://cassandra.apache.org/).

## Purpose

Canvas has stored many things in cassandra over the years.  PageViews, Auditors, GlobalLookups, etc.
For high write-throughput workloads, it's an appealing choice.  It's operational burden was surprisingly high
though, and most workloads have been migrated off at this point to dynamodb or postgres.

This library is maintained because some OSS canvas users still use cassandra to back one of those workflows,
and because in some cases our deprecation window has not fully passed (Auditors may be fully deprecated
off of Cassandra by January of 2022, for example).

Really, this gem is a wrapper around "cassandra-cql", providing an interface
for switching between consistency levels easily, and some timing logging
so that we can see how long CQL queries are taking in the canvas logs.  It
also provides a "Batch" class for taking many queries and packaging them
into a single cassandra request.

## Config

To use this in a rails app, you need to provide the library with a settings_store:

```ruby
require 'canvas_cassandra'

CanvasCassandra.settings_store = YourSettingClass # probably Setting in canvas
```

It's expected this class or object will respond to "get" with a key
for a settings name and a default value if that setting doesn't exist,
specifically because this is how you can change the read_consistency for the library
(see "event_stream.read_consistency" in canvas_cassandra/database_builder.rb).

The reason this isn't just specified as a value at config time is so that the caching
and reloading of the setting at runtime can be managed by the settings store class.

Perhaps at some point the canvas Setting class will be extracted as it's own engine
so it could be dependend on directly, in which case this would go away.

## Usage

Create a database instance to talk to a given keyspace:

```ruby
fingerprint = "some_useful_string_for_logs"
servers = ['127.0.0.1:9160','127.0.0.2:9160']
opts = {:keyspace => 'my_keyspace', :cql_version => '3.0.0'}
logger = Rails.logger
db = CanvasCassandra::Database.new(fingerprint, servers, opts, logger)
```

Write things with bind variables:

```ruby
insert_cql = "INSERT INTO table_name (key_column, id_column, ttl) VALUES (?, ?, ?) USING TTL ?"
key = "the_relevant_key_for_this_record"
db.update(insert_cql, key, ordered_id, record.id, ttl_seconds)
```

Fetch things with CQL and map over rows:

```ruby
names_array = db.execute("SELECT attr_name FROM table_name WHERE id_column=?", id_val).map do |row|
  row['attr_name']
end
```
