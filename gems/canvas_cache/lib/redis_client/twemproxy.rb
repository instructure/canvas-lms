# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
#

class RedisClient
  module Twemproxy
    UNSUPPORTED_METHODS = %w[
      migrate
      move
      object
      randomkey
      rename
      renamenx
      bitop
      msetnx
      blpop
      brpop
      brpoplpush
      psubscribe
      publish
      punsubscribe
      subscribe
      unsubscribe
      discard
      exec
      multi
      unwatch
      watch
      script
      echo
      ping
    ].freeze

    # There are some methods that are not supported by twemproxy, but which we
    # don't block, because they are viewed as maintenance-type commands that
    # wouldn't be run as part of normal code, but could be useful to run
    # one-off in script/console if you aren't using twemproxy, or in specs:
    ALLOWED_UNSUPPORTED = %w[
      keys
      quit
      flushall
      flushdb
      info
      bgrewriteaof
      bgsave
      client
      config
      dbsize
      debug
      lastsave
      monitor
      save
      shutdown
      slaveof
      slowlog
      sync
    ].freeze

    def call(command, _config)
      check_command(command.first.to_s)
      super
    end

    def call_pipelined(commands, _config)
      commands.each do |command|
        check_command(command.first.to_s)
      end
      super
    end

    def check_command(command)
      if UNSUPPORTED_METHODS.include?(command)
        raise CanvasCache::Redis::UnsupportedRedisMethod,
              "Redis method `#{command}` is not supported by Twemproxy, and so shouldn't be used in Canvas"
      end
      if ALLOWED_UNSUPPORTED.include?(command) && GuardRail.environment != :deploy
        raise CanvasCache::Redis::UnsupportedRedisMethod,
              "Redis method `#{command}` is potentially dangerous, and should only be called from console, and only if you fully understand the consequences. If you're sure, retry after running GuardRail.activate!(:deploy)"
      end
    end
  end
end
