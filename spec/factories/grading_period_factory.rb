#
# Copyright (C) 2015 Instructure, Inc.
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

# this factory creates an Account with the multiple_grading_periods feature flag enabled.
# it also creates two grading periods for the account
# the grading_periods both have a weight of 1
def grading_periods(options = {})
  Account.default.set_feature_flag! :multiple_grading_periods, 'on'
  context = options[:context] || @course || course
  count = options[:count] || 2

  grading_period_group = context.grading_period_groups.create!
  now = Time.zone.now
  count.times.map do |n|
    grading_period_group.grading_periods.create!(
      title:      "Period #{n}",
      start_date: (n).months.since(now),
      end_date:   (n+1).months.since(now),
      weight:     1
    )
  end
end
