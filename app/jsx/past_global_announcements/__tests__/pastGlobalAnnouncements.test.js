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

import PastGlobalAnnouncements from '../PastGlobalAnnouncements'
import {render} from '@testing-library/react'
import React from 'react'

describe('render announcements', () => {
  beforeAll(() => {
    window.ENV.global_notifications = {
      active: '<div><p>This is an active announcement</p></div>',
      past: '<div><p>This is a past announcement</p></div>'
    }
  })

  it('checks that the document contains active announcements', () => {
    const {getByText} = render(<PastGlobalAnnouncements/>)
    expect(getByText('This is an active announcement')).toBeVisible()
  })

  it('checks that the document contains past announcements', () => {
    const {getByText} = render(<PastGlobalAnnouncements/>)
    expect(getByText('This is a past announcement')).toBeVisible()
  })
})
