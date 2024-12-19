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
import {render} from '@testing-library/react'
import tz from 'timezone'
import tzInTest from '@instructure/moment-utils/specHelpers'
import newYork from 'timezone/America/New_York'

import DateEventGroup from '../DateEventGroup'
import {buildEvent} from '../../../__tests__/AuditTrailSpecHelpers'
import buildAuditTrail from '../../../buildAuditTrail'

describe('DateEventGroup', () => {
  let defaultProps

  beforeEach(() => {
    tzInTest.configureAndRestoreLater({
      tz: tz(newYork, 'America/New_York'),
      tzData: {
        'America/New_York': newYork,
      },
    })

    const auditEvents = [
      buildEvent({id: '4901', userId: '1101', createdAt: '2018-09-01T16:34:00Z'}),
      buildEvent({id: '4902', userId: '1101', createdAt: '2018-09-01T16:45:00Z'}),
      buildEvent({id: '4903', userId: '1101', createdAt: '2018-09-01T16:56:00Z'}),
    ]
    const users = [{id: '1101', name: 'A stupefying student', role: 'student'}]
    const externalTools = []
    const quizzes = []
    const auditTrail = buildAuditTrail({auditEvents, users, externalTools, quizzes})

    defaultProps = {
      dateEventGroup: auditTrail.creatorEventGroups[0].dateEventGroups[0],
    }
  })

  afterEach(() => {
    tzInTest.restore()
  })

  const renderDateEventGroup = (props = {}) => {
    return render(<DateEventGroup {...defaultProps} {...props} />)
  }

  it('displays the starting date and time in the timezone of the current user', () => {
    const {getByText} = renderDateEventGroup()
    expect(getByText('September 1 starting at 12:34pm')).toBeInTheDocument()
  })

  it('displays a list of all events', () => {
    const {container} = renderDateEventGroup()
    const events = container.querySelectorAll('ul li')
    expect(events).toHaveLength(3)
  })
})
