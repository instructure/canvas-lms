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
import {waitFor} from '@testing-library/react'

import {BLACKOUT_DATES, PRIMARY_PLAN} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {AssignmentRow} from '../assignment_row'

const setPlanItemDuration = jest.fn()
const setAdjustingHardEndDatesAfter = jest.fn()

const defaultProps = {
  pacePlan: PRIMARY_PLAN,
  dueDate: '2020-01-01',
  excludeWeekends: false,
  pacePlanItem: PRIMARY_PLAN.modules[0].items[0],
  pacePlanItemPosition: 0,
  blackoutDates: BLACKOUT_DATES,
  planCompleted: false,
  autosaving: false,
  enrollmentHardEndDatePlan: false,
  adjustingHardEndDatesAfter: undefined,
  disabledDaysOfWeek: [],
  showProjections: true,
  setPlanItemDuration,
  setAdjustingHardEndDatesAfter
}

describe('AssignmentRow', () => {
  it('renders the projected due date if projections are being shown', () => {
    const {getByText} = renderConnected(<AssignmentRow {...defaultProps} />)
    expect(getByText('1/1/2020')).toBeInTheDocument()
  })

  it('does not show the projected due date if projections are being hidden', async () => {
    const {queryByText} = renderConnected(
      <AssignmentRow {...defaultProps} showProjections={false} />
    )
    await waitFor(() => expect(queryByText('1/1/2020')).not.toBeInTheDocument())
  })
})
