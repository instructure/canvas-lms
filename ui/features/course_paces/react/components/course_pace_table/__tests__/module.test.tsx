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
import {act} from '@testing-library/react'
import moment from 'moment'

import {PACE_MODULE_1, PRIMARY_PACE} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {Module} from '../module'
import type {ModuleWithDueDates, CoursePaceItemWithDate} from '../../../types'

const dueDates = ['2022-03-18T00:00:00-06:00', '2022-03-22T00:00:00-06:00']
const module1: ModuleWithDueDates = {...(PACE_MODULE_1 as unknown as ModuleWithDueDates)}
module1.itemsWithDates = module1.items.map(
  (item, index) =>
    ({
      ...item,
      type: 'assignment' as const,
      date: moment(dueDates[index]),
    } as CoursePaceItemWithDate)
)

const defaultProps = {
  index: 1,
  module: module1,
  coursePace: PRIMARY_PACE,
  responsiveSize: 'large' as const,
  showProjections: true,
  compression: 0,
}

describe('Module', () => {
  it('is expanded by default, shows the module name always, and only shows column headers when expanded', () => {
    const {getByRole, queryByText, queryByTestId} = renderConnected(<Module {...defaultProps} />)
    const moduleHeader = getByRole('button', {name: '1. How 2 B A H4CK32'})
    expect(moduleHeader).toBeInTheDocument()
    expect(queryByText(PACE_MODULE_1.items[0].assignment_title)).toBeInTheDocument()
    expect(queryByTestId('pp-duration-columnheader')).toBeInTheDocument()
    expect(queryByTestId('pp-due-date-columnheader')).toBeInTheDocument()
    expect(queryByTestId('pp-status-columnheader')).toBeInTheDocument()

    act(() => moduleHeader.click())
    expect(getByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(queryByText(PACE_MODULE_1.items[0].assignment_title)).not.toBeInTheDocument()
    expect(queryByTestId('pp-duration-columnheader')).not.toBeInTheDocument()
    expect(queryByTestId('pp-due-date-columnheader')).not.toBeInTheDocument()
    expect(queryByTestId('pp-status-columnheader')).not.toBeInTheDocument()
  })

  it('does not show due date column header when hiding projections', () => {
    const {queryByRole, queryByTestId} = renderConnected(
      <Module {...defaultProps} showProjections={false} />
    )
    expect(queryByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(queryByTestId('pp-duration-columnheader')).toBeInTheDocument()
    expect(queryByTestId('pp-due-date-columnheader')).not.toBeInTheDocument()
    expect(queryByTestId('pp-status-columnheader')).toBeInTheDocument()
  })

  it('displays headers and values in stacked format when at small screen sizes', () => {
    const {queryByRole, queryAllByTestId} = renderConnected(
      <Module {...defaultProps} responsiveSize="small" showProjections={true} />
    )
    expect(queryByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(queryByRole('columnheader')).not.toBeInTheDocument()
    expect(queryAllByTestId('pp-title-cell')[0].textContent).toEqual(
      'Item: Basic encryption/decryption100 pts'
    )
    expect(queryAllByTestId('pp-duration-cell')[0]).toBeInTheDocument()
    expect(queryAllByTestId('pp-due-date-cell')[1].textContent).toEqual(
      'Due DateToggle tooltip: Tue, Mar 22, 2022'
    )
    expect(queryAllByTestId('pp-status-cell')[0].textContent).toEqual('Status: Published')
  })

  it('includes the compressed dates warning tooltip if compressing', () => {
    const {getByRole} = renderConnected(<Module {...defaultProps} compression={1000} />)
    expect(
      getByRole('tooltip', {
        name: 'Due Dates are being compressed based on your start and end dates',
      })
    ).toBeInTheDocument()
  })

  it('includes a tooltip for days change', () => {
    const {getByRole} = renderConnected(<Module {...defaultProps} />)
    expect(
      getByRole('tooltip', {
        name: 'Changing course pacing days may modify due dates',
      })
    ).toBeInTheDocument()
  })

  it('renders a tooltip about date time zone', () => {
    const {getByRole} = renderConnected(<Module {...defaultProps} />)
    expect(
      getByRole('tooltip', {
        name: 'Dates shown in Course Time Zone',
      })
    ).toBeInTheDocument()
  })

  it('In stacked format, blackout dates do not include the status entry', () => {
    const module2 = {
      ...module1,
      items: [...module1.items],
      itemsWithDates: [...module1.itemsWithDates],
    }
    module2.itemsWithDates.splice(1, 0, {
      type: 'blackout_date' as const,
      date: moment('2022-03-20T00:00:00-06:00'),
      event_title: 'black me out',
      start_date: moment('2022-03-21T00:00:00-06:00'),
      end_date: moment('2022-03-22T00:00:00-06:00'),
    })

    const {queryAllByRole, queryAllByTestId} = renderConnected(
      <Module {...defaultProps} module={module2} responsiveSize="small" showProjections={true} />
    )
    expect(queryAllByRole('row').length).toEqual(3)
    expect(queryAllByTestId('pp-status-cell').length).toEqual(2)
  })
})
