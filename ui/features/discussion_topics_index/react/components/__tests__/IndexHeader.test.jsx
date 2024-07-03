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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import IndexHeader from '../IndexHeader'
import merge from 'lodash/merge'

const user = userEvent.setup()

describe('IndexHeader', () => {
  const makeProps = (props = {}) =>
    merge(
      {
        contextType: 'course',
        contextId: '1',
        userSettings: {mark_as_read: true},
        isSavingSettings: false,
        isSettingsModalOpen: false,
        fetchUserSettings: () => {},
        fetchCourseSettings: () => {},
        saveSettings: () => {},
        searchDiscussions: () => {},
        toggleModalOpen: () => {},
        permissions: {
          create: true,
          manage_content: true,
          moderate: true,
        },
        isBusy: false,
        selectedCount: 0,
        applicationElement: () => document.getElementById('fixtures'),
      },
      props
    )

  it('renders the component', () => {
    expect(() => {
      render(<IndexHeader {...makeProps()} />)
    }).not.toThrow()
  })

  it('renders the search input', () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)
    expect(screen.getByPlaceholderText('Search...')).toBeInTheDocument()
  })

  it('renders the filter input', () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)
    expect(screen.getByRole('combobox')).toBeInTheDocument()
  })

  it('renders create discussion button if we have create permissions', () => {
    render(<IndexHeader {...makeProps({permissions: {create: true}})} />)
    expect(screen.getByText('Add discussion')).toBeInTheDocument()
  })

  it('does not render create discussion button if we do not have create permissions', () => {
    render(<IndexHeader {...makeProps({permissions: {create: false}})} />)
    expect(screen.queryByText('Add discussion')).not.toBeInTheDocument()
  })

  it('renders discussionSettings', () => {
    render(<IndexHeader {...makeProps()} />)
    expect(screen.getByText('Discussion Settings')).toBeInTheDocument()
  })

  it('calls onFilterChange when entering a search term', async () => {
    const searchMock = jest.fn()
    const props = makeProps({searchDiscussions: searchMock()})

    render(<IndexHeader {...props} />)
    const input = screen.getByPlaceholderText('Search...')
    user.type(input, 'foobar')

    await waitFor(() => expect(searchMock).toHaveBeenCalled())
  })

  it('calls onFilterChange when selecting a new filter', async () => {
    const filterMock = jest.fn()
    const props = makeProps({searchDiscussions: filterMock()})

    render(<IndexHeader {...props} />)

    const filterDDown = screen.getByRole('combobox', {name: 'Discussion Filter'})

    await userEvent.click(filterDDown)

    const secondOption = screen.getByText(/Unread/i)

    expect(screen.getByText(/All/i)).toBeInTheDocument()
    expect(secondOption).toBeInTheDocument()

    await userEvent.click(secondOption)

    await waitFor(() => {
      return expect(filterMock).toHaveBeenCalledWith()
    })
  })

  describe('instui_nav feature flag is enabled', () => {
    const oldEnv = window.ENV

    beforeEach(() => {
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterEach(() => {
      window.ENV = oldEnv
    })

    it('renders title', () => {
      render(<IndexHeader {...makeProps()} />)
      expect(screen.getByText('All Discussions')).toBeInTheDocument()
    })
  })
})
