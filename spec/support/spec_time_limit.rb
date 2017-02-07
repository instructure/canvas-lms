module SpecTimeLimit
  class Error < StandardError
    def self.message_for(type, timeout)
      case type
      when :target
        "Exceeded the #{timeout} sec target threshold for new/modified specs"
      when :absolute
        "Exceeded the #{timeout} sec absolute threshold for existing specs"
      else
        "Exceeded the #{timeout} sec historical threshold for this particular spec"
      end
    end
  end

  class << self
    def enforce(example)
      type, timeout = timeout_for(example)
      Timeout.timeout(timeout) do
        example.run
      end
    rescue Timeout::Error
      bt = $ERROR_INFO.backtrace
      bt.shift while bt.first =~ /\/(gems|test_setup)\//
      raise Error, Error.message_for(type, timeout), bt
    end

    # find an appropriate timeout for this spec
    def timeout_for(example)
      if (timeout = typical_time_for(example))
        [:status_quo, [timeout, ABSOLUTE_TIMEOUT].min]
      elsif commit_modifies_spec?(example)
        [:target, TARGET_TIMEOUT]
      else
        # in jenkins land, everything should fall into one of the two
        # above, but for local testing or if for some reason we don't have
        # stats, let's still enforce a reasonable timeout
        [:absolute, ABSOLUTE_TIMEOUT]
      end
    end

    ABSOLUTE_TIMEOUT = ENV.fetch("SPEC_TIME_LIMIT_ABSOLUTE", 60).to_i
    TARGET_TIMEOUT = ENV.fetch("SPEC_TIME_LIMIT_TARGET", 15).to_i

    def typical_time_for(example)
      return unless defined?(TestQueue::Runner::RSpec::GroupQueue)
      stat_key = TestQueue::Runner::RSpec::GroupQueue.stat_key_for(example.example)
      return unless stats[stat_key]

      # since actual time can depend on external factors (hardware, load,
      # photons, etc.), apply a generous fudge factor ... you should only
      # ever hit the threshold when you introduce something :bananas:, e.g.
      # `sleep 10`, or `100.times { course_with_student }`
      #
      # furthermore, these are exempt from rerun thresholds so your build
      # will likely still pass if it was a total fluke.
      ((stats[stat_key] * 2) + 5).ceil
    end

    def stats
      @stats ||= if File.exist?(".test_queue_stats")
                   Marshal.load(IO.binread(".test_queue_stats")) || {}
                 else
                   {}
                 end
    end

    # note: we only see if the file itself was modified, this won't catch
    # changes to things it depends on. but that's where the status_quo stuff
    # helps us out
    def commit_modifies_spec?(example)
      commit_files.include?(example.metadata[:file_path].sub(/\A\.\//, ''))
    end

    def commit_files
      # env var since in test-queue land workers won't have a .git dir
      @commit_files ||= ENV.fetch(
        "RELEVANT_SPECS",
        `git diff-tree --no-commit-id --name-only -r HEAD | grep -E '_spec\.rb$'`
      ).split("\n")
    end
  end
end
