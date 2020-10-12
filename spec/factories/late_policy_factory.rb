#
# Copyright (C) 2017 - present Instructure, Inc.
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

module Factories
  def late_policy_factory(**opts)
    params = late_policy_params(**opts)
    LatePolicy.create!(params)
  end

  def late_policy_model(**opts)
    params = late_policy_params(**opts)
    LatePolicy.new(params)
  end

  private

  def late_policy_params(course: nil, deduct: 0, every: :hour, down_to: 0, missing: 100)
    {
      course_id: course && course[:id],
      late_submission_deduction_enabled: deduct.positive?,
      late_submission_deduction: deduct,
      late_submission_interval: every,
      late_submission_minimum_percent_enabled: down_to.positive?,
      late_submission_minimum_percent: down_to,
      missing_submission_deduction_enabled: !!missing,
      missing_submission_deduction: missing
    }
  end
end
