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

import {
  BLACKOUT_DATES,
  PACE_ITEM_1,
  PACE_ITEM_3,
  PRIMARY_PACE,
  STUDENT_PACE
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
  isStudentPace: false
}

beforeAll(() => {
  ENV.CONTEXT_TIMEZONE = 'America/New_York' // to match defaultProps.dueDate
})

afterEach(() => {
  jest.clearAllMocks()
})

describe('AssignmentRow', () => {
  it('renders the assignment title and icon of the module item', () => {
    const {getByText} = renderConnected(<AssignmentRow {...defaultProps} />)
    expect(getByText(defaultProps.coursePaceItem.assignment_title)).toBeInTheDocument()
  })

  it('renders the assignment title as a link to the assignment', () => {
    const {getByText} = renderConnected(<AssignmentRow {...defaultProps} />)

    // Implementation detail bleeds in here; but the `TruncateText` means that the title isn't directly in the `a`
    expect(
      getByText(defaultProps.coursePaceItem.assignment_title)?.parentNode?.parentNode
    ).toHaveAttribute('href', defaultProps.coursePaceItem.assignment_link)
  })

  it('renders an input that updates the duration for that module item', () => {
    const {getByRole} = renderConnected(<AssignmentRow {...defaultProps} />)
    const daysInput = getByRole('textbox', {
      name: 'Duration for module Basic encryption/decryption'
    }) as HTMLInputElement
    expect(daysInput).toBeInTheDocument()
    expect(daysInput.value).toBe('2')

    userEvent.type(daysInput, '{selectall}{backspace}4')
    act(() => daysInput.blur())

    expect(setPaceItemDuration).toHaveBeenCalled()
    expect(setPaceItemDuration).toHaveBeenCalledWith('60', 4)
  })

  it('renders the projected due date if projections are being shown', () => {
    const {getByText} = renderConnected(<AssignmentRow {...defaultProps} />)
    expect(getByText('Wed, Jan 1, 2020')).toBeInTheDocument()
  })

  it('does not show the projected due date if projections are being hidden', async () => {
    const {queryByText} = renderConnected(
      <AssignmentRow {...defaultProps} datesVisible={false} showProjections={false} />
    )
    await waitFor(() => expect(queryByText('Wed, Jan 1, 2020')).not.toBeInTheDocument())
  })

  it('renders an icon showing whether or not the module item is published', () => {
    const publishedIcon = renderConnected(<AssignmentRow {...defaultProps} />).getByText(
      'Published'
    )
    expect(publishedIcon).toBeInTheDocument()

    const unpublishedProps = {
      ...defaultProps,
      coursePaceItem: {...defaultProps.coursePaceItem, published: false}
    }
    const unpublishedIcon = renderConnected(<AssignmentRow {...unpublishedProps} />).getByText(
      'Unpublished'
    )
    expect(unpublishedIcon).toBeInTheDocument()
  })

  it('disables duration inputs while publishing', () => {
    const {getByRole} = renderConnected(<AssignmentRow {...defaultProps} isSyncing />)
    const daysInput = getByRole('textbox', {
      name: 'Duration for module Basic encryption/decryption'
    })
    expect(daysInput).toBeDisabled()
  })

  it('renders provided possible points, and pluralizes them correctly', () => {
    const {getByText, rerender} = renderConnected(<AssignmentRow {...defaultProps} />)

    expect(getByText('100 pts')).toBeInTheDocument()

    rerender(<AssignmentRow {...defaultProps} coursePaceItem={PACE_ITEM_3} />)
    expect(getByText('1 pt')).toBeInTheDocument()
  })

  it('renders successfully when possible points are omitted', () => {
    const {getByText, rerender} = renderConnected(
      <AssignmentRow
        {...defaultProps}
        coursePaceItem={{...PACE_ITEM_1, points_possible: undefined}}
      />
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()

    rerender(
      <AssignmentRow {...defaultProps} coursePaceItem={{...PACE_ITEM_1, points_possible: null}} />
    )

    expect(getByText(PACE_ITEM_1.assignment_title)).toBeInTheDocument()
  })

  it('shows durations as read-only text when on student paces', () => {
    const {queryByRole, getByText} = renderConnected(
      <AssignmentRow {...defaultProps} coursePace={STUDENT_PACE} isStudentPace />
    )
    expect(
      queryByRole('textbox', {
        name: 'Duration for module Basic encryption/decryption'
      })
    ).not.toBeInTheDocument()
    expect(getByText('2')).toBeInTheDocument()
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
      const {getByText} = renderConnected(<AssignmentRow {...defaultProps} />)
      expect(getByText('Wed, 1 Jan 2020')).toBeInTheDocument()
    })
  })
})
