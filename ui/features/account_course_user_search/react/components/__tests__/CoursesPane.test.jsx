/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CoursesPane from '../CoursesPane'
import CoursesStore from '../../store/CoursesStore'
import TermsStore from '../../store/TermsStore'
import AccountsTreeStore from '../../store/AccountsTreeStore'

const stores = [CoursesStore, TermsStore, AccountsTreeStore]

describe('Account Course User Search CoursesPane View', () => {
  beforeEach(() => {
    stores.forEach(store => store.reset({accountId: '1'}))
    vi.useFakeTimers()
  })

  afterEach(() => {
    stores.forEach(store => store.reset({}))
    vi.useRealTimers()
    // Clean up any mock elements
    const mockElement = document.getElementById('flash_screenreader_holder')
    if (mockElement) {
      mockElement.remove()
    }
  })

  const renderComponent = () => {
    // Mock the live alert region to prevent warning about screenReaderOnly requiring liveRegion
    const mockDiv = document.createElement('div')
    mockDiv.id = 'flash_screenreader_holder'
    mockDiv.setAttribute('role', 'alert')
    document.body.appendChild(mockDiv)

    return render(
      <CoursesPane
        accountId="1"
        roles={[{id: '1'}]}
        queryParams={{}}
        onUpdateQueryParams={function () {}}
      />,
    )
  }

  test('onUpdateFilters triggers debounced apply filters', async () => {
    const {getByPlaceholderText} = renderComponent()

    // Mock the CoursesStore.load method to return a resolved promise
    const loadSpy = vi.spyOn(CoursesStore, 'load').mockResolvedValue()

    // Find search input and change its value
    const searchInput = getByPlaceholderText('Search courses...')

    await act(async () => {
      fireEvent.change(searchInput, {target: {value: 'test course'}})
    })

    // Advance timers to trigger debounced function (750ms debounce time)
    await act(async () => {
      vi.advanceTimersByTime(750)
    })

    // Verify the load method was called
    expect(loadSpy).toHaveBeenCalled()

    loadSpy.mockRestore()
  })

  test('it loads more terms at once', () => {
    renderComponent()
    const termsStore = stores.find(s => s.jsonKey === 'enrollment_terms')
    expect(termsStore.lastParams).toHaveProperty('per_page', 100)
  })

  test('have an h1 on the page', () => {
    const {getByRole} = renderComponent()
    expect(getByRole('heading', {level: 1, name: 'Courses'})).toBeInTheDocument()
  })
})
