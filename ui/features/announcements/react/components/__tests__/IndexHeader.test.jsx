/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import '@instructure/canvas-theme'
import React from 'react'
import {render, screen} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import IndexHeader from '../IndexHeader'

const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

const defaultPermissions = () => ({
  create: false,
  manage_course_content_edit: false,
  manage_course_content_delete: false,
  moderate: false,
})

const defaultProps = () => ({
  contextType: 'course',
  contextId: 'c1',
  isBusy: false,
  selectedCount: 0,
  isToggleLocking: false,
  permissions: defaultPermissions(),
  atomFeedUrl: null,
  searchAnnouncements: () => Promise.reject(new Error('Not Implemented')),
  toggleSelectedAnnouncementsLock: () => Promise.reject(new Error('Not Implemented')),
  deleteSelectedAnnouncements: () => Promise.reject(new Error('Not Implemented')),
  searchInputRef: null,
  announcementsLocked: false,
  markAllAnnouncementRead: jest.fn(),
})

describe('IndexHeader', () => {
  it('renders', () => {
    expect(() => {
      render(<IndexHeader {...defaultProps()} />)
    }).not.toThrow()
  })

  it('does not render title', () => {
    render(<IndexHeader {...defaultProps()} />)
    expect(screen.queryByText('All Announcements')).not.toBeInTheDocument()
  })

  it('does not render icon dropdown next to title', () => {
    render(<IndexHeader {...defaultProps()} />)
    expect(screen.queryByRole('button', {name: 'Announcement Filter'})).not.toBeInTheDocument()
  })

  it('renders filter dropdown', () => {
    render(<IndexHeader {...defaultProps()} />)
    expect(screen.getByRole('combobox', {name: 'Announcement Filter'})).toBeInTheDocument()
  })

  it('lets me add an announcement when I have the permission', () => {
    render(
      <IndexHeader {...defaultProps()} permissions={{...defaultPermissions(), create: true}} />
    )
    expect(screen.getByText('Add announcement')).toBeInTheDocument()
  })

  it('lets me lock an announcement when I have the permission and it is unlocked', () => {
    render(
      <IndexHeader
        {...defaultProps()}
        isToggleLocking={true}
        permissions={{...defaultPermissions(), manage_course_content_edit: true}}
      />
    )
    expect(screen.getByText('Lock Selected Announcements')).toBeInTheDocument()
  })

  it('lets me unlock an announcement when I have the permission and it is locked', () => {
    render(
      <IndexHeader
        {...defaultProps()}
        permissions={{...defaultPermissions(), manage_course_content_edit: true}}
      />
    )
    expect(screen.getByText('Unlock Selected Announcements')).toBeInTheDocument()
  })

  it('lets me delete an announcement when I have the permission', () => {
    render(
      <IndexHeader
        {...defaultProps()}
        permissions={{...defaultPermissions(), manage_course_content_delete: true}}
      />
    )
    expect(screen.getByText('Delete Selected Announcements')).toBeInTheDocument()
  })

  describe('instui_nav feature flag is enabled', () => {
    const oldEnv = window.ENV

    beforeAll(() => {
      window.ENV = {FEATURES: {instui_nav: true}}
    })

    afterAll(() => {
      window.ENV = oldEnv
    })

    it('renders title', () => {
      render(<IndexHeader {...defaultProps()} />)
      expect(screen.getByText('All Announcements')).toBeInTheDocument()
    })

    it('renders icon dropdown next to title', () => {
      render(<IndexHeader {...defaultProps()} />)
      expect(screen.getByRole('button', {name: 'Announcement Filter'})).toBeInTheDocument()
    })

    it('renders different title when another filter is selected from dropdown', async () => {
      render(<IndexHeader {...defaultProps()} />)
      expect(screen.queryByText('Unread Announcements')).not.toBeInTheDocument()

      const filterButton = screen.getByRole('button', {name: 'Announcement Filter'})
      await user.click(filterButton)

      const filterMenu = screen.getAllByRole('menu')[1]
      const allKeys = filterMenu.querySelectorAll('li')
      expect(allKeys.length).toBe(2)

      await user.click(allKeys[1])
      expect(screen.getByText('Unread Announcements')).toBeInTheDocument()
    })
  })
})
