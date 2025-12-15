/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'

import AssignmentPostingPolicyTray from '../index'
import {CamelizedAssignment} from '@canvas/grading/grading'
import {MockedProvider} from '@apollo/client/testing'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import {queryClient} from '@canvas/query'

export type MockContext = {
  assignment: CamelizedAssignment
  selectedPostManually?: boolean
  onAssignmentPostPolicyUpdated?: ({
    assignmentId,
    postManually,
  }: {
    assignmentId: string
    postManually: boolean
  }) => void
  onExited?: () => void
  onDismiss?: () => void
}

export const createDefaultContext = (): MockContext => ({
  assignment: {
    allowedAttempts: 1,
    anonymizeStudents: false,
    anonymousGrading: false,
    courseId: '1234',
    gradingType: 'points',
    id: '2301',
    name: 'Math 1.1',
    postManually: false,
    moderatedGrading: false,
    newQuizzesAnonymousParticipants: false,
    gradesPublished: false,
    dueAt: '',
    htmlUrl: 'http://example.com',
    muted: false,
    pointsPossible: 100,
    published: true,
    hasRubric: false,
    submissionTypes: ['online_text_entry'],
  },
  onAssignmentPostPolicyUpdated: vi.fn(),
  onExited: vi.fn(),
  onDismiss: vi.fn(),
})

export const renderTray = (context: MockContext) => {
  let tray: {show: (context: MockContext) => void} | null = null
  const component = render(
    <MockedProvider mocks={[]} addTypename={false}>
      <MockedQueryClientProvider client={queryClient}>
        <AssignmentPostingPolicyTray
          ref={ref => {
            tray = ref as {show: (context: MockContext) => void} | null
          }}
        />
      </MockedQueryClientProvider>
    </MockedProvider>,
  )
  if (tray) {
    ;(tray as {show: (context: MockContext) => void}).show(context)
  }
  return component
}

export const getTray = () => screen.queryByTestId('assignment-posting-policy-tray')

export const getSaveButton = () => screen.getByTestId('assignment-posting-policy-save-button')
export const getCancelButton = () => screen.getByTestId('assignment-posting-policy-cancel-button')
export const getCloseButton = () =>
  screen.getByTestId('assignment-posting-policy-close-button').children[0]
export const getInput = (name: string) => {
  return name === 'Automatically'
    ? screen.getByTestId('assignment-posting-policy-automatic-radio')
    : screen.getByTestId('assignment-posting-policy-manual-radio')
}

export const enterNewDateTime = async (dateTimeElement: HTMLElement, dateTimeString: string) => {
  await userEvent.click(dateTimeElement)
  await userEvent.clear(dateTimeElement)
  await userEvent.paste(dateTimeString)
  await userEvent.tab()
}
