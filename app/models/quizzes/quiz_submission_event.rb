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
#

class Quizzes::QuizSubmissionEvent < ActiveRecord::Base
  extend RootAccountResolver
  include CanvasPartman::Concerns::Partitioned

  # An event describing the student choosing an answer to a question.
  EVT_QUESTION_ANSWERED = "question_answered"
  EVT_QUESTION_FLAGGED = "question_flagged"
  # An event for every new submission created
  EVT_SUBMISSION_CREATED = "submission_created"

  belongs_to :quiz_submission, class_name: "Quizzes::QuizSubmission"
  resolves_root_account through: :quiz_submission

  serialize :event_data, coder: JSON

  # for a more meaningful API when dealing with EVT_QUESTION_ANSWERED events:
  alias_attribute :answers, :event_data

  after_initialize do
    # We ALWAYS want this to be set, otherwise the event won't be stored in the
    # right partition.
    self.created_at ||= Time.now
  end

  # After optimizing an event, it could become "empty" as in it does not
  # represent any action that its predecessor isn't already.
  #
  # If this returns true, you can safely skip storing this event.
  def empty?
    case event_type
    when EVT_QUESTION_ANSWERED
      answers.blank?
    else
      false
    end
  end
end
