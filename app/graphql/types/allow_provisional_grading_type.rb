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

module Types
  class AllowProvisionalGradingType < BaseEnum
    graphql_name "AllowProvisionalGradingType"
    description "Indicates whether a submission requires a provisional grade"

    value "not_applicable", description: "Assignment does not use moderated grading or grades are already published"
    value "not_allowed", description: "User is not allowed to provide a provisional grade"
    value "allowed", description: "User can provide a provisional grade"
  end
end
