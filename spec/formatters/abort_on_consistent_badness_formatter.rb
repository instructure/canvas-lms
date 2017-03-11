require "rspec/core/formatters/base_formatter"

class AbortOnConsistentBadnessFormatter < ::RSpec::Core::Formatters::BaseFormatter
  ::RSpec::Core::Formatters.register self, :example_finished

  # Number of identical failures in a row before we abort this worker
  RECENT_SPEC_FAILURE_LIMIT = 10

  def example_finished(notification)
    example = notification.example
    return unless example.exception

    recent_spec_errors << example.exception.to_s
    recent_errors = recent_spec_errors.last(RECENT_SPEC_FAILURE_LIMIT)
    if recent_errors.size >= RECENT_SPEC_FAILURE_LIMIT && recent_errors.uniq.size == 1
      $stderr.puts "ERROR: got the same failure #{RECENT_SPEC_FAILURE_LIMIT} times in a row, aborting"
      ::RSpec.world.wants_to_quit = true
    end
  end

  def recent_spec_errors
    @recent_spec_errors ||= []
  end
end
