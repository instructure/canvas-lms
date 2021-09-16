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

import {PLAN_MODULE_1, PRIMARY_PLAN} from '../../../__tests__/fixtures'
import {renderConnected} from '../../../__tests__/utils'

import {Module} from '../module'

const defaultProps = {
  index: 1,
  module: PLAN_MODULE_1,
  pacePlan: PRIMARY_PLAN,
  showProjections: true
}

describe('Module', () => {
  it('is expanded by default, shows the module name always, and only shows column headers when expanded', () => {
    const {getByRole, queryByRole, queryByText} = renderConnected(<Module {...defaultProps} />)
    const moduleHeader = getByRole('button', {name: '1. How 2 B A H4CK32 Days Due Date Status'})
    expect(moduleHeader).toBeInTheDocument()
    expect(queryByText(PLAN_MODULE_1.items[0].assignment_title)).toBeInTheDocument()

    act(() => moduleHeader.click())
    expect(
      queryByRole('button', {name: '1. How 2 B A H4CK32 Days Due Date Status'})
    ).not.toBeInTheDocument()
    expect(queryByText(PLAN_MODULE_1.items[0].assignment_title)).not.toBeInTheDocument()
    expect(getByRole('button', {name: '1. How 2 B A H4CK32'})).toBeInTheDocument()
  })

  it('does not show due date column header when hiding projections', () => {
    const {queryByRole} = renderConnected(<Module {...defaultProps} showProjections={false} />)
    expect(
      queryByRole('button', {name: '1. How 2 B A H4CK32 Days Due Date Status'})
    ).not.toBeInTheDocument()
    expect(queryByRole('button', {name: '1. How 2 B A H4CK32 Days Status'})).toBeInTheDocument()
  })
})
