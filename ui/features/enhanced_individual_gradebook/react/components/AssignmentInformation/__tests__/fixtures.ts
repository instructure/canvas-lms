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

import type {AssignmentConnection} from 'features/enhanced_individual_gradebook/types'
import type {AssignmentInformationComponentProps} from '..'
import {defaultGradebookOptions} from '../../__tests__/fixtures'

export const defaultAssignment: AssignmentConnection = {
  id: '1',
  assignmentGroupId: '1',
  allowedAttempts: 1,
  anonymousGrading: false,
  anonymizeStudents: false,
  courseId: '1',
  dueAt: null,
  gradeGroupStudentsIndividually: false,
  gradesPublished: false,
  gradingType: 'points',
  htmlUrl: '/courses/1/assignments/1',
  moderatedGrading: false,
  hasSubmittedSubmissions: false,
  name: 'Missing Assignment 1',
  omitFromFinalGrade: false,
  pointsPossible: 10,
  postManually: false,
  submissionTypes: ['online_text_entry', 'online_upload'],
  published: true,
  workflowState: 'published',
  gradingPeriodId: '1',
  inClosedGradingPeriod: false,
}

export const assignmentInfoDefaultProps: AssignmentInformationComponentProps = {
  assignment: defaultAssignment,
  gradebookOptions: defaultGradebookOptions,
  handleSetGrades: () => {},
  assignmentGroupInvalid: false,
  students: [],
  submissions: [],
}
