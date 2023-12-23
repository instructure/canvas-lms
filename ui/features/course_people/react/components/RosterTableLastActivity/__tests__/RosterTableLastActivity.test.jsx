/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import RosterTableLastActivity from '../RosterTableLastActivity'
import tz from 'timezone'
import chicago from 'timezone/America/Chicago'
import detroit from 'timezone/America/Detroit'
import tzInTest from '@canvas/datetime/specHelpers'
import {getI18nFormats} from '../../../../../../boot/initializers/configureDateTime'

const observerEnrollment = {
  id: '1',
  type: 'ObserverEnrollment',
  lastActivityAt: '2022-07-07T12:00:00-08:00',
}

const studentEnrollment = {
  id: '2',
  type: 'StudentEnrollment',
  lastActivityAt: '2022-08-08T12:00:00-08:00',
}

const teacherEnrollment = {
  id: '3',
  type: 'TeacherEnrollment',
  lastActivityAt: '2022-09-09T12:00:00-03:05',
}

const noLastActivityEnrollment = {
  id: '4',
  type: 'StudentEnrollment',
  lastActivityAt: null,
}

const DEFAULT_PROPS = {
  enrollments: [studentEnrollment, teacherEnrollment],
}

describe('RosterTableLastActivity', () => {
  const setup = props => {
    return render(<RosterTableLastActivity {...props} />)
  }

  beforeAll(() => {
    ENV = {
      TIMEZONE: 'America/Detroit',
      CONTEXT_TIMEZONE: 'America/Chicago',
    }
    tzInTest.configureAndRestoreLater({
      tz: tz(detroit, 'America/Detroit', chicago, 'America/Chicago'),
      tzData: {
        'America/Chicago': chicago,
        'America/Detroit': detroit,
      },
      formats: getI18nFormats(),
    })
  })

  it('should render', () => {
    const container = setup(DEFAULT_PROPS)
    expect(container).toBeTruthy()
  })

  it('should contain the time and date of last activity in the timezone of the user', () => {
    const container = setup(DEFAULT_PROPS)
    const studentLastActivity = container.getByText('Aug 8, 2022 at 4pm') // ENV.TIMEZONE
    const teacherLastActivity = container.getByText('Sep 9, 2022 at 11:05am') // ENV.TIMEZONE
    expect(studentLastActivity).toBeInTheDocument()
    expect(teacherLastActivity).toBeInTheDocument()
  })

  it('should contain a tool tip with time and date of last activity in the context timezone', () => {
    const container = setup(DEFAULT_PROPS)
    const studentLastActivity = container.getByRole('tooltip', {name: 'Aug 8, 2022 at 3pm'}) // ENV.CONTEXT_TIMEZONE
    const teacherLastActivity = container.getByRole('tooltip', {name: 'Sep 9, 2022 at 10:05am'}) // ENV.CONTEXT_TIMEZONE
    expect(studentLastActivity).toBeInTheDocument()
    expect(teacherLastActivity).toBeInTheDocument()
  })

  it('should not render any content if the user has an observer role', () => {
    const container = setup({enrollments: [observerEnrollment]})
    expect(container.queryAllByText(/.+/i)).toHaveLength(0)
    expect(container.queryAllByRole('tooltip')).toHaveLength(0)
  })

  it('should not render any content if the user last activity is null', () => {
    const container = setup({enrollments: [noLastActivityEnrollment]})
    expect(container.queryAllByText(/.+/i)).toHaveLength(0)
    expect(container.queryAllByRole('tooltip')).toHaveLength(0)
  })
})
