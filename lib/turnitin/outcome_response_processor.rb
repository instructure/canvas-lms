

module Turnitin
  class OutcomeResponseProcessor
    class << self
      def process(tool, outcomes_response_json)


        # create new submission with the file
        # save originality data
        #

      end
      handle_asynchronously :process, max_attempts: 1, priority: Delayed::LOW_PRIORITY
    end
  end
end