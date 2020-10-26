# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DataFixup::ReassociateGradingPeriodGroups
  def self.run
    # associates root account grading period groups with enrollment terms
    GradingPeriodGroup.active.where.not(account_id: nil).find_in_batches do |groups|
      account_subquery = Account.where(id: groups.map(&:account_id), root_account_id: nil)
      term_ids = EnrollmentTerm.active.where(root_account_id: account_subquery).pluck(:id)
      groups.each do |group|
        EnrollmentTerm.
          where(id: term_ids, root_account_id: group.account_id).
          update_all(grading_period_group_id: group.id)
      end
    end
  end
end
