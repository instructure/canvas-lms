// @ts-nocheck
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
import {act, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {renderRow} from '@canvas/util/react/testing/TableHelper'

import {
  BLACKOUT_DATES,
  PACE_ITEM_1,
  PACE_ITEM_3,
  PRIMARY_PACE,
  STUDENT_PACE,
} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {AssignmentRow} from '../assignment_row'

const setPaceItemDuration = jest.fn()

const defaultProps = {
  coursePace: PRIMARY_PACE,
  dueDate: '2020-01-01T02:00:00-05:00',
  excludeWeekends: false,
  coursePaceItem: PRIMARY_PACE.modules[0].items[0],
  coursePaceItemPosition: 0,
  isSyncing: false,
  blackoutDates: BLACKOUT_DATES,
  autosaving: false,
  disabledDaysOfWeek: [],
  showProjections: true,
  setPaceItemDuration,
  datesVisible: true,
  hover: false,
  isStacked: false,
  isStudentPace: false,
  coursePaceItemChanges: [],
}

beforeAll(() => {
  ENV.CONTEXT_TIMEZONE = 'America/New_York' // to match defaultProps.dueDate
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('AssignmentRow', () => {
  it('renders the assignment title and icon of the module item', () => {
    const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    expect(getByText(defaultProps.coursePaceItem.assignment_title)).toBeInTheDocument()
  })

  it('renders the assignment title as a link to the assignment', () => {
    const {getByRole} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))

    getByRole('link', {name: defaultProps.coursePaceItem.assignment_title})
  })

  it('renders an input that updates the duration for that module item', async () => {
    const {getByRole} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    const daysInput = getByRole('textbox', {
      name: 'Duration for assignment Basic encryption/decryption',
    }) as HTMLInputElement
    expect(daysInput).toBeInTheDocument()
    expect(daysInput.value).toBe('2')

    await userEvent.type(daysInput, '{selectall}{backspace}4')
    await userEvent.tab()

    expect(setPaceItemDuration).toHaveBeenCalled()
    expect(setPaceItemDuration).toHaveBeenCalledWith('60', 4)
  })

  it('renders the projected due date if projections are being shown', () => {
    const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
    expect(getByText('Wed, Jan 1, 2020')).toBeInTheDocument()
  })

  it('does not show the projected due date if projections are being hidden', async () => {
    const {queryByText} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} datesVisible={false} showProjections={false} />)
    )
    await waitFor(() => expect(queryByText('Wed, Jan 1, 2020')).not.toBeInTheDocument())
  })

  it('renders an icon showing whether or not the module item is published', () => {
    const publishedIcon = renderConnected(renderRow(<AssignmentRow {...defaultProps} />)).getByText(
      'Published'
    )
    expect(publishedIcon).toBeInTheDocument()

    const unpublishedProps = {
      ...defaultProps,
      coursePaceItem: {...defaultProps.coursePaceItem, published: false},
    }
    const unpublishedIcon = renderConnected(
      renderRow(<AssignmentRow {...unpublishedProps} />)
    ).getByText('Unpublished')
    expect(unpublishedIcon).toBeInTheDocument()
  })

  it('disables duration inputs while publishing', () => {
    const {getByRole} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} isSyncing={true} />)
    )
    const daysInput = getByRole('textbox', {
      name: 'Duration for assignment Basic encryption/decryption',
    })
    expect(daysInput).toBeDisabled()
  })

  it('renders provided possible points, and pluralizes them correctly', () => {
    const {getByText, rerender} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))

    expect(getByText('100 pts')).toBeInTheDocument()

    rerender(renderRow(<AssignmentRow {...defaultProps} coursePaceItem={PACE_ITEM_3} />))
    expect(getByText('1 pt')).toBeInTheDocument()
  })

  it('renders successfully when possible points are omitted', () => {
    const {getByText, rerender} = renderConnected(
      renderRow(
        <AssignmentRow
          {...defaultProps}
          coursePaceItem={{...PACE_ITEM_1, points_possible: undefined}}
        />
      )
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()

    rerender(
      renderRow(
        <AssignmentRow {...defaultProps} coursePaceItem={{...PACE_ITEM_1, points_possible: null}} />
      )
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()
  })

  it('shows durations as read-only text when on student paces', () => {
    const {queryByRole, getByText} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} coursePace={STUDENT_PACE} isStudentPace={true} />)
    )
    expect(
      queryByRole('textbox', {
        name: 'Duration for assignment Basic encryption/decryption',
      })
    ).not.toBeInTheDocument()
    expect(getByText('2')).toBeInTheDocument()
  })

  describe('with course paces for students', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.course_paces_for_students = true
    })

    it('renders an input for student paces that updates the duration for that module item', async () => {
      const {getByRole} = renderConnected(
        renderRow(
          <AssignmentRow {...defaultProps} coursePace={STUDENT_PACE} isStudentPace={true} />
        )
      )
      const daysInput = getByRole('textbox', {
        name: 'Duration for assignment Basic encryption/decryption',
      }) as HTMLInputElement
      expect(daysInput).toBeInTheDocument()
      expect(daysInput.value).toBe('2')

      await userEvent.type(daysInput, '{selectall}{backspace}4')
      await userEvent.tab()

      expect(setPaceItemDuration).toHaveBeenCalled()
      expect(setPaceItemDuration).toHaveBeenCalledWith('60', 4)
    })
  })

  it("renders an indicator next to duration picker when there's unsaved changes", () => {
    const unsavedChangeText = 'Unsaved change'
    const {queryByText, getByText, rerender} = renderConnected(
      renderRow(<AssignmentRow {...defaultProps} />)
    )
    const daysInput = getByText(
      'Duration for assignment Basic encryption/decryption'
    ) as HTMLInputElement
    expect(daysInput).toBeInTheDocument()
    expect(queryByText(unsavedChangeText)).not.toBeInTheDocument()

    const coursePaceItemChanges = [
      {id: PACE_ITEM_1.id, oldValue: PACE_ITEM_1, newValue: {...PACE_ITEM_1, duration: 3}},
    ]
    rerender(
      renderRow(<AssignmentRow {...defaultProps} coursePaceItemChanges={coursePaceItemChanges} />)
    )
    expect(getByText(unsavedChangeText)).toBeInTheDocument()
  })

  describe('localized', () => {
    const locale = ENV.LOCALE
    beforeAll(() => {
      ENV.LOCALE = 'en-GB'
    })
    afterAll(() => {
      ENV.LOCALE = locale
    })
    it('localizes the projected dates', () => {
      const {getByText} = renderConnected(renderRow(<AssignmentRow {...defaultProps} />))
      expect(getByText('Wed, 1 Jan 2020')).toBeInTheDocument()
    })
  })
})
