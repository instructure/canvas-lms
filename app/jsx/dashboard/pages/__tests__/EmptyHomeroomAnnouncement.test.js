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
import {render} from '@testing-library/react'
import EmptyHomeroomAnnouncement from '../EmptyHomeroomAnnouncement'

describe('EmptyHomeroomAnnouncement', () => {
  const getProps = (overrides = {}) => ({
    courseName: "Mr. Smith's Homeroom 2",
    courseUrl: 'http://google.com/courseurl2',
    ...overrides
  })

  it('renders link to homeroom course', async () => {
    const {findByText} = render(<EmptyHomeroomAnnouncement {...getProps()} />)
    const courseName = await findByText("Mr. Smith's Homeroom 2")
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBe('http://google.com/courseurl2')
  })

  it('shows some helpful text', async () => {
    const {findByText} = render(<EmptyHomeroomAnnouncement {...getProps()} />)
    expect(
      await findByText('Every new announcement shows up in this area. Create your first one now.')
    ).toBeInTheDocument()
  })

  it('shows a button to create a new announcement with correct url', async () => {
    const {findByText} = render(<EmptyHomeroomAnnouncement {...getProps()} />)
    const button = await findByText('Announcement')
    expect(button).toBeInTheDocument()
    expect(button.closest('a').href).toBe(
      'http://google.com/courseurl2/discussion_topics/new?is_announcement=true'
    )
  })
})
