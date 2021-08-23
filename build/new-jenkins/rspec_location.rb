# frozen_string_literal: true

class RSpecLocationFormatter
  RSpec::Core::Formatters.register self, :example_started

  def initialize(output)
    @output = output
  end

  def example_started(notification)
    @output << notification.example.location << "\n"
  end
end
