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
import {render} from '@testing-library/react'
import moment from 'moment-timezone'
import {Provider} from 'react-redux'
import {createStore} from 'redux'
import {Day} from '../index'

const user = {id: '1', displayName: 'Jane', avatarUrl: '/picture/is/here', color: '#03893D'}
const defaultProps = {registerAnimatable: jest.fn(), deregisterAnimatable: jest.fn()}

// Create a mock store for MissingAssignments component
const defaultState = {
  opportunities: {
    items: [],
    missingItemsExpanded: false,
  },
  courses: [],
}

const mockAssignment = {
  id: '1',
  name: 'Missing Assignment 1',
  points_possible: 10,
  html_url: 'http://example.com/assignment1',
  due_at: '2024-01-01T00:00:00Z',
  submission_types: ['online_text_entry'],
  course_id: '1',
  uniqueId: '1',
}

const store = createStore((state = defaultState, action) => {
  switch (action.type) {
    case 'SET_STATE':
      return {...state, ...action.payload}
    default:
      return state
  }
})

const renderWithRedux = (ui, {reduxState = defaultState} = {}) => {
  store.dispatch({type: 'SET_STATE', payload: reduxState})
  return render(<Provider store={store}>{ui}</Provider>)
}

const currentTimeZoneName = moment.tz.guess()
const otherTimeZoneName = ['America/Denver', 'Europe/London'].find(it => it !== currentTimeZoneName)

// Tests need to run in at least one timezone
for (const [timeZoneDesc, timeZoneName] of [
  ['In current timezone', currentTimeZoneName],
  ['In other timezone', otherTimeZoneName],
]) {
  describe(timeZoneDesc, () => {
    let originalNow

    beforeAll(() => {
      moment.tz.setDefault(timeZoneName)
      originalNow = Date.now
      // Set fixed date to 2025-01-01 for consistent testing
      const fixedDate = new Date('2025-01-01T12:53:31-07:00').getTime()
      Date.now = jest.fn(() => fixedDate)
    })

    afterAll(() => {
      Date.now = originalNow
      moment.tz.setDefault()
    })

    afterEach(() => {
      jest.clearAllMocks()
    })

    it('renders today view correctly', () => {
      const today = moment().format('YYYY-MM-DD')
      const {getByTestId} = renderWithRedux(
        <Day {...defaultProps} timeZone={timeZoneName} day={today} />,
      )

      const todayText = getByTestId('today-text')
      expect(todayText).toHaveTextContent('Today')
      expect(getByTestId('today-date')).toHaveTextContent('January 1')
    })

    it('renders future date correctly', () => {
      const tomorrow = moment().add(1, 'days').format('YYYY-MM-DD')
      const {getByTestId} = renderWithRedux(
        <Day {...defaultProps} timeZone={timeZoneName} day={tomorrow} />,
      )

      expect(getByTestId('not-today')).toHaveTextContent('Tomorrow, January 2')
    })

    it('shows missing assignments component on today when enabled', () => {
      const today = moment().format('YYYY-MM-DD')
      const mockState = {
        opportunities: {
          items: [mockAssignment],
          missingItemsExpanded: true,
        },
        courses: [{id: '1', shortName: 'Course 1', color: '#00FF00', originalName: 'Course 1'}],
      }
      const {getByTestId} = renderWithRedux(
        <Day {...defaultProps} timeZone={timeZoneName} day={today} showMissingAssignments={true} />,
        {reduxState: mockState},
      )

      expect(getByTestId('missing-assignments')).toBeInTheDocument()
    })

    it('does not show missing assignments component on non-today', () => {
      const tomorrow = moment().add(1, 'days').format('YYYY-MM-DD')
      const {queryByTestId} = renderWithRedux(
        <Day
          {...defaultProps}
          timeZone={timeZoneName}
          day={tomorrow}
          showMissingAssignments={true}
        />,
      )

      expect(queryByTestId('missing-assignments')).not.toBeInTheDocument()
    })

    it('shows "Nothing Planned Yet" when no items exist', () => {
      const today = moment().format('YYYY-MM-DD')
      const {getByTestId} = renderWithRedux(
        <Day {...defaultProps} timeZone={timeZoneName} day={today} />,
      )

      expect(getByTestId('no-items')).toHaveTextContent('Nothing Planned Yet')
    })
  })
}

describe('Day items grouping', () => {
  const TZ = 'America/Denver'
  let originalNow

  beforeAll(() => {
    moment.tz.setDefault(TZ)
    originalNow = Date.now
    // Set fixed date to 2025-01-01 for consistent testing
    const fixedDate = new Date('2025-01-01T12:53:31-07:00').getTime()
    Date.now = jest.fn(() => fixedDate)
  })

  afterAll(() => {
    Date.now = originalNow
    moment.tz.setDefault()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('groups items by context correctly', () => {
    const items = [
      {
        id: '1',
        uniqueId: 'assignment_1',
        title: 'Assignment 1',
        date: moment.tz('2025-01-01T12:00:00Z', TZ),
        context: {
          type: 'Course',
          id: 1,
          title: 'Course 1',
        },
      },
      {
        id: '2',
        uniqueId: 'assignment_2',
        title: 'Assignment 2',
        date: moment.tz('2025-01-01T12:00:00Z', TZ),
        context: {
          type: 'Course',
          id: 1,
          title: 'Course 1',
        },
      },
      {
        id: '3',
        uniqueId: 'assignment_3',
        title: 'Assignment 3',
        date: moment.tz('2025-01-01T12:00:00Z', TZ),
        context: {
          type: 'Course',
          id: 2,
          title: 'Course 2',
        },
      },
    ]

    const {getByTestId} = renderWithRedux(
      <Day
        {...defaultProps}
        timeZone={TZ}
        day={moment().format('YYYY-MM-DD')}
        itemsForDay={items}
        currentUser={user}
      />,
    )

    expect(getByTestId('day')).toBeInTheDocument()
  })

  it('groups items without context into Notes category', () => {
    const items = [
      {
        id: '4',
        uniqueId: 'note_1',
        title: 'Note 1',
        date: moment.tz('2025-01-01T12:00:00Z', TZ),
      },
      {
        id: '5',
        uniqueId: 'note_2',
        title: 'Note 2',
        date: moment.tz('2025-01-01T12:00:00Z', TZ),
      },
    ]

    const {getByTestId} = renderWithRedux(
      <Day
        {...defaultProps}
        timeZone={TZ}
        day={moment().format('YYYY-MM-DD')}
        itemsForDay={items}
        currentUser={user}
      />,
    )

    expect(getByTestId('day')).toBeInTheDocument()
  })

  it('registers as animatable on mount', () => {
    const registerMock = jest.fn()
    const props = {
      ...defaultProps,
      registerAnimatable: registerMock,
      timeZone: TZ,
      day: moment().format('YYYY-MM-DD'),
    }

    renderWithRedux(<Day {...props} />)
    expect(registerMock).toHaveBeenCalledWith('day', expect.any(Object), 0, [])
  })

  it('deregisters as animatable on unmount', () => {
    const deregisterMock = jest.fn()
    const props = {
      ...defaultProps,
      deregisterAnimatable: deregisterMock,
      timeZone: TZ,
      day: moment().format('YYYY-MM-DD'),
    }

    const {unmount} = renderWithRedux(<Day {...props} />)
    unmount()
    expect(deregisterMock).toHaveBeenCalledWith('day', expect.any(Object), [])
  })
})
