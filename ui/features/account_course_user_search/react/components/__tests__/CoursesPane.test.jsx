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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import CoursesPane from '../CoursesPane'
import CoursesStore from '../../store/CoursesStore'
import TermsStore from '../../store/TermsStore'
import AccountsTreeStore from '../../store/AccountsTreeStore'

const stores = [CoursesStore, TermsStore, AccountsTreeStore]

describe('Account Course User Search CoursesPane View', () => {
  beforeEach(() => {
    stores.forEach(store => store.reset({accountId: '1'}))
    jest.useFakeTimers()
  })

  afterEach(() => {
    stores.forEach(store => store.reset({}))
    jest.useRealTimers()
  })

  const renderComponent = () => {
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
    const user = userEvent.setup({delay: null})

    // Mock the CoursesStore.load method to track calls
    const loadSpy = jest.spyOn(CoursesStore, 'load')

    // Find search input and type in it
    const searchInput = getByPlaceholderText('Search courses...')
    await user.type(searchInput, 'test course')

    // Advance timers to trigger debounced function
    jest.advanceTimersByTime(500)

    await waitFor(() => {
      expect(loadSpy).toHaveBeenCalled()
    })

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
