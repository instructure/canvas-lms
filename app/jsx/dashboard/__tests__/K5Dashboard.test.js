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
import moxios from 'moxios'
import {act, render, waitFor} from '@testing-library/react'
import {K5Dashboard} from '../K5Dashboard'
import fetchMock from 'fetch-mock'

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck'
}
const cardSummary = [
  {
    type: 'Conversation',
    unread_count: 1,
    count: 3
  }
]
const dashboardCards = [
  {
    id: 'test',
    assetString: 'course_1',
    href: '/courses/1',
    shortName: 'Econ 101',
    originalName: 'Economics 101',
    courseCode: 'ECON-001',
    isHomeroom: false,
    canManage: true
  },
  {
    id: 'homeroom',
    assetString: 'course_2',
    href: '/courses/2',
    shortName: 'Homeroom1',
    originalName: 'Home Room',
    courseCode: 'HOME-001',
    isHomeroom: true,
    canManage: true
  }
]
const homeroomAnnouncement = [
  {
    title: 'Announcement here',
    message: '<p>This is the announcement</p>',
    html_url: 'http://google.com/announcement',
    permissions: {
      update: true
    },
    attachments: [
      {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf'
      }
    ]
  }
]
const gradeCourses = [
  {
    id: 'test',
    name: 'Economics 101',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: 82,
        computed_current_grade: 'B-'
      }
    ],
    homeroom_course: false
  },
  {
    id: 'homeroom',
    name: 'Homeroom Class',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: null,
        computed_current_grade: null
      }
    ],
    homeroom_course: true
  }
]
const staff = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
    email: 't@abc.edu',
    avatar_url: '/images/avatar1.png',
    enrollments: [
      {
        role: 'TeacherEnrollment'
      }
    ]
  },
  {
    id: '2',
    short_name: 'Tommy the TA',
    bio: 'Office Hours: 1-3pm F',
    email: 'tommy@abc.edu',
    avatar_url: '/images/avatar2.png',
    enrollments: [
      {
        role: 'TaEnrollment'
      }
    ]
  }
]
const defaultEnv = {
  current_user: currentUser,
  FEATURES: {
    canvas_for_elementary: true,
    unpublished_courses: true
  },
  PREFERENCES: {
    hide_dashcard_color_overlays: false
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver'
}
const defaultProps = {
  currentUser,
  env: defaultEnv,
  plannerEnabled: false
}

beforeAll(() => {
  moxios.install()
  moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
    status: 200,
    response: dashboardCards
  })
  moxios.stubRequest(/\/api\/v1\/planner\/items.*/, {
    status: 200,
    response: [],
    headers: {
      link: ''
    }
  })
  fetchMock.get('/api/v1/courses/test/activity_stream/summary', JSON.stringify(cardSummary))
  fetchMock.get(
    /\/api\/v1\/announcements\?context_codes=course_homeroom.*/,
    JSON.stringify(homeroomAnnouncement)
  )
  fetchMock.get(/\/api\/v1\/announcements\?context_codes=course_test.*/, '[]')
  fetchMock.get('/api/v1/users/self/missing_submissions?filter[]=submittable', '[]')
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, JSON.stringify(gradeCourses))
  fetchMock.get(/\/api\/v1\/courses\/homeroom\/users.*/, JSON.stringify(staff))
})

afterAll(() => {
  moxios.uninstall()
  fetchMock.restore()
})

beforeEach(() => {
  jest.resetModules()
  global.ENV = defaultEnv
})

afterEach(() => {
  global.ENV = {}
})

describe('K-5 Dashboard', () => {
  it('displays a welcome message to the logged-in user', async () => {
    const {findByText} = render(<K5Dashboard {...defaultProps} />)
    expect(await findByText('Welcome, Geoffrey Jellineck!')).toBeInTheDocument()
  })

  describe('Tabs', () => {
    it('show Homeroom, Schedule, Grades, and Resources options', async () => {
      const {getByText} = render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => {
        ;['Homeroom', 'Schedule', 'Grades', 'Resources'].forEach(label =>
          expect(getByText(label)).toBeInTheDocument()
        )
      })
    })

    it('default to the Homeroom tab', async () => {
      const {findByRole} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
    })

    describe('store current tab ID to URL', () => {
      afterEach(() => {
        window.location.hash = ''
      })

      it('and start at that tab if it is valid', async () => {
        window.location.hash = '#grades'
        const {findByRole} = render(<K5Dashboard {...defaultProps} />)
        expect(await findByRole('tab', {name: 'Grades', selected: true})).toBeInTheDocument()
      })

      it('and start at the default tab if it is invalid', async () => {
        window.location.hash = 'tab-not-a-real-tab'
        const {findByRole} = render(<K5Dashboard {...defaultProps} />)
        expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
      })

      it('and update the current tab as tabs are changed', async () => {
        const {findByRole, getByRole, queryByRole} = render(<K5Dashboard {...defaultProps} />)

        const gradesTab = await findByRole('tab', {name: 'Grades'})
        act(() => gradesTab.click())
        expect(await findByRole('tab', {name: 'Grades', selected: true})).toBeInTheDocument()

        act(() => getByRole('tab', {name: 'Resources'}).click())
        expect(await findByRole('tab', {name: 'Resources', selected: true})).toBeInTheDocument()
        expect(queryByRole('tab', {name: 'Grades', selected: true})).not.toBeInTheDocument()
      })
    })
  })

  describe('Homeroom Section', () => {
    it('displays "My Subjects" heading', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('My Subjects')).toBeInTheDocument()
    })

    it('shows course cards, excluding homerooms', async () => {
      const {findByText, queryByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('Economics 101')).toBeInTheDocument()
      expect(queryByText('Home Room')).not.toBeInTheDocument()
    })

    it('shows latest announcement from each homeroom', async () => {
      const {findByText, getByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('Announcement here')).toBeInTheDocument()
      expect(getByText('This is the announcement')).toBeInTheDocument()
      const attachment = getByText('exam1.pdf')
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://google.com/download')
    })
  })

  describe('Schedule Section', () => {
    it('displays an empty state when no items are fetched', async () => {
      const {findByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )
      expect(await findByText("Looks like there isn't anything here")).toBeInTheDocument()
    })
  })

  describe('Grades Section', () => {
    it('displays a score summary for each non-homeroom course', async () => {
      const {findByText, getByText, queryByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-grades" />
      )
      expect(await findByText('Economics 101')).toBeInTheDocument()
      expect(getByText('B-')).toBeInTheDocument()
      expect(queryByText('Homeroom Class')).not.toBeInTheDocument()
    })
  })

  describe('Resources Section', () => {
    it('shows the staff contact info for each staff member in all homeroom courses', async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)
      expect(await wrapper.findByText('Mrs. Thompson')).toBeInTheDocument()
      expect(wrapper.getByText('Office Hours: 1-3pm W')).toBeInTheDocument()
      expect(wrapper.getByText('Teacher')).toBeInTheDocument()
      expect(wrapper.getByText('Tommy the TA')).toBeInTheDocument()
      expect(wrapper.getByText('Teaching Assistant')).toBeInTheDocument()
    })
  })
})
