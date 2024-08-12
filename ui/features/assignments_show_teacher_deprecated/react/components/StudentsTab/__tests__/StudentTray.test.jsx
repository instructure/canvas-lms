/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {closest, mockAssignment, mockUser, mockSubmission} from '../../../test-utils'
import StudentTray from '../StudentTray'

describe('student tray data', () => {
  it('renders basic information', () => {
    const user = mockUser()
    const submission = mockSubmission({nodes: [user]})
    const assignment = mockAssignment({
      name: 'Egypt Economy Research',
      submissions: {
        nodes: [submission],
      },
    })

    user.submission = submission
    const {getByText} = render(
      <StudentTray assignment={assignment} student={user} trayOpen={true} />
    )
    expect(getByText(user.shortName)).toBeInTheDocument()
    const userProfileLink = closest(getByText(user.shortName), 'a')
    expect(userProfileLink.getAttribute('target')).toMatch('_blank')
    expect(getByText(assignment.name)).toBeInTheDocument()

    expect(getByText(`Score ${submission.score}/${assignment.pointsPossible}`)).toBeInTheDocument()
    expect(getByText('SpeedGrader')).toBeInTheDocument()

    const viewSubmissionLink = closest(getByText('SpeedGrader'), 'a')
    expect(viewSubmissionLink).toBeTruthy()
    expect(viewSubmissionLink.getAttribute('href')).toMatch(
      /\/courses\/course-lid\/gradebook\/speed_grader\?assignment_id=assignment-lid#%7B%22student_id%22:%22user_1%22%7D/
    )
    expect(viewSubmissionLink.getAttribute('target')).toMatch('_blank')
  })

  it('renders no-score case', () => {
    const user = mockUser()
    const submission = mockSubmission({score: null, nodes: [user]})
    const assignment = mockAssignment({
      submissions: {
        nodes: [submission],
      },
    })
    user.submission = submission

    const {getByText} = render(
      <StudentTray assignment={assignment} student={user} trayOpen={true} />
    )
    expect(getByText(`Score –/${assignment.pointsPossible}`)).toBeInTheDocument()
  })
})

describe('student tray actions options', () => {
  /* These are lame but will expand later when the tray respects permissions
     for whether user can do these things.
   */
  it('renders Message Student link', () => {
    const user = mockUser()
    const submission = mockSubmission({score: null, nodes: [user]})
    const assignment = mockAssignment({
      submissions: {
        nodes: [submission],
      },
    })
    user.submission = submission

    const {getByText} = render(
      <StudentTray assignment={assignment} student={user} trayOpen={true} />
    )
    const messageStudentButton = closest(getByText('Message Student'), 'button')
    expect(messageStudentButton).toBeTruthy()
  })

  it('renders Submit for Student link', () => {
    const user = mockUser()
    const submission = mockSubmission({score: null, nodes: [user]})
    const assignment = mockAssignment({
      submissions: {
        nodes: [submission],
      },
    })
    user.submission = submission

    const {getByText} = render(
      <StudentTray assignment={assignment} student={user} trayOpen={true} />
    )
    const submitForButton = closest(getByText('Submit for Student'), 'button')
    expect(submitForButton).toBeTruthy()
  })
})
