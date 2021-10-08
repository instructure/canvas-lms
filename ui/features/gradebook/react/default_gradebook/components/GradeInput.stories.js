/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import GradeInput from './GradeInput'

export default {
  title: 'Examples/Evaluate/Gradebook/GradeInput',
  component: GradeInput,
  args: {
    assignment: {
      anonymizeStudents: false,
      gradingType: ['gpa_scale', 'letter_grade', 'not_graded', 'pass_fail', 'points', 'percent'],
      pointsPossible: 100
    },
    disabled: false,
    enterGradesAs: 'points',
    gradingScheme: [
      ['A', 90],
      ['B', 80],
      ['C', 70]
    ],
    onSubmissionUpdate: () => {},
    pendingGradeInfo: {
      excused: false,
      grade: '95',
      valid: true
    },
    submission: {
      enteredGrade: 'A',
      enteredScore: 95,
      excused: false,
      id: '1'
    },
    submissionUpdating: false
  }
}

const Template = args => <GradeInput {...args} />
export const Default = Template.bind({})
