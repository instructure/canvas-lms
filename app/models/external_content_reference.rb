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
#

class ExternalContentReference < ApplicationRecord
  belongs_to :root_account, class_name: "Account"
  belongs_to :context, polymorphic: [:wiki_page], separate_columns: true, optional: false

  before_validation :set_root_account_id, on: :create

  validates :content_id, presence: true
  validates :root_account, presence: true

  private

  def set_root_account_id
    self.root_account_id ||= context&.root_account_id
  end
end
