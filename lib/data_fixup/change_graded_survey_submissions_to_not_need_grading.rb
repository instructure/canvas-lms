#
# Copyright (C) 2013 - present Instructure, Inc.
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

module DataFixup
  class ChangeGradedSurveySubmissionsToNotNeedGrading

    def self.run
      Quizzes::Quiz.where("quizzes.quiz_type NOT IN ('practice_quiz', 'assignment')").active.find_in_batches(batch_size: 200) do |group|
        subs = Quizzes::QuizSubmission.where(quiz_id: group, workflow_state: 'pending_review')
        subs.each do |qsub|
          qsub.update_attribute(:workflow_state, 'complete')
        end
        Submission.where(quiz_submission_id: subs, workflow_state: 'pending_review').each do |sub|
          sub.update_attribute(:workflow_state, 'graded')
        end
      end
    end
  end
end
