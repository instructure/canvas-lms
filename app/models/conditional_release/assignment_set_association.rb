#
# Copyright (C) 2020 - present Instructure, Inc.
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

module ConditionalRelease
  class AssignmentSetAssociation < ActiveRecord::Base
    include Deletion

    validates :assignment_id, presence: true
    validates :assignment_id, uniqueness: { scope: :assignment_set_id, conditions: -> { active } }
    validate :not_trigger

    acts_as_list :scope => {:assignment_set => self, :deleted_at => nil}

    belongs_to :assignment_set, required: true
    belongs_to :assignment
    has_one :scoring_range, through: :assignment_set
    has_one :rule, through: :assignment_set

    delegate :course_id, to: :rule, allow_nil: true

    private
    def not_trigger
      if rule && assignment_id == rule.trigger_assignment_id
        errors.add(:assignment_id, "can't match rule trigger_assignment_id")
      end
    end
  end
end
