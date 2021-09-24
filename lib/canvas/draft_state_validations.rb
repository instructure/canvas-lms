# frozen_string_literal: true

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

module Canvas
  module DraftStateValidations
    def self.included(base)
      base.class_eval do
        validate :validate_draft_state_change, :if => :workflow_state_changed?
      end
    end

    def validate_draft_state_change
      old_draft_state, new_draft_state = self.changes['workflow_state']
      return if old_draft_state == new_draft_state
      if new_draft_state == 'unpublished' && has_student_submissions?
        self.errors.add :workflow_state, I18n.t('#quizzes.cant_unpublish_when_students_submit',
                                                "Can't unpublish if there are student submissions")
      end
    end
  end
end
