#
# Copyright (C) 2015 - present Instructure, Inc.
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
  class SubmissionForShow
    def initialize(context, options={})
      @context = context
      @options = options
    end
    attr_reader :options

    def assignment
      @_assignment ||= @context.assignments.active.find(options[:assignment_id])
    end

    def submission
      @_submission ||= versioned? ? versioned_submission : root_submission
    end

    def user
      @_user ||= @context.all_students.find(options[:id])
    end

    private
    def versioned?
      options[:preview] && options[:version] && !assignment.quiz
    end

    def root_submission
      @_root_submission ||= assignment.submissions.
        preload(:versions).where(user_id: user).first_or_initialize
    end

    def versioned_submission
      root_submission.submission_history[options[:version].to_i] || root_submission
    end
  end
end
