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

describe('past_global_announcements::pastGlobalAnnouncements', () => {
  describe('render announcements', () => {
    beforeAll(() => {
      window.ENV.global_notifications = {
        current: ['<div><p>This is an active announcement</p></div>'],
        past: ['<div><p>This is a past announcement</p></div>'],
      }
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
    beforeAll(() => {
      window.ENV.global_notifications = {
        current: [],
        past: [],
      }
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
      window.ENV.global_notifications = {
        current: [
          '<div><p>This is current page one</p></div>',
          '<div><p>This is current page two</p></div>',
        ],
        past: [],
      }
      const {findByText} = render(<PastGlobalAnnouncements />)
      expect(await findByText('This is current page one')).toBeVisible()
      fireEvent.click(await findByText('2'))
      expect(await findByText('This is current page two')).toBeVisible()
    })

    it('checks paging for past section is working', async () => {
      window.ENV.global_notifications = {
        current: [],
        past: [
          '<div><p>This is past page one</p></div>',
          '<div><p>This is past page two</p></div>',
        ],
      }
      const {findByText} = render(<PastGlobalAnnouncements />)
      fireEvent.click(await findByText('Recent'))
      expect(await findByText('This is past page one')).toBeVisible()
      fireEvent.click(await findByText('2'))
      expect(await findByText('This is past page two')).toBeVisible()
    })
  })
})
