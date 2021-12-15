# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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
class ApiScopeMapperFallback
  # The ApiScopeMapper is a generated file that we don't commit.
  # This ensures that if the file doesn't exist specs and canvas won't blow up.

  def self.lookup_resource(controller, _)
    controller
  end

  def self.name_for_resource(resource)
    resource
  end

  def self.register_fallback
    # rubocop:disable Lint/OrAssignmentToConstant
    ::ApiScopeMapper ||= ApiScopeMapperFallback
    # rubocop:enable Lint/OrAssignmentToConstant
  end
end
