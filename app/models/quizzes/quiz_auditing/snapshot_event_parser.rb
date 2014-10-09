module Quizzes::QuizAuditing
  # @class SnapshotEventParser
  #
  # Scrapes a bunch of QuizSubmissionSnapshot objects for event data and
  # produces "descriptors" for these events which can be used as initial data
  # for an auditing event model.
  class SnapshotEventParser
    # @param [Hash] options
    #
    # @param [Boolean] options[:optimize]
    #  Optimize events and discard ones that become empty after optimizing.
    #
    #  See Quizzes::QuizSubmissionEvent#optimize_answers
    #  See Quizzes::QuizSubmissionEvent#empty?
    #
    #  True by default.
    def initialize(options={})
      @options = {
        optimize: options.fetch(:optimize, true)
      }
    end

    # Main API. Parse events from all snapshots found for quiz submissions
    # for a bunch o' quizzes.
    #
    # @see #events_from_snapshots() for a lower-level API if you already have
    # the snapshots loaded
    #
    # @param [String[]] quiz_ids
    # @return [QuizSubmissionEvent[]] event_descriptors
    def events_from_quizzes(quiz_ids)
      quiz_submission_ids = ::Quizzes::QuizSubmission.
        where(quiz_id: Array(quiz_ids)).
        pluck(:id).
        map(&:to_s)

      snapshots = ::Quizzes::QuizSubmissionSnapshot.
        where({ quiz_submission_id: quiz_submission_ids }).
        includes(:quiz_submission)

      events_from_snapshots(snapshots)
    end

    # Parse events from a bunch of snapshots.
    #
    # @param [Quizzes::QuizSubmissionSnapshot] snapshots
    # @return [Quizzes::QuizSubmissionEvent[]] events
    def events_from_snapshots(snapshots)
      events = snapshots.map do |snapshot|
        event = Quizzes::QuizSubmissionEvent.build_from_submission_data(
          snapshot.data,
          snapshot.quiz_submission.quiz_data
        )
        event.quiz_submission = snapshot.quiz_submission
        event.created_at = snapshot.created_at
        event
      end

      if @options[:optimize]
        answered_event_type = Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED

        # an optimizer pass:
        pass = -> {
          quiz_submission_events = events.group_by(&:quiz_submission_id)
          quiz_submission_events.each do |_id, set|
            set.sort_by!(&:created_at)
            set.each_with_index do |event, index|
              event.optimize_answers(set[index-1]) if index > 0
            end
          end
        }

        pass.call()

        # perform as many passes as needed to get rid of any redundancy in the
        # event stream:
        while events.any?(&:empty?)
          events.reject!(&:empty?)
          pass.call()
        end
      end

      events.sort_by { |e| [ e.quiz_submission_id, e.created_at ] }
    end
  end
end