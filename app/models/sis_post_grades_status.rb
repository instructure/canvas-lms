#
# Copyright (C) 2014 Instructure, Inc.
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

class SisPostGradesStatus < ActiveRecord::Base
  ALLOWED_STATUSES = %w{success warning failed}
  belongs_to :course
  belongs_to :course_section
  belongs_to :user

  validates :course, presence: true
  validates :grades_posted_at, presence: true
  validates :message, presence: true
  validates :status, presence: true, inclusion: {in: ALLOWED_STATUSES}
end
