# Dynamic Settings

This is how we load information from Consul for config at runtime.
The core idea is that config information is stored in consul
as trees.  This gem has some opinions about where fallback/override keys
will exist for a given config value (region, environment, global) and when you
ask for a given key it will search all the places that key might live all the way
up to global, return what it finds, and will cache the results for a time in
whatever caching implementation you provide to it.

Settings are stored under prefixes in a tree-like structure,
and DynamicSettings::find(prefix) lets you query a particular keyspace subtree.
Keyspace names used below, such as "Shared Local Configuration".

In local dev, you can use a YAML file as the data source rather than running a Consul server.  Start with a cp config/dynamic_settings.yml{.example,} and edit the file from there.

## Usage

Fetch the lti-signing-secret config value from the root of the Shared Local Configuration keyspace:

`DynamicSettings.find()["lti-signing-secret"]`

Fetch the recaptcha_server_key config value from the root of the Private Local Configuration keyspace:

`DynamicSettings.find(tree: :private)['recaptcha_server_key']`

Create an object to query the live-events configuration keyspace with a long cache TTL and use it to fetch some keys:

```ruby
le_settings = Canvas::DynamicSettings.find('live-events', default_ttl: 2.hours)
le_settings['stream_name']
le_settings['acl_token']
```

Fetch the disable_needs_grading_queries config value, looking first in a keyspace for the activated shard's cluster and, failing that, falling back to local and global keyspaces:

`DynamicSettings.find(cluster: Shard.current.database_server.id)["disable_needs_grading_queries"]`

## Fallback Rules

An initializer configures the Canvas::DynamicSettings with an environment, e.g. DynamicSettings.config = { 'environment' => 'production' }, which influences the fallback paths followed for any query.  The easiest way to describe the behavior is probably through a set of examples, so here we go.

Query: Canvas::DynamicSettings.find()['key']
Search paths:

```bash
config/canvas/production/key
config/canvas/key
global/config/canvas/production/key
global/config/canvas/key
```

Query: DynamicSettings.find(cluster: 'cluster21')['key']
Search paths:

```bash
config/canvas/production/cluster21/key
config/canvas/production/key
config/canvas/key
global/config/canvas/production/key
global/config/canvas/key
```

Query: DynamicSettings.find(tree: :private, cluster: 'cluster21')['key']
Search paths:

```bash
private/canvas/production/cluster21/key
private/canvas/production/key
private/canvas/key
global/private/canvas/production/key
global/private/canvas/key
```