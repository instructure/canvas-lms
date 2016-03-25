# The purpose of this file is to ease debugging and figuring out
# just what is going on. It defines a global function which will
# write out information to a *separate* log file which I can inspect
# more easily than the main log (which is sometimes useful so I don't
# want to turn it off, but is also too hard to use for easy things)

class BZDebug

  @@bz_dont_attempt_logging = false
  @@bz_debug_file = nil

  def self.setup
    return if @@bz_dont_attempt_logging
    begin
      @@bz_debug_file = File.new("bz-debug.log", "a")
    rescue
      # if any attempt at logging fails, just give up entirely so it
      # doesn't spam error reports about that too
      @@bz_dont_attempt_logging = true
    end
  end
  def self.log(what)
    BZDebug.setup if @@bz_debug_file.nil?
    return if @@bz_dont_attempt_logging
    begin
      @@bz_debug_file.puts(what.inspect)
      @@bz_debug_file.flush
    rescue
      @@bz_dont_attempt_logging = true
    end
  end
end
