/*
 * Copyright (C) 2021 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import React from 'react'
import moment from 'moment-timezone'
import {render} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {WeeklyPlannerHeader} from '../index'

const TZ = 'America/Denver'

function defaultProps(options) {
  return {
    loadNextWeekItems: () => {},
    loadPastWeekItems: () => {},
    loadThisWeekItems: () => {},
    scrollToToday: () => {},
    loading: {
      isLoading: false,
      loadingWeek: false
    },
    visible: true,
    ...options
  }
}

describe('WeeklyPlannerHeader', () => {
  it('renders the component', () => {
    const {getByText} = render(<WeeklyPlannerHeader {...defaultProps()} />)
    expect(getByText('View previous week')).toBeInTheDocument()
    expect(getByText('Today')).toBeInTheDocument()
    expect(getByText('View next week')).toBeInTheDocument()
  })

  it('calls loadPastWeekItems when previous week button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadPastWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('View previous week').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })

  it('calls loadNextWeekItems when next week button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadNextWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('View next week').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })

  it('calls loadThisWeekItems when Today button is clicked', () => {
    const callback = jest.fn()
    const props = defaultProps({loadThisWeekItems: callback})
    const {getByText} = render(<WeeklyPlannerHeader {...props} />)
    getByText('Today').closest('button').click()
    expect(callback).toHaveBeenCalled()
  })
})
