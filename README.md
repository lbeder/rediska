# Rediska

[![Gem Version](https://badge.fury.io/rb/rediska.png)](http://badge.fury.io/rb/rediska)
[![Build Status](https://travis-ci.org/lbeder/rediska.png)](https://travis-ci.org/lbeder/rediska)
[![Dependency Status](https://gemnasium.com/lbeder/rediska.png)](https://gemnasium.com/lbeder/rediska)
[![Coverage Status](https://coveralls.io/repos/lbeder/rediska/badge.png)](https://coveralls.io/r/lbeder/rediska)

This is a light-weight implementation of a redis simulator, which is useful for local development and testing or for minimal environments (where a real redis server might not be available or even desired, while every worker matters).

Currently, rediska is currently only compliant with redis 3 and supports the following database strategies:

* Memory (default): the data is being stored entirely in the memory and is not persistent nor shared between different processed.
* Filesystem: the data is being backed by the filesystem and even though slower than the in-memory implementation, it does provides persistency (to some extent, as the data is being stored in a temporary folder) and can be accessed across the different processes.

Additional integrations:
* Seamless integration with Sidekiq.

## Setup

If you are using bundler add rediska to your Gemfile:

``` ruby
gem 'rediska'
```

Then run:

```bash
$ bundle install
```

Otherwise install the gem:

```bash
$ gem install rediska
```

## Usage
The gem will automatically add its fake driver to Redis::Connection.drivers, so not extra configuration is required, other than conditionally bundling the gem (for example, in Rails' "test", "development", "continuos_integration" groups, per-your requirements.

## Configuration

### Database Strategy
Rediska supports the following database strategies:

* Memory (:memory): the data is being stored entirely in the memory and is not persistent nor shared between different processed.
* Filesystem (:filesystem): the data is being backed by the filesystem and even though slower than the in-memory implementation, it does provides persistency (to some extent, as the data is being stored in a temporary folder) and can be accessed across the different processes.

By default, rediska uses the in-memory strategy.

To override this behavior you can config the ```database``` option like so:

```ruby
Rediska.configure do |config|
  config.database = :filesystem
end
```

### Adding Namespace

If you choose to use the filesystem backed database, you can append an additional namespace in order to prevent conflicts like so:

```ruby
Rediska.configure do |config|
  config.namespace = 'test'
end
```

### Supported Redis Commands

* APPEND
* AUTH
* BITCOUNT
* BGSAVE
* BGREWRITEAOF
* BLPOP
* BRPOP
* BRPOPLPUSH
* DBSIZE
* DECR
* DECRBY
* DEL
* DISCARD
* DUMP
* ECHO
* EXEC
* EXISTS
* EXPIRE
* EXPIREAT
* FLUSHALL
* FLUSHDB
* GET
* GETBIT
* GETRANGE
* GETSET
* HDEL
* HEXISTS
* HGET
* HGETALL
* HINCRBY
* HINCRBYFLOAT
* HKEYS
* HLEN
* HMGET
* HMSET
* HSET
* HSETNX
* HVALS
* INCR
* INCRBY
* INCRBYFLOAT
* INFO
* KEYS
* LASTSAVE
* LINDEX
* LINSERT
* LLEN
* LPOP
* LRANGE
* LREM
* LSET
* LTRIM
* MGET
* MOVE
* MONITOR
* MSET
* MSETNX
* MULTI
* PERSIST
* PEXPIRE
* PING
* PTTL
* RANDOMKEY
* REDIS
* RENAME
* RENAMENX
* RESTORE
* RPOP
* RPOPLPUSH
* RPUSH
* RPUSHX
* SADD
* SAVE
* SCAN
* SCARD
* SDIFF
* SDIFFSTORE
* SELECT
* SET
* SETEX
* SETBIT
* SETNX
* SETRANGE
* SINTER
* SINTERSTORE
* SISMEMBER
* SMEMBERS
* SMOVE
* SORT
* SPOP
* SRANDMEMBER
* SREM
* SSCAN
* STRLEN
* SUNION
* SUNIONSTORE
* TIME
* TTL
* TYPE
* UNWATCH
* WATCH
* ZADD
* ZCARD
* ZCOUNT
* ZINCRBY
* ZINTERSTORE
* ZUNIONSTORE
* ZRANK
* ZRANGE
* ZRANGEBYSCORE
* ZREM
* ZREMRANGEBYRANK
* ZREVRANGE
* ZREVRANGEBYSCORE
* ZREVRANK
* ZSCAN
* ZSCORE

## Credits and Contributors

This gem was inspired by (and originally forked from) the [fakeredis](https://github.com/guilleiguaran/fakeredis) gem.

## License

The MIT License (MIT)

Copyright (c) 2013

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

<div align="center">
  <img alt='rediska' src="http://farm6.staticflickr.com/5189/5640624758_b6717935bf.jpg" />
</div>
