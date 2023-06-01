# frozen_string_literal: true

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
  class SubmissionForShow < AbstractSubmissionForShow
    attr_reader :id

    def initialize(assignment_id:, context:, id:, preview: false, version: nil)
      super(assignment_id:, context:, preview:, version:)
      @id = id
    end

    def user
      @user ||= context.all_students.find(id)
    end

    private

    def root_submission
      @root_submission ||= assignment.submissions
                                     .except(:preload)
                                     .preload(versioned? ? :versions : nil)
                                     .where(user_id: user)
                                     .first_or_initialize
    end
  end
end
