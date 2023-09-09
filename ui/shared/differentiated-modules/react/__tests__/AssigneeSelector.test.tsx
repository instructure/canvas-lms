/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {act, render} from '@testing-library/react'
import AssigneeSelector, {OPTIONS} from '../AssigneeSelector'

describe('AssigneeSelector', () => {
  beforeAll(() => {
    if (!document.getElementById('flash_screenreader_holder')) {
      const liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }
  })

  const renderComponent = () => render(<AssigneeSelector />)

  it('renders', () => {
    const {getByTestId} = renderComponent()
    expect(getByTestId('assignee_selector')).toBeInTheDocument()
  })

  it('selects multiple options', () => {
    const {getByTestId, getByText, getAllByTestId} = renderComponent()
    act(() => getByTestId('assignee_selector').click())
    act(() => getByText(OPTIONS[0].value).click())
    act(() => getByTestId('assignee_selector').click())
    act(() => getByText(OPTIONS[2].value).click())
    expect(getAllByTestId('assignee_selector_option').length).toBe(2)
  })

  it('clears selection', () => {
    const {getByTestId, queryAllByTestId, getByText} = renderComponent()
    act(() => getByTestId('assignee_selector').click())
    act(() => getByText(OPTIONS[0].value).click())
    expect(queryAllByTestId('assignee_selector_option').length).toBe(1)
    act(() => getByTestId('clear_selection_button').click())
    expect(queryAllByTestId('assignee_selector_option').length).toBe(0)
  })
})
