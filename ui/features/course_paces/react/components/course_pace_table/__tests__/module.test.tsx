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

import {PACE_MODULE_1, PRIMARY_PACE} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {Module} from '../module'

const defaultProps = {
  index: 1,
  module: PACE_MODULE_1,
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
      queryByRole('cell', {name: 'Assignments : Basic encryption/decryption 100 pts'})
    ).toBeInTheDocument()
    expect(queryAllByTestId('pp-duration-cell')[0]).toBeInTheDocument()
    expect(queryByRole('cell', {name: 'Due Date : Fri, Sep 3, 2021'})).toBeInTheDocument()
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
})
