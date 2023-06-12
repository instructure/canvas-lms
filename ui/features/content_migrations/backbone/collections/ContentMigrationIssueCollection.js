/*
 * Copyright (C) 2023 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import {extend} from '@canvas/backbone/utils'
import PaginatedCollection from '@canvas/pagination/backbone/collections/PaginatedCollection'

extend(ContentMigrationIssueCollection, PaginatedCollection)

function ContentMigrationIssueCollection() {
  return ContentMigrationIssueCollection.__super__.constructor.apply(this, arguments)
}

ContentMigrationIssueCollection.optionProperty('course_id')

ContentMigrationIssueCollection.optionProperty('content_migration_id')

ContentMigrationIssueCollection.prototype.url = function () {
  return (
    '/api/v1/courses/' +
    this.course_id +
    '/content_migrations/' +
    this.content_migration_id +
    '/migration_issues'
  )
}

export default ContentMigrationIssueCollection
