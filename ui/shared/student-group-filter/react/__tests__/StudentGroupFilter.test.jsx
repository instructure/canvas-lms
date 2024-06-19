/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, cleanup, screen} from '@testing-library/react'
import StudentGroupFilter from '../index'
import '@testing-library/jest-dom/extend-expect'

describe('StudentGroupFilter', () => {
  let context

  const renderComponent = (props = {}) => {
    render(<StudentGroupFilter {...context} {...props} />)
  }

  const getOptions = () => {
    return [...screen.getByRole('combobox').querySelectorAll('option')]
  }

  const getSelect = () => {
    return screen.getByRole('combobox')
  }

  beforeEach(() => {
    context = {
      categories: [
        {
          groups: [{id: '2101', name: 'group 1'}],
          id: '1101',
          name: 'group category 1',
        },
      ],
      label: 'Select a student group',
      onChange: jest.fn(),
      value: '2101',
    }
  })

  afterEach(() => {
    cleanup()
  })

  test('renders a select', () => {
    renderComponent()
    expect(getSelect()).toBeInTheDocument()
  })

  test('renders the group categories', () => {
    renderComponent()
    const categories = [...screen.getAllByRole('group')].map(category => category.label)
    expect(categories).toEqual(['group category 1'])
  })

  test('renders the groups', () => {
    renderComponent()
    const groups = getOptions().map(option => option.textContent)
    expect(groups).toEqual(['Select One', 'group 1'])
  })

  test('the "Select One" option is disabled', () => {
    renderComponent()
    const option = getOptions().find(opt => opt.textContent === 'Select One')
    expect(option).toBeDisabled()
  })

  test('the "Select One" option has a value of "0"', () => {
    renderComponent()
    const option = getOptions().find(opt => opt.textContent === 'Select One')
    expect(option).toHaveValue('0')
  })

  test('select is set to value that is passed in', () => {
    renderComponent()
    expect(getSelect().value).toBe('2101')
  })

  test('select is set to value "0" when no value is passed in', () => {
    renderComponent({value: null})
    expect(getSelect().value).toBe('0')
  })
})
