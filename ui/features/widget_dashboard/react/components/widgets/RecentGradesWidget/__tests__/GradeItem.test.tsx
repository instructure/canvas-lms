/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {GradeItem} from '../GradeItem'
import type {RecentGradeSubmission} from '../../../../types'
import {ResponsiveProvider} from '../../../../hooks/useResponsiveContext'
import {PlatformTestWrapper} from '../../../../__tests__/testHelpers'

const buildSubmission = (submissionTypes: string[]): RecentGradeSubmission => ({
  _id: 'sub-test',
  submittedAt: '2026-04-25T10:00:00Z',
  gradedAt: '2026-04-27T14:30:00Z',
  score: 90,
  grade: 'A',
  excused: false,
  state: 'graded',
  assignment: {
    _id: 'asgn-test',
    name: 'Test Assignment',
    htmlUrl: '/courses/1/assignments/1',
    pointsPossible: 100,
    gradingType: 'points',
    submissionTypes,
    quiz: null,
    discussion: null,
    course: {
      _id: '1',
      name: 'Test Course',
      courseCode: 'TEST-101',
    },
  },
})

const renderGradeItem = (submission: RecentGradeSubmission) => {
  return render(
    <PlatformTestWrapper>
      <ResponsiveProvider matches={['desktop']}>
        <GradeItem submission={submission} />
      </ResponsiveProvider>
    </PlatformTestWrapper>,
  )
}

describe('GradeItem', () => {
  it('renders the peer review icon for a peer review submission', () => {
    const submission = buildSubmission(['peer_review'])

    renderGradeItem(submission)

    expect(screen.getByTestId('peer-review-icon')).toBeInTheDocument()
  })

  it('renders the assignment icon for a non peer review submission', () => {
    const submission = buildSubmission(['online_text_entry'])

    renderGradeItem(submission)

    expect(screen.getByTestId('assignment-icon')).toBeInTheDocument()
    expect(screen.queryByTestId('peer-review-icon')).not.toBeInTheDocument()
  })
})
