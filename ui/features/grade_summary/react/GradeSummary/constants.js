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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('grade_summary')

export const ASSIGNMENT_SORT_OPTIONS = {
  ASSIGNMENT_GROUP: 'Assignment Group',
  DUE_DATE: 'Due Date',
  NAME: 'Name',
  MODULE: 'Module',
}

export const ASSIGNMENT_NOT_APPLICABLE = 'N/A'

export const ASSIGNMENT_STATUS = {
  EXCUSED: {
    id: 'excused',
    label: I18n.t('Excused'),
    color: 'primary',
    shouldConsiderAsGraded: false,
  },
  DROPPED: {
    id: 'dropped',
    label: I18n.t('Dropped'),
    color: 'primary',
    shouldConsiderAsGraded: false,
  },
  MISSING: {
    id: 'missing',
    label: I18n.t('Missing'),
    color: 'danger',
    shouldConsiderAsGraded: false,
  },
  NOT_SUBMITTED: {
    id: 'not_submitted',
    label: I18n.t('Not Submitted'),
    color: 'primary',
    shouldConsiderAsGraded: false,
  },
  LATE_GRADED: {
    id: 'late_graded',
    label: I18n.t('Late'),
    color: 'warning',
    shouldConsiderAsGraded: true,
  },
  LATE_NOT_GRADED: {
    id: 'late_not_graded',
    label: I18n.t('Late'),
    color: 'warning',
    shouldConsiderAsGraded: false,
  },
  GRADED: {
    id: 'graded',
    label: I18n.t('Graded'),
    color: 'success',
    shouldConsiderAsGraded: true,
  },
  NOT_GRADED: {
    id: 'not_graded',
    label: I18n.t('Not Graded'),
    color: 'primary',
    shouldConsiderAsGraded: false,
  },
}
