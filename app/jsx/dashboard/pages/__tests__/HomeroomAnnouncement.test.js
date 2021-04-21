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
import HomeroomAnnouncement from '../HomeroomAnnouncement'

describe('HomeroomAnnouncement', () => {
  const getProps = (overrides = {}) => ({
    courseId: 123,
    courseName: "Mrs. Jensen's Homeroom",
    courseUrl: 'http://google.com/courseurl',
    canEdit: true,
    title: '20 minutes of weekly reading',
    message: '<p>You have this assignment due <strong>tomorrow</strong>!',
    url: 'http://google.com/url',
    attachment: {
      display_name: 'exam1.pdf',
      url: 'http://google.com/download',
      filename: '1608134586_366__exam1.pdf'
    },
    ...overrides
  })

  it('shows homeroom course title with underlying link for teachers', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps()} />)
    const courseName = await findByText("Mrs. Jensen's Homeroom")
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBe('http://google.com/courseurl')
  })

  it('shows homeroom course title with no link for students', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps({canEdit: false})} />)
    const courseName = await findByText("Mrs. Jensen's Homeroom")
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBeUndefined()
  })

  it('shows announcement title', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps()} />)
    expect(await findByText('20 minutes of weekly reading')).toBeInTheDocument()
  })

  it('shows announcement body with rich content', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps()} />)
    const announcementBody = await findByText('You have this assignment', {exact: false})
    expect(announcementBody).toBeInTheDocument()
    expect(announcementBody.innerHTML).toBe(
      'You have this assignment due <strong>tomorrow</strong>!'
    )
  })

  it('shows an edit button if teacher', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps()} />)
    expect(await findByText('Edit announcement 20 minutes of weekly reading')).toBeInTheDocument()
  })

  it('does not show an edit button if student', async () => {
    const {queryByText} = render(<HomeroomAnnouncement {...getProps({canEdit: false})} />)
    expect(
      await queryByText('Edit announcement 20 minutes of weekly reading')
    ).not.toBeInTheDocument()
  })

  it('shows the announcement attachment link if present', async () => {
    const {findByText} = render(<HomeroomAnnouncement {...getProps()} />)
    const courseName = await findByText('exam1.pdf')
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBe('http://google.com/download')
    expect(courseName.title).toBe('1608134586_366__exam1.pdf')
  })
})
