# frozen_string_literal: true

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
  class AssignmentSetAction < ActiveRecord::Base
    include Deletion

    validates :action, inclusion: { in: %w[assign unassign] }
    validates :source, inclusion: { in: %w[grade_change select_assignment_set] }
    validates :student_id, presence: true
    validates :actor_id, presence: true
    validates :assignment_set_id, presence: true
    belongs_to :assignment_set
    belongs_to :root_account, class_name: "Account"

    before_create :set_root_account_id
    def set_root_account_id
      self.root_account_id ||= assignment_set.root_account_id
    end

    scope :latest, lambda {
      select("DISTINCT ON (assignment_set_id, student_id) id")
        .order("assignment_set_id, student_id, updated_at DESC")
    }

    def self.current_assignments(student_id_or_ids, sets = nil)
      conditions = { student_id: student_id_or_ids }
      conditions[:assignment_set] = sets if sets
      where(id: latest.where(conditions), action: "assign")
    end

    def self.create_from_sets(assigned, unassigned, opts = {})
      opts[:actor_id] ||= opts[:student_id]

      [["assign", assigned], ["unassign", unassigned]].each do |action, sets|
        Array.wrap(sets).each do |set|
          set_action_data = opts.merge(action:, assignment_set: set, root_account_id: set.root_account_id)
          (set_action = find_by(set_action_data)) ? set_action.touch : create!(set_action_data)
        end
      end
    end
  end
end
