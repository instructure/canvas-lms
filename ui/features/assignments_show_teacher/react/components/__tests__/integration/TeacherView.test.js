/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import TeacherView from '../../TeacherView'
import {TeacherViewContextDefaults} from '../../TeacherViewContext'
import {MockedProvider} from '@apollo/react-testing'
import {
  closest,
  mockAssignment,
  mockOverride,
  mockPageInfo,
  saveAssignmentResult,
  waitForNoElement,
  initialTeacherViewGQLMocks,
} from '../../../test-utils'
import {DateTime} from '@instructure/ui-i18n'

const locale = TeacherViewContextDefaults.locale
const timeZone = TeacherViewContextDefaults.timeZone

const newOverrideLockAt = '2019-04-02T13:00:00.000-05:00'

const override = mockOverride()
const assignment = mockAssignment({
  assignmentOverrides: {pageInfo: mockPageInfo(), nodes: [override]},
})

function mocks() {
  return [
    ...initialTeacherViewGQLMocks(assignment.course.lid),
    saveAssignmentResult(
      assignment,
      {
        id: assignment.lid,
        name: assignment.name,
        description: assignment.description,
        state: assignment.state,
        pointsPossible: parseFloat(assignment.pointsPossible),
        dueAt: assignment.dueAt && new Date(assignment.dueAt).toISOString(),
        unlockAt: assignment.unlockAt && new Date(assignment.unlockAt).toISOString(),
        lockAt: assignment.lockAt && new Date(assignment.lockAt).toISOString(),
        assignmentOverrides: [
          {
            id: override.lid,
            dueAt: override.dueAt && new Date(override.dueAt).toISOString(),
            lockAt: newOverrideLockAt && new Date(newOverrideLockAt).toISOString(), // <-- this is what was updated
            unlockAt: override.unlockAt && new Date(override.unlockAt).toISOString(),
            sectionId: override.set.lid,
            groupId: undefined,
            studentIds: undefined,
          },
        ],
      },
      {},
      undefined
    ),
  ]
}

describe('TeacherView', () => {
  it.skip('updates assignment, including overrides', async () => {
    // what this spec _really_ tests is that the saveAssignment mutation the code
    // calls matches the mocked mutation, which we know includes the
    // AssignmentOverrides array. So we can infer that TeacherView is
    // sending the overrides with the save.
    const {getAllByText, getByText, getByTestId, getByDisplayValue, findByTestId} = render(
      <MockedProvider mocks={mocks()} addTypename={false}>
        <TeacherView assignment={assignment} />
      </MockedProvider>
    )

    // open the override detail
    const expandButton = getAllByText('Click to show details')[0]
    fireEvent.click(expandButton)
    await findByTestId('OverrideDetail')

    // open the Until date editor
    const editButton = closest(getByText('Edit Until'), 'button')
    editButton.click()
    await findByTestId('EditableDateTime-editor')

    // edit the date
    const dateDisplay = DateTime.toLocaleString(override.lockAt, locale, timeZone, 'LL')
    const dinput = getByDisplayValue(dateDisplay)
    dinput.focus()
    fireEvent.change(dinput, {target: {value: newOverrideLockAt}})

    // blur to show the footer
    dinput.blur()
    await findByTestId('TeacherFooter')

    const saveButton = closest(getByText('Save'), 'button')
    saveButton.click()
    expect(await waitForNoElement(() => getByTestId('TeacherFooter'))).toBe(true)
  }, 10000 /* giving this a 10sec timeout since for some reason it is timing out in jenkins */)
})
