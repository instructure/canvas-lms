#
# Copyright (C) 2013 - present Instructure, Inc.
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

define [
  'underscore'
  '../collections/ContentMigrationIssueCollection'
  '../models/ContentMigrationProgress'
  '../models/ProgressingContentMigration'
  '../collections/PaginatedCollection'
], (_, MigrationIssueCollection, MigrationProgress, ProgressingContentMigration, PaginatedCollection) -> 
  class ProgressingContentMigrationCollection extends PaginatedCollection
    model: ProgressingContentMigration
    @optionProperty 'course_id'
    url: -> "/api/v1/courses/#{@course_id}/content_migrations"

    # Ensures the order of this collection is ranked by created_at date
    # We are returning 1, -1 and 0 because 'created_at' is date time
    # that can't be returns directly.
    comparator: (a, b) -> 
      if b.get('created_at') > a.get('created_at')
        1
      else if b.get('created_at') < a.get('created_at')
        -1
      else
        0
