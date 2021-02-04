/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ManageOutcomesView from '../ManageOutcomesView'
import {outcomeGroup} from './mocks'

describe('ManageOutcomesView', () => {
  let onSelectOutcomesHandler
  let onOutcomeGroupMenuHandler
  let onOutcomeMenuHandler
  let onSearchChangeHandler
  let onSearchClearHandler
  const defaultProps = (props = {}) => ({
    outcomeGroup,
    selectedOutcomes: {'1': true},
    searchString: 'abc',
    onSelectOutcomesHandler,
    onOutcomeGroupMenuHandler,
    onOutcomeMenuHandler,
    onSearchChangeHandler,
    onSearchClearHandler,
    ...props
  })

  beforeEach(() => {
    onSelectOutcomesHandler = jest.fn()
    onOutcomeGroupMenuHandler = jest.fn()
    onOutcomeMenuHandler = jest.fn()
    onSearchChangeHandler = jest.fn()
    onSearchClearHandler = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders group title but no list of outcomes if outcomeGroup prop provided with id, title but no children', () => {
    const {queryByTestId} = render(
      <ManageOutcomesView {...defaultProps({outcomeGroup: {id: '1', title: 'Group Title'}})} />
    )
    expect(queryByTestId('outcome-group-container')).toBeInTheDocument()
    expect(queryByTestId('outcome-items-list')).not.toBeInTheDocument()
  })

  it('renders list of outcomes if outcomeGroup prop provided with id, title and children', () => {
    const {queryByTestId} = render(<ManageOutcomesView {...defaultProps()} />)
    expect(queryByTestId('outcome-group-container')).toBeInTheDocument()
    expect(queryByTestId('outcome-items-list')).toBeInTheDocument()
  })
})
