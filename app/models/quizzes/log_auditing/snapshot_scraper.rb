# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Quizzes::LogAuditing
  # @class SnapshotEventParser
  #
  # Scrapes a bunch of QuizSubmissionSnapshot objects for event data and
  # produces "descriptors" for these events which can be used as initial data
  # for an auditing event model.
  #
  # @note
  # This is a utility class and is not used in runtime code, only in support
  # tasks/scripts, and it is built with that assumption.
  class SnapshotScraper
    # Parse events from all snapshots found for quiz submissions for a bunch of
    # quizzes.
    #
    # @see #events_from_snapshots() for a lower-level API if you already have
    # the snapshots loaded
    #
    # @param [Array<String>] quiz_ids
    # @return [Array<QuizSubmissionEvent>] events
    def events_from_quizzes(quiz_ids)
      quiz_submission_ids = ::Quizzes::QuizSubmission
                            .where(quiz_id: Array(quiz_ids))
                            .pluck(:id)
                            .map(&:to_s)

      snapshots = ::Quizzes::QuizSubmissionSnapshot
                  .where({ quiz_submission_id: quiz_submission_ids })
                  .preload(:quiz_submission)

      events_from_snapshots(snapshots)
    end

    # Parse events from a bunch of snapshots for a specific quiz submission.
    #
    # @param [Array<Quizzes::QuizSubmissionSnapshot>] snapshots
    # @return [Array<Quizzes::QuizSubmissionEvent>]
    #   The set of events that were extracted. Note that those events are *not*
    #   persisted.
    def events_from_snapshots(snapshots)
      extractor = Quizzes::LogAuditing::QuestionAnsweredEventExtractor.new

      events = snapshots.map do |snapshot|
        event = extractor.build_event(snapshot.data, snapshot.quiz_submission)
        event.quiz_submission = snapshot.quiz_submission
        event.created_at = snapshot.created_at
        event
      end

      optimize(events).sort_by { |e| [e.quiz_submission_id, e.created_at] }
    end

    private

    def optimize(events)
      optimizer = Quizzes::LogAuditing::QuestionAnsweredEventOptimizer.new

      quiz_submission_events = events.group_by(&:quiz_submission_id)
      quiz_submission_events.each_value do |set|
        set.sort_by!(&:created_at)
        set.each_with_index do |event, index|
          if index > 0
            optimizer.run(event, set.slice(0, index - 1))
          end
        end
      end

      events.reject(&:empty?)
    end
  end
end
