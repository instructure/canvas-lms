# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

class BlackoutDate < ActiveRecord::Base
  belongs_to :context, polymorphic: [:account, :course]
  belongs_to :root_account, class_name: 'Account'

  validates :context, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :event_title, presence: true, length: { minimum: 1, maximum: 255 }
  validate :end_date_not_before_start_date

  extend RootAccountResolver
  resolves_root_account through: :context

  def end_date_not_before_start_date
    if end_date&.< start_date
      errors.add :end_date, "can't be before start date"
    end
  end
end
