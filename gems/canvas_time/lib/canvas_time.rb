require 'active_support/all'

module CanvasTime
  module ClassMethods
    def _load args
      return super unless args.starts_with?("pre1900:")
      # 8 puts us after the colon in "pre1900:"
      iso8601(args[8..-1])
    end
  end

  # set to 11:59pm if it's 12:00am
  def self.fancy_midnight(time)
    return time if time.nil? || time.hour != 0 || time.min != 0
    time.end_of_day
  end

  def self.is_fancy_midnight?(time)
    return false unless time
    time.hour == 23 && time.min == 59
  end

  def self.try_parse(maybe_time, default=nil)
    begin
      Time.zone.parse(maybe_time) || default
    rescue
      default
    end
  end

  def utc_datetime
    timestamp = self.getutc
    DateTime.civil(timestamp.year,
                   timestamp.month,
                   timestamp.day,
                   timestamp.hour,
                   timestamp.min)
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
  def _dump(_level)
    return super if year >= 1900
    "pre1900:#{iso8601}"
  end
end

Time.prepend(CanvasTime)
Time.singleton_class.prepend(CanvasTime::ClassMethods)
