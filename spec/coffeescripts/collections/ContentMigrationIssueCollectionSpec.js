/*
 * Copyright (C) 2013 - present Instructure, Inc.
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

import ContentMigrationIssueCollection from 'ui/features/content_migrations/backbone/collections/ContentMigrationIssueCollection'

QUnit.module('ContentMigrationIssueCollection')

test('generates the correct fetch url', () => {
  const course_id = 5
  const content_migration_id = 10
  const cmiCollection = new ContentMigrationIssueCollection([], {
    course_id,
    content_migration_id,
  })
  equal(
    cmiCollection.url(),
    `/api/v1/courses/${course_id}/content_migrations/${content_migration_id}/migration_issues`
  )
})
