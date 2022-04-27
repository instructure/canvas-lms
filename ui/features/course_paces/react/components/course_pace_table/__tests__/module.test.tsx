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
import {act, getByText} from '@testing-library/react'
import moment from 'moment'

import {PACE_MODULE_1, PRIMARY_PACE} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {Module} from '../module'
import {ModuleWithDueDates, CoursePaceItemWithDate} from '../../../types'

const dueDates = ['2022-03-18T00:00:00-06:00', '2022-03-22T00:00:00-06:00']
const module1: ModuleWithDueDates = {...(PACE_MODULE_1 as unknown as ModuleWithDueDates)}
module1.items = module1.items.map(
  (item, index) =>
    ({
      ...item,
      type: 'assignment' as const,
      date: moment(dueDates[index])
    } as CoursePaceItemWithDate)
)

const defaultProps = {
  index: 1,
  module: module1,
  coursePace: PRIMARY_PACE,
  responsiveSize: 'large' as const,
  showProjections: true,
  compression: 0
}

describe('Module', () => {
  it('is expanded by default, shows the module name always, and only shows column headers when expanded', () => {
    const {getByRole, queryByRole, queryByText, queryByTestId} = renderConnected(
      <Module {...defaultProps} />
    )
    const moduleHeader = getByRole('button', {name: '1. How 2 B A H4CK32'})
    expect(moduleHeader).toBeInTheDocument()
    expect(queryByText(PACE_MODULE_1.items[0].assignment_title)).toBeInTheDocument()
    expect(queryByTestId('pp-duration-columnheader')).toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Due Date'})).toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Status'})).toBeInTheDocument()

    act(() => moduleHeader.click())
    expect(getByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(queryByText(PACE_MODULE_1.items[0].assignment_title)).not.toBeInTheDocument()
    expect(queryByTestId('pp-duration-columnheader')).not.toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Due Date'})).not.toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Status'})).not.toBeInTheDocument()
  })

  it('does not show due date column header when hiding projections', () => {
    const {queryByRole, getByTestId} = renderConnected(
      <Module {...defaultProps} showProjections={false} />
    )
    expect(queryByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(getByTestId('pp-duration-columnheader')).toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Due Date'})).not.toBeInTheDocument()
    expect(queryByRole('columnheader', {name: 'Status'})).toBeInTheDocument()
  })

  it('displays headers and values in stacked format when at small screen sizes', () => {
    const {queryAllByRole, queryByRole, queryAllByTestId} = renderConnected(
      <Module {...defaultProps} responsiveSize="small" showProjections />
    )
    expect(queryByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
    expect(queryByRole('columnheader')).not.toBeInTheDocument()
    expect(
      queryByRole('cell', {name: 'Item : Basic encryption/decryption 100 pts'})
    ).toBeInTheDocument()
    expect(queryAllByTestId('pp-duration-cell')[0]).toBeInTheDocument()
    expect(queryByRole('cell', {name: 'Due Date : Tue, Mar 22, 2022'})).toBeInTheDocument()
    expect(queryAllByRole('cell', {name: 'Status : Published'})[0]).toBeInTheDocument()
  })

  it('includes the compressed dates warning tooltip if compressing', () => {
    const {getByRole} = renderConnected(<Module {...defaultProps} compression={1000} />)
    expect(
      getByRole('tooltip', {
        name: 'Due Dates are being compressed based on your start and end dates.'
      })
    ).toBeInTheDocument()
  })

  it('includes an info tooltip for days change', () => {
    const {getByRole} = renderConnected(<Module {...defaultProps} />)
    expect(
      getByRole('tooltip', {
        name: 'Changing course pacing days may modify due dates.'
      })
    ).toBeInTheDocument()
  })

  it('merges assignments and blackout dates in the table', () => {
    // the blackout dates fall between these 2 due dates
    const module2 = {...module1, items: [...module1.items]}
    module2.items.splice(1, 0, {
      type: 'blackout_date' as const,
      date: moment('2022-03-20T00:00:00-06:00'),
      event_title: 'black me out',
      start_date: moment('2022-03-21T00:00:00-06:00'),
      end_date: moment('2022-03-22T00:00:00-06:00')
    })

    const {getAllByRole} = renderConnected(<Module {...defaultProps} module={module2} />)

    const rows = getAllByRole('row')
    expect(rows.length).toEqual(4)
    expect(getByText(rows[1], 'Fri, Mar 18, 2022')).toBeInTheDocument()
    expect(getByText(rows[2], 'Mon, Mar 21, 2022')).toBeInTheDocument()
    expect(getByText(rows[2], 'Tue, Mar 22, 2022')).toBeInTheDocument()
    expect(getByText(rows[3], 'Tue, Mar 22, 2022')).toBeInTheDocument()
  })

  it('In stacked format, blackout dates do not include the status entry', () => {
    const module2 = {...module1, items: [...module1.items]}
    module2.items.splice(1, 0, {
      type: 'blackout_date' as const,
      date: moment('2022-03-20T00:00:00-06:00'),
      event_title: 'black me out',
      start_date: moment('2022-03-21T00:00:00-06:00'),
      end_date: moment('2022-03-22T00:00:00-06:00')
    })

    const {queryAllByRole} = renderConnected(
      <Module {...defaultProps} module={module2} responsiveSize="small" showProjections />
    )
    expect(queryAllByRole('row').length).toEqual(3)
    expect(queryAllByRole('cell', {name: /Status/}).length).toEqual(2)
  })
})
