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
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_create')

export const defaultEveryoneOption = {
  assetCode: 'everyone',
  label: I18n.t('Everyone'),
}
export const defaultEveryoneElseOption = {
  assetCode: 'everyone',
  label: I18n.t('Everyone else'),
}

export const masteryPathsOption = {
  assetCode: 'mastery_paths',
  label: I18n.t('Mastery Paths'),
}

const GradedDiscussionDueDateDefaultValues = {
  assignedInfoList: [],
  setAssignedInfoList: () => {},
  studentEnrollments: [],
  sections: [],
  dueDateErrorMessages: [],
  setDueDateErrorMessages: () => {},
  groups: [],
}

export const GradedDiscussionDueDatesContext = React.createContext(
  GradedDiscussionDueDateDefaultValues
)

export const ASSIGNMENT_OVERRIDE_GRAPHQL_TYPENAMES = {
  ADHOC: 'AdhocStudents',
  SECTION: 'Section',
  GROUP: 'Group',
}
