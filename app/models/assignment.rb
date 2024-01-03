# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class Assignment < AbstractAssignment
  # Returns the value to be stored in the polymorphic type column for Polymorphic Associations.
  def self.polymorphic_name
    "Assignment"
  end

  # Returns the value to be used for asset string prefixes.
  def self.reflection_type_name
    "assignment"
  end

  def self.serialization_root_key
    "assignment"
  end

  def self.url_context_class
    self
  end
end
