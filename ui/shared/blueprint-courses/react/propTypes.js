/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import MigrationStates from './migrationStates'

const {shape, string, arrayOf, oneOf, bool, instanceOf} = PropTypes
const propTypes = {}

propTypes.migrationState = oneOf(MigrationStates.statesList)

propTypes.term = shape({
  id: string.isRequired,
  name: string.isRequired,
})
propTypes.termList = arrayOf(propTypes.term)

propTypes.account = shape({
  id: string.isRequired,
  name: string.isRequired,
})
propTypes.accountList = arrayOf(propTypes.account)

propTypes.course = shape({
  id: string.isRequired,
  name: string.isRequired,
  course_code: string.isRequired,
  term: propTypes.term.isRequired,
  teachers: arrayOf(
    shape({
      display_name: string.isRequired,
    })
  ),
  teacher_count: string,
  sis_course_id: string,
})
propTypes.courseList = arrayOf(propTypes.course)

propTypes.courseInfo = shape({
  id: string.isRequired,
  name: string.isRequired,
  enrollment_term_id: string.isRequired,
  sis_course_id: string,
})

propTypes.lockableAttribute = oneOf([
  'points',
  'content',
  'due_dates',
  'availability_dates',
  'settings',
  'deleted',
])
propTypes.lockableAttributeList = arrayOf(propTypes.lockableAttribute)

propTypes.migrationException = shape({
  course_id: string.isRequired,
  conflicting_changes: propTypes.lockableAttributeList,
})
propTypes.migrationExceptionList = arrayOf(propTypes.migrationException)

propTypes.migrationChange = shape({
  asset_id: string.isRequired,
  asset_type: oneOf([
    'assignment',
    'quiz',
    'discussion_topic',
    'wiki_page',
    'attachment',
    'context_module',
    'learning_outcome',
    'learning_outcome_group',
    'announcement',
    'rubric',
    'syllabus',
    'media_tracks',
  ]).isRequired,
  asset_name: string.isRequired,
  change_type: oneOf(['created', 'updated', 'deleted']).isRequired,
  htnl_url: string,
  exceptions: propTypes.migrationExceptionList,
})
propTypes.migrationChangeList = arrayOf(propTypes.migrationChange)

propTypes.migration = shape({
  id: string.isRequired,
  workflow_state: propTypes.migrationState.isRequired,
  comment: string,
  created_at: string.isRequired,
  exports_started_at: string,
  imports_queued_at: string,
  imports_completed_at: string,
  changes: propTypes.migrationChangeList,
})
propTypes.migrationList = arrayOf(propTypes.migration)

propTypes.unsyncedChange = shape({
  asset_id: string.isRequired,
  asset_type: string.isRequired,
  asset_name: string.isRequired,
  change_type: string.isRequired,
  html_url: string.isRequired,
  locked: bool.isRequired,
})
propTypes.unsyncedChanges = arrayOf(propTypes.unsyncedChange)

propTypes.notification = shape({
  id: string.isRequired,
  message: string.isRequired,
  err: instanceOf(Error),
})
propTypes.notificationList = arrayOf(propTypes.notification)

propTypes.itemLocks = shape({
  content: bool,
  points: bool,
  due_dates: bool,
  availability_dates: bool,
})

propTypes.itemLocksByObject = shape({
  assignment: propTypes.itemLocks,
  discussion_topic: propTypes.itemLocks,
  wiki_page: propTypes.itemLocks,
  quiz: propTypes.itemLocks,
  attachment: propTypes.itemLocks,
})

export default propTypes
