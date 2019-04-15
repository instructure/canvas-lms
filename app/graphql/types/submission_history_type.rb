#
# Copyright (C) 2019 - present Instructure, Inc.
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
  class SubmissionHistoryType < ApplicationObjectType
    graphql_name 'SubmissionHistory'

    # This does not implement Relay::Node or have an id/_id because all of the
    # submission histories share the same submission id. There is only one
    # `Submission` in the database, and it's updated whenever a new submission
    # is created. Thank versionable and poor database design choice made years
    # ago for this.

    implements Interfaces::TimestampInterface
    implements Interfaces::SubmissionInterface
  end
end
