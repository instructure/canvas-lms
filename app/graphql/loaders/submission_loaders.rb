# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module Loaders
  module SubmissionLoaders
    class ProvisionalGradesLoader < GraphQL::Batch::Loader
      def initialize(scorer)
        super()
        @scorer = scorer
      end

      def perform(submission_ids)
        grades_by_submission_id = ModeratedGrading::ProvisionalGrade
                                  .where(submission_id: submission_ids)
                                  .scored_by(@scorer).group_by(&:submission_id)

        submission_ids.each do |id|
          fulfill(id, grades_by_submission_id.fetch(id, []))
        end
      end
    end

    class HasProvisionalGradeByCurrentUserLoader < GraphQL::Batch::Loader
      def initialize(current_user_id)
        super()
        @current_user_id = current_user_id
      end

      def perform(submission_ids)
        return if submission_ids.empty? || @current_user_id.nil?

        provisional_grades = ModeratedGrading::ProvisionalGrade
                             .where(submission_id: submission_ids, scorer_id: @current_user_id)
                             .where.not(score: nil)
                             .distinct
                             .pluck(:submission_id)
                             .to_set

        submission_ids.each do |submission_id|
          fulfill(submission_id, provisional_grades.include?(submission_id))
        end
      end
    end

    class HasUnreadRubricAssessmentLoader < GraphQL::Batch::Loader
      def perform(submission_ids)
        return if submission_ids.empty?

        # Get submission IDs that have at least one unread rubric assessment
        # Using SELECT DISTINCT is much faster than loading all content_participations
        submissions_with_unread = ContentParticipation
                                  .where(content_id: submission_ids, content_type: "Submission")
                                  .where(workflow_state: "unread", content_item: "rubric")
                                  .distinct
                                  .pluck(:content_id)
                                  .to_set

        submission_ids.each do |id|
          fulfill(id, submissions_with_unread.include?(id))
        end
      end
    end
  end
end
