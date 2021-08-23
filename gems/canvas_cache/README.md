# CanvasCache

For all those things you don't want to go lookup again.

## Usage

There are a collection of caching helpers in this library for different
enhancements for the canvas system to help us scale effectively.

#### Redis Client Management

canvas_cache knows where the redis config info is
and whether how the local environment is setup.  You
can ask from anywhere:

```ruby
CanvasCache::Redis.enabled?
```

You can access the distrbitued redis client directly
off the module:

```ruby
CanvasCache::Redis.redis.set("key", "value")
```

If your config file has "servers: 'cache_store'", it will
just give you a vanilla Rails.cache.redis instance, but
if you give it a set of servers to work with in the config
it will construct a patched version of the redis client.

It works pretty much like a standard redis client, but
there are several enhancements that this library makes to the
way redis caching works.

 - uses the configurable HashRing described below for distributed configs
 - includes some safety checks to prevent you from accidentally dropping your
    production cache with a "flushdb"
 - performs logging with elapsed-time in the output
 - uses a circuit breaker to tamp down on redis traffic if it gets
    connectivity issues.



#### Consistent Hashing on redis with Digest Injection

when spreading cache keys over a ring of nodes, you don't
want the addition of a node to the ring to cause all keys
to get re-positioned (that would be expensive).  the redis-store
library handles this internally with it's HashRing implementation,
but it does not allow you to pass in your digest function of choice.

The HashRing implementation in this library provides a configurable
digest and some statistics funcitonality for checking on
the distribution of keys.  You can use it by making sure the
":ring" option passed to your Redis::Distributed initialization
is an instance of "CanvasCache::HashRing" if it isn't otherwise
specified:

```ruby
require 'redis/distributed'
module EnhancedDistributed
  def initialize(addresses, options = { })
    options[:ring] ||= CanvasCache::HashRing.new([], options[:replicas], options[:digest])
    super
  end
end

Redis::Distributed.prepend(EnhancedDistributed)
```

That way the "digest" option can be passed to any instantiation of
the Redis::Distributed module (like in rails application initialization if you
specify multiple redis urls).

## Running Tests

This gem is tested with rspec.  You can use `test.sh` to run it, or
do it yourself with `bundle exec rspec spec`.