# CanvasCache

For all those things you don't want to go lookup again.

## Usage

There are a collection of caching helpers in this library for different
enhancements for the canvas system to help us scale effectively.

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