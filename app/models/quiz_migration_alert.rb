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

class QuizMigrationAlert < ApplicationRecord
  belongs_to :user, optional: false
  belongs_to :course, optional: false
  belongs_to :migration, polymorphic: [:content_migration, :content_export]

  validates :user_id, :migration_id, presence: true

  set_policy do
    given { |u| u.id == user_id }
    can :read and can :update and can :destroy
  end
end
