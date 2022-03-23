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

# TODO: CANVAS_RAILS6_0 remove this whole class since we will always get it from switchman
class UnshardedRecord < ::ActiveRecord::Base
  self.abstract_class = true

  # This line is conditional just so if it is eager-loaded nothing breaks
  self.shard_category = :unsharded if Rails.version < "6.1"
end
