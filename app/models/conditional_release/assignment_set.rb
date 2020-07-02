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
  class AssignmentSet < ActiveRecord::Base
    include Deletion

    belongs_to :scoring_range, required: true
    has_many :assignment_set_associations, -> { active.order(position: :asc) }, inverse_of: :assignment_set, dependent: :destroy
    accepts_nested_attributes_for :assignment_set_associations, allow_destroy: true
    acts_as_list :scope => {:scoring_range => self, :deleted_at => nil}
    has_one :rule, through: :scoring_range
    belongs_to :root_account, :class_name => "Account"

    attr_accessor :service_id # TODO: can remove after migration is complete

    before_create :set_root_account_id
    def set_root_account_id
      self.root_account_id ||= scoring_range.root_account_id
    end

    def self.collect_associations(sets)
      sets.map(&:assignment_set_associations).flatten.sort_by(&:id).uniq(&:assignment_id)
    end
  end
end
