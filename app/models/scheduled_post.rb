# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class ScheduledPost < ActiveRecord::Base
  belongs_to :assignment, inverse_of: :scheduled_post, class_name: "AbstractAssignment"
  belongs_to :post_policy, inverse_of: :scheduled_post

  validates :assignment, presence: true, uniqueness: true
  validates :post_policy, presence: true, uniqueness: true
  validates :root_account_id, presence: true
  validates :post_comments_at, presence: true
  validates :post_grades_at, presence: true
end
