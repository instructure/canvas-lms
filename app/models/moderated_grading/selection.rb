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

class ModeratedGrading::Selection < ActiveRecord::Base
  belongs_to :provisional_grade,
    foreign_key: :selected_provisional_grade_id,
    class_name: 'ModeratedGrading::ProvisionalGrade'
  belongs_to :assignment
  belongs_to :student, class_name: 'User'

  validates :student_id, uniqueness: { scope: :assignment_id }

  def create_moderation_event(user)
    AnonymousOrModerationEvent.create!(
      assignment_id: assignment_id,
      user: user,
      submission_id: provisional_grade&.submission_id,
      event_type: :provisional_grade_selected,
      payload: { id: selected_provisional_grade_id, student_id: student_id }
    )
  end
end
