#
# Copyright (C) 2017 Instructure, Inc.
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

class LatePolicy < ActiveRecord::Base
  belongs_to :course, inverse_of: :late_policy

  validates :course_id,
    presence: true
  validates :late_submission_minimum_percent, :missing_submission_deduction, :late_submission_deduction,
    presence: true,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :late_submission_interval,
    presence: true,
    inclusion: {
      in: %w/day hour/,
      message: "'%{value}' is not a valid interval"
    }
end
