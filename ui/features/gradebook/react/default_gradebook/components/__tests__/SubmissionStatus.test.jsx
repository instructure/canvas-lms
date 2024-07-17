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

import React from 'react'
import {render, screen, cleanup} from '@testing-library/react'
import '@testing-library/jest-dom'
import SubmissionStatus from '../SubmissionStatus'

describe('SubmissionStatus - Pills', () => {
  let props

  beforeEach(() => {
    props = {
      assignment: {
        anonymizeStudents: false,
        postManually: false,
        published: true,
      },
      isConcluded: false,
      isInOtherGradingPeriod: false,
      isInClosedGradingPeriod: false,
      isInNoGradingPeriod: false,
      isNotCountedForScore: false,
      submission: {
        assignmentId: '1',
        excused: false,
        hasPostableComments: false,
        late: false,
        missing: false,
        postedAt: null,
        secondsLate: 0,
        workflowState: 'unsubmitted',
      },
    }
  })

  afterEach(cleanup)

  test('shows the "Unpublished" pill when the assignment is unpublished', () => {
    props.assignment.published = false
    render(<SubmissionStatus {...props} />)
    expect(screen.getByText('Unpublished')).toBeInTheDocument()
  })

  test('does not show the "Unpublished" pill when the assignment is published', () => {
    props.assignment.published = true
    render(<SubmissionStatus {...props} />)
    expect(screen.queryByText('Unpublished')).toBeNull()
  })

  // Add additional test cases following the above structure...
})
