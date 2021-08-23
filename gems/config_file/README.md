# Config File

In Canvas, This is how we load information from yaml files on disk at runtime.

## Usage

You use ConfigFile by passing in the name of the file
(no extension) to the "load" method.

```ruby
ConfigFile.load('saml')
```

This will return you a hash that has the parsed yaml from that file.
The module also knows about rails environments, and will try to pull
the subset of the hash that is specific to the current rails env, but
you can override it:

```ruby
ConfigFile.load('database', 'test')
```

There are some nicities to this like the loaded hash always has indifferent access
and if the file doesn't exist it doesn't error (you just get a null hash), and this
helps with a number of common accidental errors.

The main value is that this information is cacheable (once the file is loaded,
it's stored in memory according to it's filename).  loading the same config many places
will always result in the in-memory version being served.

There's also a more sophisticated caching mechanism if your config file
gets loaded specifically to build some sort of in memory structure
that you don't want to re-derive on each config load, like building
a client object:

```ruby
ConfigFile.cache_object('pv4') do |config|
  Pv4Client.new(config['uri'], config['access_token'])
end
```

In this kind of case, the parsed yaml is passed to the block
as "config", and the value returned from the block is shoved
into the object cache so that any other invocations of the
"cache_object" method with the same key will just return
the already built object.

Since all the config
info we might load from disk is stored in one structure, it
is simple to clear the cache to force a settings reload from disk.

```ruby
ConfigFile.reset_cache
```

And the next time any bit of code asks for a given config file, it will be reloaded from disk.

## Running Tests

This gem is tested with rspec.  You can use `test.sh` to run it, or
do it yourself with `bundle exec rspec spec`.