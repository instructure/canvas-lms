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
  class AnonymousSubmissionForShow < AbstractSubmissionForShow
    attr_reader :anonymous_id

    def initialize(anonymous_id:, assignment_id:, context:, preview: false, version: nil)
      super(assignment_id: assignment_id, context: context, preview: preview, version: version)
      @anonymous_id = anonymous_id
    end

    def user
      @user ||= root_submission.user
    end

    private

    def root_submission
      @root_submission ||= assignment.submissions.
        except(:preload).
        active.
        preload(versioned? ? :versions : nil).
        find_or_initialize_by(anonymous_id: anonymous_id)
    end
  end
end
