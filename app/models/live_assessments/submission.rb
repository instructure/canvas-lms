#
# Copyright (C) 2014 Instructure, Inc.
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

module LiveAssessments
  class Submission < ActiveRecord::Base
    attr_accessible :user, :assessment, :possible, :score, :assessed_at

    belongs_to :user
    belongs_to :assessment, class_name: 'LiveAssessments::Assessment'

    validates_presence_of :user, :assessment

    def create_outcome_result(alignment)
      # we don't delete results right now
      # when we do, we'll need to start cleaning up outcome results when all the results are deleted. bail until then.
      return if possible == 0

      outcome_result = alignment.learning_outcome_results.where(user_id: user.id).first_or_initialize
      outcome_result.title = "#{user.name}, #{assessment.title}"
      outcome_result.context = assessment.context
      outcome_result.associated_asset = assessment
      outcome_result.artifact = self
      outcome_result.assessed_at = assessed_at
      outcome_result.submitted_at = assessed_at

      outcome_result.score = score
      outcome_result.possible = possible
      outcome_result.percent = score.to_f / possible.to_f

      if alignment.mastery_score
        outcome_result.mastery = outcome_result.percent >= alignment.mastery_score
      else
        outcome_result.mastery = nil
      end

      # map actual magic marker result to outcome rubric criterion if we have one
      # this is a hack. the rollups and gradebooks should handle explicit mastery
      # this only works because we set mastery_score based on the rubric in the first place
      criterion = alignment.learning_outcome.data && alignment.learning_outcome.data[:rubric_criterion]
      if criterion
        outcome_result.possible = criterion[:points_possible]
        outcome_result.score = outcome_result.percent * outcome_result.possible
      end

      outcome_result.save!
    end
  end
end
