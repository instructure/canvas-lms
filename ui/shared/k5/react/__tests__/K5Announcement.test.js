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
import fetchMock from 'fetch-mock'
import tz from '@canvas/timezone'
import {act, render, waitFor} from '@testing-library/react'
import K5Announcement from '../K5Announcement'

describe('K5Announcement', () => {
  const getCourseProps = overrides => ({
    courseId: '123',
    courseName: "Mrs. Jensen's Homeroom",
    courseUrl: 'http://google.com/courseurl',
    canEdit: true,
    published: true,
    showCourseDetails: true,
    ...overrides
  })

  const getProps = (courseOverrides = {}, anncOverrides = {}) => ({
    ...getCourseProps(courseOverrides),
    firstAnnouncement: {
      id: '17',
      title: '20 minutes of weekly reading',
      message: '<p>You have this assignment due <strong>tomorrow</strong>!',
      url: 'http://google.com/url',
      postedDate: new Date(),
      attachment: {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf'
      },
      ...anncOverrides
    }
  })

  it('shows homeroom course title with underlying link for teachers', () => {
    const {getByText} = render(<K5Announcement {...getProps()} />)
    const courseName = getByText("Mrs. Jensen's Homeroom")
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBe('http://google.com/courseurl')
  })

  it('shows homeroom course title with no link for students', () => {
    const {getByText} = render(<K5Announcement {...getProps({canEdit: false})} />)
    const courseName = getByText("Mrs. Jensen's Homeroom")
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBeUndefined()
  })

  it('shows announcement title with a link to the announcement', () => {
    const {getByText} = render(<K5Announcement {...getProps()} />)
    const announcementTitle = getByText('20 minutes of weekly reading')
    expect(announcementTitle).toBeInTheDocument()
    expect(announcementTitle.href).toBe('http://google.com/url')
  })

  it('shows announcement body with rich content', () => {
    const {getByText} = render(<K5Announcement {...getProps()} />)
    const announcementBody = getByText('You have this assignment', {exact: false})
    expect(announcementBody).toBeInTheDocument()
    expect(announcementBody.innerHTML).toBe(
      'You have this assignment due <strong>tomorrow</strong>!'
    )
  })

  it('shows an edit button if teacher', () => {
    const {getByText} = render(<K5Announcement {...getProps()} />)
    expect(getByText('Edit announcement 20 minutes of weekly reading')).toBeInTheDocument()
  })

  it('does not show an edit button if student', () => {
    const {queryByText} = render(<K5Announcement {...getProps({canEdit: false})} />)
    expect(queryByText('Edit announcement 20 minutes of weekly reading')).not.toBeInTheDocument()
  })

  it('shows the announcement attachment link if present', () => {
    const {getByText} = render(<K5Announcement {...getProps()} />)
    const courseName = getByText('exam1.pdf')
    expect(courseName).toBeInTheDocument()
    expect(courseName.href).toBe('http://google.com/download')
    expect(courseName.title).toBe('1608134586_366__exam1.pdf')
  })

  it('shows indicator if course is unpublished', () => {
    const {getByText} = render(<K5Announcement {...getProps({published: false})} />)
    expect(getByText('Your homeroom is currently unpublished.')).toBeInTheDocument()
  })

  it('does not show indicator if course is published', () => {
    const {queryByText} = render(<K5Announcement {...getProps()} />)
    expect(queryByText('Your homeroom is currently unpublished.')).not.toBeInTheDocument()
  })

  it('hides the course name but keeps the edit button if showCourseDetails is false', () => {
    const {getByRole, queryByText} = render(
      <K5Announcement {...getProps({showCourseDetails: false})} />
    )
    expect(queryByText("Mrs. Jensen's Homeroom")).not.toBeInTheDocument()
    expect(
      getByRole('link', {name: 'Edit announcement 20 minutes of weekly reading'})
    ).toBeInTheDocument()
  })

  it("doesn't show the unpublished indicator if showCourseDetails is false", () => {
    const {queryByText} = render(
      <K5Announcement {...getProps({published: false, showCourseDetails: false})} />
    )
    expect(queryByText('Your homeroom is currently unpublished.')).not.toBeInTheDocument()
  })

  it('shows the posted date if passed', async () => {
    const date = '2021-05-14T17:06:21-06:00'
    const {findByText} = render(<K5Announcement {...getProps({}, {postedDate: new Date(date)})} />)
    expect(await findByText(tz.format(date, 'date.formats.date_at_time'))).toBeInTheDocument()
  })

  describe('with inter-announcement navigation enabled', () => {
    beforeAll(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.k5_homeroom_many_announcements = true
    })
    afterEach(() => {
      fetchMock.restore()
    })
    it('does not show prev and next buttons if more announcements do not exist', async () => {
      fetchMock.get(
        /\/api\/v1\/announcements/,
        {
          body: '[]',
          headers: {
            Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"'
          }
        },
        {}
      )
      const date = '2021-05-14T17:06:21-06:00'
      const {getByText, queryByText} = render(
        <K5Announcement {...getProps({}, {postedDate: new Date(date)})} />
      )
      await waitFor(() => {}, {timeout: 10})
      expect(getByText('Edit announcement 20 minutes of weekly reading')).toBeInTheDocument()
      expect(queryByText('Previous announcement')).toBeNull()
      expect(queryByText('Next announcement')).toBeNull()
    })

    it('does shows prev and next buttons if more announcements exist', async () => {
      fetchMock.get(
        /\/api\/v1\/announcements/,
        {
          body: JSON.stringify([
            {
              id: '18',
              title: 'Announcement 2',
              message: 'Hello, I am announcement 2',
              html_url: '/courses/1/discussion_topics/18',
              posted_at: '2021-05-13T17:06:21-06:00',
              attachments: []
            }
          ]),
          headers: {
            Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"'
          }
        },
        {}
      )
      const date = '2021-05-14T17:06:21-06:00'
      const {getByText} = render(<K5Announcement {...getProps({}, {postedDate: new Date(date)})} />)
      await waitFor(() => {}, {timeout: 10})
      expect(getByText('Edit announcement 20 minutes of weekly reading')).toBeInTheDocument()
      expect(getByText('Previous announcement')).toBeInTheDocument()
      expect(getByText('Next announcement')).toBeInTheDocument()
    })

    it('does shows previous announcement if prev button is clicked', async () => {
      fetchMock.get(
        /\/api\/v1\/announcements/,
        {
          body: JSON.stringify([
            {
              id: '18',
              title: 'Announcement 2',
              message: 'Hello, I am announcement 2',
              html_url: '/courses/1/discussion_topics/18',
              posted_at: '2021-05-13T17:06:21-06:00',
              attachments: []
            }
          ]),
          headers: {
            Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"'
          }
        },
        {}
      )
      const date = '2021-05-14T17:06:21-06:00'
      const {findByText, getByText} = render(
        <K5Announcement {...getProps({}, {postedDate: new Date(date)})} />
      )
      await waitFor(() => {}, {timeout: 10})
      const prevBtn = getByText('Previous announcement').closest('button')
      const nextBtn = getByText('Next announcement').closest('button')
      await act(async () => {
        prevBtn.click()
        expect(await findByText('Announcement 2')).toBeInTheDocument()
        expect(prevBtn.hasAttribute('disabled')).toBeTruthy()
        expect(nextBtn.hasAttribute('disabled')).toBeFalsy()
      })
      await act(async () => {
        nextBtn.click()
        expect(await findByText('20 minutes of weekly reading')).toBeInTheDocument()
        expect(prevBtn.hasAttribute('disabled')).toBeFalsy()
        expect(nextBtn.hasAttribute('disabled')).toBeTruthy()
      })
    })

    describe('with no recent announcements', () => {
      let oldDate
      beforeEach(() => {
        oldDate = new Date()
        oldDate.setMonth(oldDate.getMonth() - 3)
      })

      describe('with no announcements at all', () => {
        beforeEach(() => {
          // there are no more
          fetchMock.get(
            /\/api\/v1\/announcements/,
            {
              body: '[]',
              headers: {
                Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"'
              }
            },
            {}
          )
        })
        it('shows nothing for a student', async () => {
          const {container} = render(<K5Announcement {...getCourseProps({canEdit: false})} />)

          await waitFor(() => {}, {ttimeout: 10})
          expect(container.innerHTML).toEqual('')
        })

        it('shows "create a new announcement" for a teacher', async () => {
          const {findByText} = render(<K5Announcement {...getCourseProps({canEdit: true})} />)

          expect(
            await findByText('Create a new announcement now.', {exact: false})
          ).toBeInTheDocument()
        })
      })

      describe('with old announcements', () => {
        beforeEach(() => {
          // get the last one
          fetchMock.get(
            /\/api\/v1\/announcements/,
            {
              body: JSON.stringify([
                {
                  id: '18',
                  title: 'Announcement 2',
                  message: 'Hello, I am announcement 2',
                  html_url: '/courses/1/discussion_topics/18',
                  posted_at: '2021-05-13T17:06:21-06:00',
                  attachments: []
                }
              ]),
              headers: {
                Link: '</api/v1/announcements>; rel="current",</api/v1/announcements>; rel="first",</api/v1/announcements>; rel="last"'
              }
            },
            {}
          )
        })

        it('shows "no recent announcements" for a student', async () => {
          const {findByText, getByText, queryByText} = render(
            <K5Announcement {...getCourseProps({canEdit: false})} />
          )

          expect(await findByText('No recent announcements')).toBeInTheDocument()
          const prevBtn = getByText('Previous announcement').closest('button')
          const nextBtn = getByText('Next announcement').closest('button')
          expect(prevBtn.hasAttribute('disabled')).toBeFalsy()
          expect(nextBtn.hasAttribute('disabled')).toBeTruthy()
          expect(queryByText('Create a new announcement', {exact: false})).toBeNull()
        })

        it('shows "no recent announcements" and a button for a teacher', async () => {
          const {findByText, getByText} = render(
            <K5Announcement {...getCourseProps({canEdit: true})} />
          )

          expect(await findByText('No recent announcements')).toBeInTheDocument()
          const prevBtn = getByText('Previous announcement').closest('button')
          const nextBtn = getByText('Next announcement').closest('button')
          expect(prevBtn.hasAttribute('disabled')).toBeFalsy()
          expect(nextBtn.hasAttribute('disabled')).toBeTruthy()
          expect(getByText('Create a new announcement', {exact: false})).toBeInTheDocument()
        })
      })
    })
  })
})
