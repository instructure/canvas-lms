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
import {act, render, screen, waitFor} from '@testing-library/react'
import {resetCardCache} from '@canvas/dashboard-card'
import {resetPlanner} from '@canvas/planner'
import fetchMock from 'fetch-mock'
import {
  MOCK_TODOS,
  createPlannerMocks,
  defaultEnv,
  defaultK5DashboardProps as defaultProps,
} from './mocks'
import {
  MOCK_ASSIGNMENTS,
  MOCK_CARDS,
  MOCK_EVENTS,
  MOCK_ACCOUNT_CALENDAR_EVENT,
} from '@canvas/k5/react/__tests__/fixtures'

import K5Dashboard from '../K5Dashboard'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const ASSIGNMENTS_URL = /\/api\/v1\/calendar_events\?type=assignment&important_dates=true&.*/
const EVENTS_URL = /\/api\/v1\/calendar_events\?type=event&important_dates=true&.*/
const announcements = [
  {
    id: '20',
    context_code: 'course_2',
    title: 'Announcement here',
    message: '<p>This is the announcement</p>',
    html_url: 'http://google.com/announcement',
    permissions: {
      update: true,
    },
    attachments: [
      {
        display_name: 'exam1.pdf',
        url: 'http://google.com/download',
        filename: '1608134586_366__exam1.pdf',
      },
    ],
  },
  {
    id: '21',
    context_code: 'course_1',
    title: "This sure isn't a homeroom",
    message: '<p>Definitely not!</p>',
    html_url: '/courses/1/announcements/21',
  },
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
        type: 'student',
      },
    ],
    homeroom_course: false,
  },
  {
    id: '2',
    name: 'Homeroom Class',
    has_grading_periods: false,
    enrollments: [
      {
        computed_current_score: null,
        computed_current_grade: null,
        type: 'student',
      },
    ],
    homeroom_course: true,
  },
]
const syllabus = {
  id: '2',
  syllabus_body: "<p>Here's the grading scheme for this class.</p>",
}
const apps = [
  {
    id: '17',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png',
    },
    context_id: '1',
    context_name: 'Economics 101',
  },
]
const staff = [
  {
    id: '1',
    short_name: 'Mrs. Thompson',
    bio: 'Office Hours: 1-3pm W',
    avatar_url: '/images/avatar1.png',
    enrollments: [
      {
        role: 'TeacherEnrollment',
      },
    ],
  },
  {
    id: '2',
    short_name: 'Tommy the TA',
    bio: 'Office Hours: 1-3pm F',
    avatar_url: '/images/avatar2.png',
    enrollments: [
      {
        role: 'TaEnrollment',
      },
    ],
  },
]

beforeEach(() => {
  moxios.install()
  createPlannerMocks()
  fetchMock.get(/\/api\/v1\/announcements.*/, announcements)
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, JSON.stringify(gradeCourses))
  fetchMock.get(encodeURI('api/v1/courses/2?include[]=syllabus_body'), JSON.stringify(syllabus))
  fetchMock.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, JSON.stringify(apps))
  fetchMock.get(/\/api\/v1\/courses\/2\/users.*/, JSON.stringify(staff))
  fetchMock.get(/\/api\/v1\/users\/self\/todo.*/, MOCK_TODOS)
  fetchMock.put('/api/v1/users/self/settings', JSON.stringify({}))
  fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS)
  fetchMock.get(EVENTS_URL, MOCK_EVENTS)
  fetchMock.post(
    /\/api\/v1\/calendar_events\/save_selected_contexts.*/,
    JSON.stringify({status: 'ok'})
  )
  fetchMock.put(/\/api\/v1\/users\/\d+\/colors\.*/, {status: 200, body: []})
  global.ENV = defaultEnv
})

afterEach(() => {
  moxios.uninstall()
  fetchMock.restore()
  global.ENV = {}
  resetPlanner()
  resetCardCache()
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
})

describe('K-5 Dashboard', () => {
  it('displays a welcome message to the logged-in user', () => {
    const {getByText} = render(<K5Dashboard {...defaultProps} />)
    expect(getByText('Welcome, Geoffrey Jellineck!')).toBeInTheDocument()
  })

  it('allows admins and teachers to turn off the elementary dashboard', async () => {
    const {getByRole} = render(
      <K5Dashboard {...defaultProps} canDisableElementaryDashboard={true} />
    )
    const optionsButton = getByRole('button', {name: 'Dashboard Options'})
    act(() => optionsButton.click())
    // There should be an Homeroom View menu option already checked
    const elementaryViewOption = screen.getByRole('menuitemradio', {
      name: 'Homeroom View',
      checked: true,
    })
    expect(elementaryViewOption).toBeInTheDocument()
    // There should be a Classic View menu option initially un-checked
    const classicViewOption = screen.getByRole('menuitemradio', {
      name: 'Classic View',
      checked: false,
    })
    expect(classicViewOption).toBeInTheDocument()
    // Clicking the Classic View option should update the user's dashboard setting
    act(() => classicViewOption.click())
    await waitFor(() => {
      expect(fetchMock.called('/api/v1/users/self/settings', 'PUT')).toBe(true)
      expect(fetchMock.lastOptions('/api/v1/users/self/settings').body).toEqual(
        JSON.stringify({
          elementary_dashboard_disabled: true,
        })
      )
    })
  })

  describe('Homeroom Section', () => {
    it('displays "My Subjects" heading', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('My Subjects')).toBeInTheDocument()
    })

    it('shows course cards, excluding homerooms and subjects with pending invites', async () => {
      const {findByLabelText, queryByLabelText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByLabelText('Economics 101')).toBeInTheDocument()
      expect(queryByLabelText('Home Room')).not.toBeInTheDocument()
      expect(queryByLabelText('The Maths')).not.toBeInTheDocument()
    })

    it('shows latest announcement from each homeroom', async () => {
      const {findByText, getByText} = render(<K5Dashboard {...defaultProps} />)
      expect(await findByText('Announcement here')).toBeInTheDocument()
      expect(getByText('This is the announcement')).toBeInTheDocument()
      const attachment = getByText('exam1.pdf')
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://google.com/download')
    })

    it('shows unpublished indicator if homeroom is unpublished', async () => {
      const {findByText, getByText} = render(<K5Dashboard {...defaultProps} />)
      await findByText('Announcement here')
      expect(getByText('Your homeroom is currently unpublished.')).toBeInTheDocument()
    })

    // FOO-3830
    it.skip('shows due today and missing items links pointing to the schedule tab of the course (flaky)', async () => {
      const {findByTestId} = render(<K5Dashboard {...defaultProps} plannerEnabled={true} />)
      const dueTodayLink = await findByTestId('number-due-today')
      expect(dueTodayLink).toBeInTheDocument()
      expect(dueTodayLink).toHaveTextContent('View 1 items due today for course Economics 101')
      expect(dueTodayLink.getAttribute('href')).toMatch('/courses/1?focusTarget=today#schedule')

      const missingItemsLink = await findByTestId('number-missing')
      expect(missingItemsLink).toBeInTheDocument()
      expect(missingItemsLink).toHaveTextContent('View 2 missing items for course Economics 101')
      expect(missingItemsLink.getAttribute('href')).toMatch(
        '/courses/1?focusTarget=missing-items#schedule'
      )
    })

    it('shows the latest announcement for each subject course if one exists', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} />)
      const announcementLink = await findByText("This sure isn't a homeroom")
      expect(announcementLink).toBeInTheDocument()
      expect(announcementLink.closest('a').href).toMatch('/courses/1/announcements/21')
    })

    it('shows loading skeletons for course cards while they load', () => {
      const {getAllByText} = render(<K5Dashboard {...defaultProps} />)
      expect(getAllByText('Loading Card')[0]).toBeInTheDocument()
    })

    // FOO-3830
    it.skip('displays an empty state on the homeroom and schedule tabs if the user has no cards (flaky)', async () => {
      moxios.stubs.reset()
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
        status: 200,
        response: [],
      })
      const {getByTestId, getByText} = render(
        <K5Dashboard {...defaultProps} plannerEnabled={true} />
      )
      await waitFor(() =>
        expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
      )
      expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
      const scheduleTab = getByText('Schedule')
      act(() => scheduleTab.click())
      expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
      expect(getByTestId('empty-dash-panda')).toBeInTheDocument()
    })

    it('only fetches announcements based on cards once per page load', done => {
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify(MOCK_CARDS))
      moxios.withMock(() => {
        render(<K5Dashboard {...defaultProps} />)
        // Don't respond immediately, let the cards from sessionStorage return first
        moxios.wait(() =>
          moxios.requests
            .mostRecent()
            .respondWith({
              status: 200,
              response: MOCK_CARDS,
            })
            .then(() => {
              // Expect just one announcement request for all cards
              expect(fetchMock.calls(/\/api\/v1\/announcements.*latest_only=true.*/).length).toBe(1)
              done()
            })
        )
      })
    })

    it('only fetches announcements and apps if there are any cards', done => {
      sessionStorage.setItem('dashcards_for_user_1', JSON.stringify([]))
      moxios.withMock(() => {
        render(<K5Dashboard {...defaultProps} />)
        moxios.wait(() =>
          moxios.requests
            .mostRecent()
            .respondWith({
              status: 200,
              response: [],
            })
            .then(() => {
              expect(fetchMock.calls(/\/api\/v1\/announcements.*/).length).toBe(0)
              expect(
                fetchMock.calls(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/).length
              ).toBe(0)
              done()
            })
        )
      })
    })
  })

  describe('Grades Section', () => {
    it('does not show the grades tab to students if hideGradesTabForStudents is set', async () => {
      const {findByRole, queryByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student']}
          hideGradesTabForStudents={true}
        />
      )
      await findByRole('tab', {name: 'Homeroom'})
      expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
    })

    it('shows the grades tab to teachers even if hideGradesTabForStudents is set', async () => {
      const {findByRole} = render(
        <K5Dashboard
          {...defaultProps}
          currentUserRoles={['student', 'teacher']}
          hideGradesTabForStudents={true}
        />
      )
      expect(await findByRole('tab', {name: 'Grades'})).toBeInTheDocument()
    })

    it('displays a score summary for each non-homeroom course', async () => {
      const {getByText, queryByText, findByRole} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-grades" />
      )
      expect(await findByRole('link', {name: 'Economics 101'})).toBeInTheDocument()
      expect(getByText('B-')).toBeInTheDocument()
      expect(queryByText('Homeroom Class')).not.toBeInTheDocument()
    })
  })

  describe('Resources Section', () => {
    it('displays syllabus content for homeroom under important info section', async () => {
      const {getByText, findByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-resources" />
      )
      expect(await findByText("Here's the grading scheme for this class.")).toBeInTheDocument()
      expect(getByText('Important Info')).toBeInTheDocument()
    })

    it("shows apps installed in the user's courses", async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)

      const button = await wrapper.findByTestId('k5-app-button')
      expect(button).toBeInTheDocument()
      expect(button).toHaveTextContent('Google Apps')

      const icon = wrapper.getByTestId('renderedIcon')
      expect(icon).toBeInTheDocument()
      expect(icon.src).toContain('google.png')
    })

    it('shows the staff contact info for each staff member in all homeroom courses', async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} defaultTab="tab-resources" />)
      expect(await wrapper.findByText('Mrs. Thompson')).toBeInTheDocument()
      expect(wrapper.getByText('Office Hours: 1-3pm W')).toBeInTheDocument()
      expect(wrapper.getByText('Teacher')).toBeInTheDocument()
      expect(wrapper.getByText('Tommy the TA')).toBeInTheDocument()
      expect(wrapper.getByText('Teaching Assistant')).toBeInTheDocument()
    })
  })

  describe('Todos Section', () => {
    it('displays todo tab to teachers', async () => {
      const {findByText} = render(<K5Dashboard {...defaultProps} currentUserRoles={['teacher']} />)
      const todoTab = await findByText('To Do')
      expect(todoTab).toBeInTheDocument()
      act(() => todoTab.click())

      const gradeButton = await findByText('Grade Plant a plant')
      expect(gradeButton).toBeInTheDocument()
    })

    it('does not show the todos tab to students or admins', async () => {
      const {findByRole, queryByRole} = render(
        <K5Dashboard {...defaultProps} currentUserRoles={['admin', 'student']} />
      )
      expect(await findByRole('tab', {name: 'Homeroom', selected: true})).toBeInTheDocument()
      expect(queryByRole('tab', {name: 'To Do'})).not.toBeInTheDocument()
    })
  })
  describe('Important Dates', () => {
    it('renders a sidebar with important dates and no tray buttons on large screens', async () => {
      const {getByText, queryByText} = render(<K5Dashboard {...defaultProps} />)
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
      expect(getByText('Algebra 2')).toBeInTheDocument()
      expect(getByText('Important Dates')).toBeInTheDocument()
      expect(queryByText('View Important Dates')).not.toBeInTheDocument()
      expect(queryByText('Hide Important Dates')).not.toBeInTheDocument()
    })

    it('filters important dates to those selected', async () => {
      moxios.stubs.reset()
      // Overriding mocked cards to make all cards active so we have 2 subjects to choose from
      moxios.stubRequest(window.location.origin + '/api/v1/dashboard/dashboard_cards', {
        status: 200,
        response: MOCK_CARDS.map(c => ({...c, enrollmentState: 'active'})),
      })
      // Only return assignments associated with course_1 on next call
      fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS.slice(0, 1), {overwriteRoutes: true})
      const {getByLabelText, getByTestId, getByText, queryByText} = render(
        <K5Dashboard
          {...defaultProps}
          selectedContextsLimit={1}
          selectedContextCodes={['course_1']}
        />
      )
      await waitFor(() => {
        expect(getByText('Algebra 2')).toBeInTheDocument()
        expect(queryByText('History Discussion')).not.toBeInTheDocument()
        expect(queryByText('History Exam')).not.toBeInTheDocument()
      })
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).toMatch('context_codes%5B%5D=course_1')
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).not.toMatch('context_codes%5B%5D=course_3')
      // Only return assignments associated with course_3 on next call
      fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS.slice(1, 3), {overwriteRoutes: true})
      act(() => getByTestId('filter-important-dates-button').click())

      const subjectCalendarEconomics = getByLabelText('Economics 101', {selector: 'input'})
      expect(subjectCalendarEconomics).toBeChecked()

      const subjectCalendarMaths = getByLabelText('The Maths', {selector: 'input'})
      expect(subjectCalendarMaths).not.toBeChecked()

      act(() => subjectCalendarEconomics.click())
      act(() => subjectCalendarMaths.click())
      act(() => getByText('Submit').click())
      await waitFor(() => {
        expect(queryByText('Algebra 2')).not.toBeInTheDocument()
        expect(getByText('History Discussion')).toBeInTheDocument()
        expect(getByText('History Exam')).toBeInTheDocument()
      })
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).not.toMatch('context_codes%5B%5D=course_1')
      expect(fetchMock.lastUrl(ASSIGNMENTS_URL)).toMatch('context_codes%5B%5D=course_3')
    })

    it('loads important dates on the grades tab', async () => {
      const {getByText} = render(<K5Dashboard {...defaultProps} defaultTab="tab-grades" />)
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
    })

    it('includes account calendar events', async () => {
      fetchMock.get(EVENTS_URL, [...MOCK_EVENTS, MOCK_ACCOUNT_CALENDAR_EVENT], {
        overwriteRoutes: true,
      })
      const {getByText} = render(
        <K5Dashboard {...defaultProps} selectedContextCodes={['course_1', 'account_1']} />
      )
      await waitFor(() => expect(getByText('History Discussion')).toBeInTheDocument())
      expect(fetchMock.lastUrl(EVENTS_URL)).toMatch(
        'context_codes%5B%5D=course_1&context_codes%5B%5D=account_1'
      )
      ;['Morning Yoga', 'Football Game', 'CSU'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument()
      )
    })
  })
})
