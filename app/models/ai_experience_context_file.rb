# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

class AiExperienceContextFile < ApplicationRecord
  belongs_to :ai_experience
  belongs_to :attachment
  belongs_to :root_account, class_name: "Account"

  acts_as_list scope: :ai_experience_id

  validates :ai_experience, presence: true
  validates :attachment, presence: true
  validates :attachment_id, uniqueness: { scope: :ai_experience_id }
  validate :attachment_file_size

  before_validation :set_root_account

  MAX_FILE_SIZE = 314_572_800 # 300 MB in bytes

  private

  def set_root_account
    self.root_account_id ||= ai_experience&.root_account_id
  end

  def attachment_file_size
    return unless attachment

    if attachment.size > MAX_FILE_SIZE
      errors.add(:attachment, I18n.t("file size must be less than 300 MB"))
    end
  end
end
