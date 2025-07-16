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
#

class SubmissionText < ActiveRecord::Base
  belongs_to :submission, optional: false
  belongs_to :attachment, optional: false
  belongs_to :root_account, class_name: "Account", optional: false

  validates :text, presence: true, length: { maximum: maximum_long_text_length }
  validates :attempt, presence: true, numericality: { greater_than: 0 }
  validates :contains_images, inclusion: { in: [true, false] }
  validates :submission_id, uniqueness: { scope: [:attachment_id, :attempt] }
end
