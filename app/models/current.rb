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

class Current < ActiveSupport::CurrentAttributes
  attribute :in_migration_context

  def self.in_migration?
    in_migration_context == true
  end

  def self.with_migration_context(&)
    previous_value = in_migration_context
    self.in_migration_context = true
    yield
  ensure
    self.in_migration_context = previous_value
  end
end
