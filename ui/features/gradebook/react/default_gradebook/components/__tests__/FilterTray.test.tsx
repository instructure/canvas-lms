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
import FilterTray from '../FilterTray'
import fetchMock from 'fetch-mock'
import store from '../../stores/index'
import type {FilterTrayProps} from '../FilterTray'
import type {FilterPreset, Filter} from '../../gradebook.d'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import '@testing-library/jest-dom/extend-expect'

const originalState = store.getState()

const defaultFilterPresets: FilterPreset[] = [
  {
    id: '1',
    name: 'Filter Preset 1',
    filters: [
      {
        id: '2',
        type: 'module',
        value: '1',
        created_at: '2022-02-05T10:18:34-07:00',
      },
    ],
    created_at: '2022-02-05T10:18:34-07:00',
    updated_at: '2022-02-05T10:18:34-07:00',
  },
  {
    id: 'preset-2',
    name: 'Filter Preset 2',
    filters: [
      {
        id: '3',
        type: 'section',
        value: '7',
        created_at: new Date().toISOString(),
      },
      {
        id: '4',
        type: 'section',
        value: '8',
        created_at: new Date().toISOString(),
      },
    ],
    created_at: '2022-02-06T10:18:34-07:00',
    updated_at: '2022-02-06T10:18:34-07:00',
  },
]

const defaultAppliedFilters: Filter[] = [
  {
    id: '2',
    type: 'module',
    value: '1',
    created_at: new Date().toISOString(),
  },
]

const defaultProps: FilterTrayProps = {
  isTrayOpen: true,
  setIsTrayOpen: () => {},
  filterPresets: defaultFilterPresets,
  modules: [],
  assignmentGroups: [],
  sections: [],
  gradingPeriods: [],
  studentGroupCategories: {},
}

describe('FilterTray', () => {
  beforeEach(() => {
    store.setState({
      filterPresets: defaultFilterPresets,
      appliedFilters: defaultAppliedFilters,
    })
    fetchMock.mock('*', 200)
  })
  afterEach(() => {
    store.setState(originalState, true)
    fetchMock.restore()
  })

  it('Header shows for saved filter presets', () => {
    const {getByText} = render(<FilterTray {...defaultProps} />)
    expect(getByText('Saved Filter Presets', {selector: 'h3'})).toBeInTheDocument()
  })

  it('Pressing close button triggers setIsTrayOpen', () => {
    const setIsTrayOpen = jest.fn()
    const {getByText} = render(<FilterTray {...defaultProps} setIsTrayOpen={setIsTrayOpen} />)
    expect(getByText('Saved Filter Presets', {selector: 'h3'})).toBeVisible()
    userEvent.click(getByText('Close', {selector: 'span'}))
    expect(setIsTrayOpen).toHaveBeenCalledWith(false)
  })

  it('renders new filter button', () => {
    const {getByText} = render(<FilterTray {...defaultProps} />)
    expect(getByText('Toggle Create Filter Preset')).toBeVisible()
  })

  it('Pressing expand toggles open/close a filter', () => {
    const {getByText, queryByText} = render(<FilterTray {...defaultProps} />)
    expect(queryByText('Filter preset name', {selector: 'span'})).toBeNull()
    userEvent.click(getByText('Toggle Filter Preset 1', {selector: 'span'})) // button
    expect(queryByText('Filter preset name', {selector: 'span'})).toBeVisible()
    userEvent.click(getByText('Toggle Filter Preset 1', {selector: 'span'})) // button
    expect(queryByText('Filter preset name', {selector: 'span'})).toBeNull()
  })

  it('Shows filter count subheading', () => {
    const {getByText} = render(<FilterTray {...defaultProps} />)
    expect(getByText('2 Filters', {selector: 'span'})).toBeInTheDocument()
  })
})
