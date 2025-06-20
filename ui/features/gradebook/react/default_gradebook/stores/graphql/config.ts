/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

const GRADEBOOK_GRAPHQL_CONFIG = {
  // Number of users to fetch per page in the gradebook
  usersPageSize: 100,
  // Maximum number of assignments to request concurrently
  maxAssignmentRequestCount: 10,
  // Initial number of students to include as an alias when fetching submissions
  // this will result responses with
  // maxPageSize * initialNumberOfStudentsPerSubmissionRequest submissions
  // There is a max on the number of aliases that can be used in a query,
  // which is currently 20.
  initialNumberOfStudentsPerSubmissionRequest: 20,
  // Maximum number of assignments to request concurrently
  maxSubmissionRequestCount: 10,
}

export default Object.freeze(GRADEBOOK_GRAPHQL_CONFIG)
