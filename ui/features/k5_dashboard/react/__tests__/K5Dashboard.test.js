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
import moment from 'moment-timezone'
import moxios from 'moxios'
import {act, render, waitFor} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
import {resetPlanner} from '@instructure/canvas-planner'
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
    id: '1',
    assetString: 'course_1',
    href: '/courses/1',
    shortName: 'Econ 101',
    originalName: 'Economics 101',
    courseCode: 'ECON-001',
    isHomeroom: false,
    canManage: true
  },
  {
    id: '2',
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
    id: '1',
    name: 'Economics 101',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: 82,
        computed_current_grade: 'B-',
        type: 'student'
      }
    ],
    homeroom_course: false
  },
  {
    id: '2',
    name: 'Homeroom Class',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: null,
        computed_current_grade: null,
        type: 'student'
      }
    ],
    homeroom_course: true
  }
]
const opportunities = [
  {
    id: 1,
    course_id: '1',
    name: 'Assignment 1',
    point_possible: 23,
    html_url: '/courses/1/assignments/1',
    due_at: '2021-01-10T05:59:00Z',
    submission_types: ['online_quiz']
  },
  {
    id: 2,
    course_id: '1',
    name: 'Assignment 2',
    point_possible: 10,
    html_url: '/courses/1/assignments/2',
    due_at: '2021-01-15T05:59:00Z',
    submission_types: ['online_url']
  }
]
const staff = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
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
    avatar_url: '/images/avatar2.png',
    enrollments: [
      {
        role: 'TaEnrollment'
      }
    ]
  }
]
const apps = [
  {
    id: '17',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png'
    }
  }
]
const defaultEnv = {
  current_user: currentUser,
  K5_MODE: true,
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
  plannerEnabled: false,
  loadAllOpportunities: () => {},
  timeZone: defaultEnv.TIMEZONE
}

beforeAll(() => {
  moxios.install()
  moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
    status: 200,
    response: dashboardCards
  })
  moxios.stubRequest(/api\/v1\/planner\/items.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: [
      {
        context_name: 'Course2',
        context_type: 'Course',
        course_id: '1',
        html_url: '/courses/2/assignments/15',
        new_activity: false,
        plannable: {
          created_at: '2021-03-16T17:17:17Z',
          due_at: moment().toISOString(),
          id: '15',
          points_possible: 10,
          title: 'Assignment 15',
          updated_at: '2021-03-16T17:31:52Z'
        },
        plannable_date: moment().toISOString(),
        plannable_id: '15',
        plannable_type: 'assignment',
        planner_override: null,
        submissions: {
          excused: false,
          graded: false,
          has_feedback: false,
          late: false,
          missing: true,
          needs_grading: false,
          redo_request: false,
          submitted: false
        }
      }
    ]
  })
  moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submission.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: opportunities
  })
  fetchMock.get('/api/v1/courses/1/activity_stream/summary', JSON.stringify(cardSummary))
  fetchMock.get(
    /\/api\/v1\/announcements\?context_codes=course_2.*/,
    JSON.stringify(homeroomAnnouncement)
  )
  fetchMock.get(/\/api\/v1\/announcements\?context_codes=course_1.*/, '[]')
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, JSON.stringify(gradeCourses))
  fetchMock.get(/\/api\/v1\/courses\/2\/users.*/, JSON.stringify(staff))
  fetchMock.get('/api/v1/courses/1/external_tools/visible_course_nav_tools', JSON.stringify(apps))
})

afterAll(() => {
  moxios.uninstall()
  fetchMock.restore()
})

beforeEach(() => {
  global.ENV = defaultEnv
})

afterEach(() => {
  global.ENV = {}
  resetPlanner()
  window.location.hash = ''
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

    it('shows a due today link pointing to the first item on schedule tab for today', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} plannerEnabled />)
      const dueTodayLink = await findByText('1 due today', {timeout: 5000})
      expect(dueTodayLink).toBeInTheDocument()

      act(() => dueTodayLink.click())
      expect(await findByText('Assignment 15')).toBeInTheDocument()
      // window.requestAnimationFrame doesn't really work in jsdom, so we can't test that the
      // correct element is focused since that occurs at the end of the scrolling animation
    })

    it('shows a missing items link pointing to the missing items section on the schedule tab', async () => {
      const {findByText, getByRole, getByText} = render(
        <K5Dashboard {...defaultProps} plannerEnabled />
      )
      const missingLink = await findByText('2 missing')
      expect(missingLink).toBeInTheDocument()

      act(() => missingLink.click())
      expect(await findByText('Assignment 15')).toBeInTheDocument()

      // The missing items button should be expanded and focused
      await waitFor(() => {
        expect(document.activeElement.dataset.testid).toBe('missing-item-info')
        expect(document.activeElement.getAttribute('aria-expanded')).toBe('true')
      })
      expect(getByRole('button', {name: 'Hide 2 missing items'})).toBeInTheDocument()

      // Missing item details should be shown underneath it
      expect(getByText('Assignment 1')).toBeInTheDocument()
      expect(getByText('Assignment 2')).toBeInTheDocument()
    })

    it('shows loading skeletons for course cards while they load', () => {
      const {getAllByText} = render(<K5Dashboard {...defaultProps} />)
      expect(getAllByText('Loading Card')[0]).toBeInTheDocument()
    })
  })

  describe('Schedule Section', () => {
    it('displays the planner with a planned item', async () => {
      const {findByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )
      expect(await findByText('Assignment 15')).toBeInTheDocument()
      // The new weekly planner doesn't display the PlannerEmptyState.
      // This will get addressed one way or another with LS-2042
      // expect(await findByText("Looks like there isn't anything here")).toBeInTheDocument()
      // expect(await findByText('Nothing More To Do')).toBeInTheDocument()
    })

    it('displays a list of missing assignments if there are any', async () => {
      const {findByRole, getByRole, getByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )

      const missingAssignments = await findByRole('button', {name: 'Show 2 missing items'})
      expect(missingAssignments).toBeInTheDocument()

      act(() => missingAssignments.click())
      expect(getByRole('button', {name: 'Hide 2 missing items'})).toBeInTheDocument()
      expect(getByText('Assignment 1')).toBeInTheDocument()
      expect(getByText('Assignment 2')).toBeInTheDocument()
    })

    it('renders the weekly planner header', async () => {
      const {findByTestId} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )
      const planner = await findByTestId('PlannerApp', {timeout: 4000}) // give it some more time
      expect(planner).toBeInTheDocument()

      const header = await findByTestId('WeeklyPlannerHeader')
      expect(header).toBeInTheDocument()

      const footer = await findByTestId('WeeklyPlannerFooter')
      expect(footer).toBeInTheDocument()
    })

    it('displays a teacher preview if the user has no student enrollments', async () => {
      const {findByTestId, getByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnable={false} />
      )

      expect(await findByTestId('kinder-panda')).toBeInTheDocument()
      expect(getByText('Teacher Schedule Preview')).toBeInTheDocument()
      expect(
        getByText('Below is an example of how your students will see their schedule')
      ).toBeInTheDocument()
      expect(getByText('Social Studies')).toBeInTheDocument()
      expect(getByText('A great discussion assignment')).toBeInTheDocument()
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

    it("shows apps installed in the user's courses", async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)
      expect(await wrapper.findByText('Google Apps')).toBeInTheDocument()
      const icon = wrapper.getByTestId('renderedIcon')
      expect(icon).toBeInTheDocument()
      expect(icon.src).toContain('google.png')
    })
  })
})
