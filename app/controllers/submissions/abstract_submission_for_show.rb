#
# Copyright (C) 2018 - present Instructure, Inc.
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

module Submissions
  class AbstractSubmissionForShow
    attr_reader :context, :assignment_id, :preview, :version

    def initialize(context:, assignment_id:, preview: false, version: nil)
      @context = context
      @assignment_id = assignment_id
      @preview = preview
      @version = version
    end

    def assignment
      @assignment ||= context.assignments.active.find(assignment_id)
    end

    def submission
      @submission ||= versioned? ? versioned_submission : root_submission
    end

    protected

    def versioned?
      preview && version && !assignment.quiz
    end

    def versioned_submission
      root_submission.submission_history[version.to_i] || root_submission
    end
  end
end

