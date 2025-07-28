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
import PastGlobalAnnouncements from '../PastGlobalAnnouncements'
import {render, fireEvent} from '@testing-library/react'
import fakeENV from '@canvas/test-utils/fakeENV'

describe('past_global_announcements::pastGlobalAnnouncements', () => {
  describe('render announcements', () => {
    beforeEach(() => {
      fakeENV.setup({
        global_notifications: {
          current: ['<div><p>This is an active announcement</p></div>'],
          past: ['<div><p>This is a past announcement</p></div>'],
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('checks that the document contains active announcements', () => {
      const {getByText} = render(<PastGlobalAnnouncements />)
      expect(getByText('This is an active announcement')).toBeVisible()
    })

    it('checks that the document contains past announcements', async () => {
      const {findByText} = render(<PastGlobalAnnouncements />)
      fireEvent.click(await findByText('Recent'))
      expect(await findByText('This is a past announcement')).toBeVisible()
    })
  })

  describe('render image if there are no announcements', () => {
    beforeEach(() => {
      fakeENV.setup({
        global_notifications: {
          current: [],
          past: [],
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('checks that a dessert svg is rendered in the current section', async () => {
      const {findByTestId} = render(<PastGlobalAnnouncements />)
      expect(await findByTestId('NoGlobalAnnouncementImageCurrent')).toBeVisible()
    })

    it('checks that a dessert svg is rendered in the past section', async () => {
      const {findByTestId, findByText} = render(<PastGlobalAnnouncements />)
      fireEvent.click(await findByText('Recent'))
      expect(await findByTestId('NoGlobalAnnouncementImagePast')).toBeVisible()
    })
  })

  describe('pagination', () => {
    it('checks paging for current section is working', async () => {
      fakeENV.setup({
        global_notifications: {
          current: [
            '<div><p>This is current page one</p></div>',
            '<div><p>This is current page two</p></div>',
          ],
          past: [],
        },
      })

      const {findByText} = render(<PastGlobalAnnouncements />)
      expect(await findByText('This is current page one')).toBeVisible()
      fireEvent.click(await findByText('2'))
      expect(await findByText('This is current page two')).toBeVisible()

      fakeENV.teardown()
    })

    it('checks paging for past section is working', async () => {
      fakeENV.setup({
        global_notifications: {
          current: [],
          past: [
            '<div><p>This is past page one</p></div>',
            '<div><p>This is past page two</p></div>',
          ],
        },
      })

      const {findByText} = render(<PastGlobalAnnouncements />)
      fireEvent.click(await findByText('Recent'))
      expect(await findByText('This is past page one')).toBeVisible()
      fireEvent.click(await findByText('2'))
      expect(await findByText('This is past page two')).toBeVisible()

      fakeENV.teardown()
    })
  })

  describe('with instui_nav feature flag on', () => {
    beforeEach(() => {
      fakeENV.setup({
        FEATURES: {
          instui_nav: true,
        },
        global_notifications: {
          current: [],
          past: [],
        },
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('checks that SimpleSelect is displayed for lower resolution', () => {
      const {getByTestId} = render(<PastGlobalAnnouncements breakpoints={{mobileOnly: true}} />)
      expect(getByTestId('GlobalAnnouncementSelect')).toBeVisible()
    })

    it('checks that Tabs are displayed for higher resolutions', () => {
      const {getByTestId} = render(<PastGlobalAnnouncements breakpoints={{desktop: true}} />)
      expect(getByTestId('GlobalAnnouncementTabs')).toBeVisible()
    })

    it('checks that the "Global Announcements" header is visible', () => {
      const {getByText} = render(<PastGlobalAnnouncements breakpoints={{desktop: true}} />)
      expect(getByText('Global Announcements')).toBeVisible()
    })
  })
})
