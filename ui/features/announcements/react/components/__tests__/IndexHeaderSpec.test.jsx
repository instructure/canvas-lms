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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import IndexHeader from '../IndexHeader'
import fakeENV from '@canvas/test-utils/fakeENV'

function makeProps() {
  return {
    applicationElement: () => document.getElementById('fixtures'),
    contextId: '1',
    contextType: 'course',
    deleteSelectedAnnouncements: jest.fn(),
    isBusy: false,
    permissions: {
      create: true,
      manage_course_content_edit: true,
      manage_course_content_delete: true,
      moderate: true,
    },
    searchAnnouncements: jest.fn(),
    selectedCount: 0,
    toggleSelectedAnnouncementsLock: jest.fn(),
    announcementsLocked: false,
    isToggleLocking: false,
    markAllAnnouncementRead: jest.fn(),
  }
}

// Making sure debounce is not making tests slow in CI, passed fn should fire instantly instead
jest.mock('lodash/debounce', () => jest.fn(fn => fn))

describe('"Add Announcement" button', () => {
  test('is present when the user has permission to create an announcement', () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)
    expect(
      screen.getByRole('link', {
        name: /add announcement/i,
      }),
    ).toBeInTheDocument()
  })

  test('is absent when the user does not have permission to create an announcement', () => {
    const props = makeProps()
    props.permissions.create = false
    render(<IndexHeader {...props} />)
    expect(
      screen.queryByRole('link', {
        name: /add announcement/i,
      }),
    ).not.toBeInTheDocument()
  })
})

describe('searching announcements', () => {
  test('calls the searchAnnouncements prop with searchInput value after debounce timeout', async () => {
    const spy = jest.fn()
    const props = makeProps()
    props.searchAnnouncements = spy
    render(<IndexHeader {...props} />)
    const input = screen.getByRole('textbox')
    await userEvent.type(input, 'foo')

    await waitFor(() => {
      expect(spy).toHaveBeenCalledWith(
        expect.objectContaining({
          term: 'foo',
        }),
      )
    })
  })
})

describe('"Announcement Filter" select', () => {
  beforeEach(() => {
    fakeENV.setup({
      FEATURES: {
        instui_nav: false,
      },
    })
  })

  afterEach(() => {
    fakeENV.teardown()
  })

  test('includes two options in the filter select component', async () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)

    const filterDDown = screen.getByRole('combobox', {name: 'Announcement Filter'})

    await userEvent.click(filterDDown)

    await waitFor(() => {
      expect(screen.getByText('All')).toBeInTheDocument()
      expect(screen.getByText('Unread')).toBeInTheDocument()
    })
  })

  test('includes two options in the filter select component with instui_nav enabled', async () => {
    fakeENV.setup({
      FEATURES: {
        instui_nav: true,
      },
    })

    const props = makeProps()
    render(<IndexHeader {...props} />)

    const filterButton = screen.getByRole('button', {name: 'Announcement Filter'})

    await userEvent.click(filterButton)

    await waitFor(() => {
      expect(screen.getByText('All Announcements')).toBeInTheDocument()
      expect(screen.getByText('Unread Announcements')).toBeInTheDocument()
    })
  })

  test('calls the searchAnnouncements prop when selecting a filter option with the selected value', async () => {
    const spy = jest.fn()
    const props = makeProps()
    props.searchAnnouncements = spy
    render(<IndexHeader {...props} />)

    const filterDDown = screen.getByRole('combobox', {name: 'Announcement Filter'})

    await userEvent.click(filterDDown)

    await userEvent.click(screen.getByText(/Unread/i))

    await waitFor(() => {
      expect(spy).toHaveBeenCalledWith(
        expect.objectContaining({
          filter: 'unread',
        }),
      )
    })
  })
})

describe('"Lock Selected Announcements" button', () => {
  test('is present when the user has permission to lock announcements', () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)

    expect(screen.getByText(/unlock selected announcements/i)).toBeInTheDocument()
  })

  test('is absent when the user does not have permission to lock announcements', () => {
    const props = makeProps()
    props.permissions.manage_course_content_edit = false
    render(<IndexHeader {...props} />)
    expect(screen.queryByText(/unlock selected announcements/i)).not.toBeInTheDocument()
  })

  test('is absent when announcements are globally locked', () => {
    const props = makeProps()
    props.announcementsLocked = true
    render(<IndexHeader {...props} />)
    expect(screen.queryByText(/unlock selected announcements/i)).not.toBeInTheDocument()
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    render(<IndexHeader {...props} />)
    expect(screen.getByTestId('lock_announcements')).toBeDisabled()
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    render(<IndexHeader {...props} />)
    expect(screen.getByTestId('lock_announcements')).toBeDisabled()
  })

  test('calls the toggleSelectedAnnouncementsLock prop when clicked', async () => {
    const props = makeProps()
    props.selectedCount = 1
    render(<IndexHeader {...props} />)
    await userEvent.click(screen.getByTestId('lock_announcements'))

    waitFor(() => {
      expect(props.toggleSelectedAnnouncementsLock).toHaveBeenCalledTimes(1)
    })
  })
})

describe('"Delete Selected Announcements" button', () => {
  test('is present when the user has permission to delete announcements', () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)
    expect(screen.getByTestId('delete-announcements-button')).toBeInTheDocument()
  })

  test('is absent when the user does not have permission to delete announcements', () => {
    const props = makeProps()
    props.permissions.manage_course_content_delete = false
    render(<IndexHeader {...props} />)
    expect(screen.queryByTestId('delete-announcements-button')).not.toBeInTheDocument()
  })

  test('is disabled when "isBusy" is true', () => {
    const props = makeProps()
    props.isBusy = true
    render(<IndexHeader {...props} />)
    expect(screen.getByTestId('delete-announcements-button')).toBeDisabled()
  })

  test('is disabled when "selectedCount" is 0', () => {
    const props = makeProps()
    props.selectedCount = 0
    render(<IndexHeader {...props} />)
    expect(screen.getByTestId('delete-announcements-button')).toBeDisabled()
  })

  // see VICE-4352
  test.skip('shows the "Confirm Delete" modal when clicked', async () => {
    const props = makeProps()
    props.selectedCount = 1
    const ref = React.createRef()
    render(<IndexHeader {...props} ref={ref} />)
    const delButton = screen.getByTestId('delete-announcements-button')
    await userEvent.click(delButton)

    expect(
      screen.getByRole('heading', {
        name: /confirm delete/i,
      }),
    ).toBeInTheDocument()
  })
})

describe('"Mark all announcement read" button', () => {
  it('calls the markAllAnnouncementRead prop when clicked', async () => {
    const props = makeProps()
    render(<IndexHeader {...props} />)
    await userEvent.click(screen.getByTestId('mark-all-announcement-read'))

    expect(props.markAllAnnouncementRead).toHaveBeenCalledTimes(1)
  })
})
