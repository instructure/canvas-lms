require 'active_support/all'

module CanvasTime
  require "canvas_time/time"
end

# Ruby 1.9+ made the somewhat odd decision to shave off a few bits by
# marshalling Time objects with the year stored as (year - 1900), and raising
# an exception if year < 1900.
#
# We don't often deal with really old times like that, but exploding whenever
# we happen to try and store one into the cache is awful.
#
# So we extend the marshalling on Time to use a different format for dates
# before 1900. For convenience we just use the iso8601 representation of the
# Time. We retain the original format for post-1900 Times, so the slightly
# larger representation and slower pure-ruby parsing only happens in the edge case.
# We also don't bother storing sub-second data for these old Times.
#
# This applies to TimeWithZone as well, since that object just stores a (Time, Zone) tuple.
class Time
  def utc_datetime
    timestamp = self.getutc
    DateTime.civil(timestamp.year,
                   timestamp.month,
                   timestamp.day,
                   timestamp.hour,
                   timestamp.min)
  end

  def _dump_with_old_times level
    if self.year >= 1900
      _dump_without_old_times(level)
    else
      "pre1900:#{self.iso8601}"
    end
  end
  alias_method_chain :_dump, :old_times

  class << self
    def _load_with_old_times args
      if args.starts_with?("pre1900:")
        # 8 puts us after the colon in "pre1900:"
        self.iso8601(args[8..-1])
      else
        _load_without_old_times(args)
      end
    end
    alias_method_chain :_load, :old_times
  end
end
