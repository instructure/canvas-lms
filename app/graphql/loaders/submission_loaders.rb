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
      def self.for(scorer)
        key = scorer.id
        @loaders ||= {}
        @loaders[key] ||= new(scorer)
      end

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
  end
end
