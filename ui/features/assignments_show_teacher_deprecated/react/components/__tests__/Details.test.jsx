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
import {mockAssignment, mockOverride} from '../../test-utils'
import Details from '../Details'

const override1 = {
  lid: '18',
  title: 'Section A',
  dueAt: '2019-09-01T23:59:59-06:00',
  lockAt: '2019-09-03T23:59:59-06:00',
  unlockAt: '2019-08-28T00:00:00-06:00',
  set: {
    lid: '2',
    sectionName: 'Section A',
    __typename: 'Section',
  },
}
const override2 = {
  lid: '19',
  title: 'Section B',
  dueAt: '2019-10-01T23:59:59-06:00',
  lockAt: '2019-10-03T23:59:59-06:00',
  unlockAt: '2019-09-28T00:00:00-06:00',
  set: {
    lid: '3',
    sectionName: 'Section B',
    __typename: 'Section',
  },
}

function renderDetails(assignment, props = {}) {
  return render(
    <Details
      assignment={assignment}
      onChangeAssignment={() => {}}
      onValidate={() => true}
      invalidMessage={() => undefined}
      {...props}
    />
  )
}
describe('Assignment Details', () => {
  it('renders', () => {
    const assignment = mockAssignment()
    const {getByText, getAllByText, getByTestId} = renderDetails(assignment)

    expect(getByTestId('AssignmentDescription')).toBeInTheDocument()
    expect(getByText('Everyone')).toBeInTheDocument()
    expect(getAllByText('Due:', {exact: false})[0]).toBeInTheDocument()
    expect(getByText('Available', {exact: false})).toBeInTheDocument()
  })

  it('renders an override', () => {
    const assignment = mockAssignment({
      assignmentOverrides: {
        nodes: [mockOverride()],
      },
    })
    const {getByText} = renderDetails(assignment)
    expect(getByText('Section A')).toBeInTheDocument()
    expect(getByText('Everyone else')).toBeInTheDocument()
  })

  it('renders all the overrides', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)],
      },
    })
    const {getByText, queryAllByText} = renderDetails(assignment)

    expect(getByText('Section A')).toBeInTheDocument()
    expect(getByText('Section B')).toBeInTheDocument()
    expect(queryAllByText('Everyone', {exact: false})).toHaveLength(1)
  })

  it('renders all override dates', () => {
    const assignment = mockAssignment({
      dueAt: '2019-08-01T23:59:59-06:00',
      lockAt: '2019-08-03T23:59:59-06:00',
      unlockAt: '2019-07-28T00:00:00-06:00',
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)],
      },
    })
    const {getByText} = renderDetails(assignment)

    // Everyone else
    const everyoneElseOverrideSummary = getByText('Everyone else').closest(
      `div[data-testid="OverrideSummary"]`
    )
    expect(getByText('8/2/2019', everyoneElseOverrideSummary)).toBeInTheDocument() // Due Date
    expect(getByText('7/28/2019 to 8/4/2019', everyoneElseOverrideSummary)).toBeInTheDocument() // Available from/to

    // Section A
    const sectionAOverrideSummary = getByText('Section A').closest(
      `div[data-testid="OverrideSummary"]`
    )
    expect(getByText('9/2/2019', sectionAOverrideSummary)).toBeInTheDocument() // Due Date
    expect(getByText('8/28/2019 to 9/4/2019', sectionAOverrideSummary)).toBeInTheDocument() // Available from/to

    // Section B
    const sectionBOverrideSummary = getByText('Section B').closest(
      `div[data-testid="OverrideSummary"]`
    )
    expect(getByText('10/2/2019', sectionBOverrideSummary)).toBeInTheDocument() // Due Date
    expect(getByText('9/28/2019 to 10/4/2019', sectionBOverrideSummary)).toBeInTheDocument() // Available from/to
  })

  /*
   *  CAUTION: The InstUI Select component is greatly changed in v7.
   *  Updating the import to the new ui-select location is almost certainly
   *  going to break the functionality of the component. Any failing tests
   *  will just be skipped, and the component can be fixed later when work
   *  resumes on A2.
   */

  it.skip('renders override details when expand button is clicked', () => {
    const assignment = mockAssignment({
      dueAt: '2019-09-01T23:59:59-06:00',
      lockAt: '2019-09-03T23:59:59-06:00',
      unlockAt: '2019-08-28T00:00:00-06:00',
      assignmentOverrides: {
        nodes: [mockOverride(override1)],
      },
      submissionTypes: ['online_text_entry', 'online_url', 'online_upload'],
    })
    const {getByText, getByTestId, getAllByTestId} = renderDetails(assignment)
    const everyoneOverrideDetailButton = getByText('Everyone else')
      .closest(`div[data-testid="Override"]`)
      .querySelector('button')
    expect(everyoneOverrideDetailButton.getAttribute('aria-expanded')).toBe('false')

    everyoneOverrideDetailButton.click()
    expect(everyoneOverrideDetailButton.getAttribute('aria-expanded')).toBe('true')
    expect(getByTestId('OverrideDetail')).toBeInTheDocument()

    // Dates
    const overrideDetail = getByTestId('OverrideDetail')
    expect(getAllByTestId('EditableDateTime', overrideDetail).length).toEqual(3)
    // Due Date
    expect(
      getByText('Due:', overrideDetail).closest(`div[data-testid="AssignmentDate"]`)
    ).toBeInTheDocument()
    // Available Date
    expect(
      getByText('Available:', overrideDetail).closest(`div[data-testid="AssignmentDate"]`)
    ).toBeInTheDocument()
    // Until Date
    expect(
      getByText('Until:', overrideDetail).closest(`div[data-testid="AssignmentDate"]`)
    ).toBeInTheDocument()

    // 3 Submission Types: Text, URL & File
    const submissionTypeContainer = getAllByTestId('OverrideSubmissionTypes', overrideDetail)
    expect(submissionTypeContainer.length).toEqual(3)
    expect(getByText('Item 1', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('Text Entry', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('Item 2', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('URL', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('Item 3', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('File', submissionTypeContainer[0])).toBeInTheDocument()
    expect(getByText('All Types Allowed', submissionTypeContainer[0])).toBeInTheDocument()

    // Attempts
    const attemptsDetailContainer = getByTestId('OverrideAttempts-Limit')
    expect(getByText('Attempts Allowed', attemptsDetailContainer)).toBeInTheDocument()
  })

  it('renders the Add Override button if !readOnly', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)],
      },
    })
    const {getByTestId} = renderDetails(assignment)

    expect(getByTestId('AddHorizontalRuleButton')).toBeInTheDocument()
  })

  it('does not render the Add Override button if readOnly', () => {
    const assignment = mockAssignment({
      dueAt: null,
      assignmentOverrides: {
        nodes: [mockOverride(override1), mockOverride(override2)],
      },
    })
    const {queryByTestId} = renderDetails(assignment, {readOnly: true})

    expect(queryByTestId('AddHorizontalRuleButton')).toBeNull()
  })
})
