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
import {act, render, screen, waitFor} from '@testing-library/react'
import {resetDashboardCards} from '@canvas/dashboard-card'
import {resetPlanner} from '@instructure/canvas-planner'
import fetchMock from 'fetch-mock'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/k5/ObserverGetObservee'
import {cloneDeep} from 'lodash'

import {MOCK_TODOS} from './mocks'
import {
  MOCK_ASSIGNMENTS,
  MOCK_CARDS,
  MOCK_CARDS_2,
  MOCK_EVENTS,
  MOCK_OBSERVER_LIST,
  MOCK_PLANNER_ITEM
} from '@canvas/k5/react/__tests__/fixtures'
import K5Dashboard from '../K5Dashboard'
import {destroyContainer} from '@canvas/alerts/react/FlashAlert'

const ASSIGNMENTS_URL = /\/api\/v1\/calendar_events\?type=assignment&important_dates=true&.*/

const currentUserId = '1'
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUserId}`

const currentUser = {
  id: currentUserId,
  display_name: 'Geoffrey Jellineck',
  avatar_image_url: 'http://avatar'
}
const cardSummary = [
  {
    type: 'Conversation',
    unread_count: 1,
    count: 3
  }
]
const announcements = [
  {
    id: '20',
    context_code: 'course_2',
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
  },
  {
    id: '21',
    context_code: 'course_1',
    title: "This sure isn't a homeroom",
    message: '<p>Definitely not!</p>',
    html_url: '/courses/1/announcements/21'
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
    id: '1',
    course_id: '1',
    name: 'Assignment 1',
    points_possible: 23,
    html_url: '/courses/1/assignments/1',
    due_at: '2021-01-10T05:59:00Z',
    submission_types: ['online_quiz']
  },
  {
    id: '2',
    course_id: '1',
    name: 'Assignment 2',
    points_possible: 10,
    html_url: '/courses/1/assignments/2',
    due_at: '2021-01-15T05:59:00Z',
    submission_types: ['online_url']
  }
]
const syllabus = {
  id: '2',
  syllabus_body: "<p>Here's the grading scheme for this class.</p>"
}
const apps = [
  {
    id: '17',
    course_navigation: {
      text: 'Google Apps',
      icon_url: 'google.png'
    },
    context_id: '1',
    context_name: 'Economics 101'
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
const defaultEnv = {
  current_user: currentUser,
  current_user_id: '1',
  K5_USER: true,
  FEATURES: {
    important_dates: true
  },
  PREFERENCES: {
    hide_dashcard_color_overlays: false
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver'
}
const defaultProps = {
  canDisableElementaryDashboard: false,
  currentUser,
  currentUserRoles: ['admin'],
  createPermissions: null,
  plannerEnabled: false,
  loadingOpportunities: false,
  loadAllOpportunities: () => {},
  timeZone: defaultEnv.TIMEZONE,
  hideGradesTabForStudents: false,
  showImportantDates: true,
  selectedContextCodes: ['course_1', 'course_3'],
  selectedContextsLimit: 2,
  parentSupportEnabled: false,
  canAddObservee: false,
  observerList: MOCK_OBSERVER_LIST
}

beforeAll(() => {
  jest.setTimeout(15000)
})

afterAll(() => {
  jest.setTimeout(5000)
})

beforeEach(() => {
  moxios.install()
  moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
    status: 200,
    response: MOCK_CARDS
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?start_date=.*end_date=.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: MOCK_PLANNER_ITEM
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?start_date=.*per_page=1/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: [
      {
        context_name: 'Course2',
        context_type: 'Course',
        course_id: '1',
        html_url: '/courses/2/announcements/12',
        new_activity: false,
        plannable: {
          created_at: '2020-03-16T17:17:17Z',
          id: '12',
          title: 'Announcement 12',
          updated_at: '2020-03-16T17:31:52Z'
        },
        plannable_date: moment().subtract(6, 'months').toISOString(),
        plannable_id: '12',
        plannable_type: 'announcement',
        planner_override: null,
        submissions: {}
      }
    ]
  })
  moxios.stubRequest(/api\/v1\/planner\/items\?end_date=.*per_page=1/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: [
      {
        context_name: 'Course2',
        context_type: 'Course',
        course_id: '1',
        html_url: '/courses/2/discussion_topics/8',
        new_activity: false,
        plannable: {
          created_at: '2022-03-16T17:17:17Z',
          id: '8',
          title: 'Discussion 8',
          updated_at: '2022-03-16T17:31:52Z'
        },
        plannable_date: moment().add(6, 'months').toISOString(),
        plannable_id: '8',
        plannable_type: 'discussion',
        planner_override: null,
        submissions: {}
      }
    ]
  })
  moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submission.*/, {
    status: 200,
    headers: {link: 'url; rel="current"'},
    response: opportunities
  })
  fetchMock.get('/api/v1/courses/1/activity_stream/summary', JSON.stringify(cardSummary))
  fetchMock.get(/\/api\/v1\/announcements.*/, announcements)
  fetchMock.get(/\/api\/v1\/users\/self\/courses.*/, JSON.stringify(gradeCourses))
  fetchMock.get(encodeURI('api/v1/courses/2?include[]=syllabus_body'), JSON.stringify(syllabus))
  fetchMock.get(/\/api\/v1\/external_tools\/visible_course_nav_tools.*/, JSON.stringify(apps))
  fetchMock.get(/\/api\/v1\/courses\/2\/users.*/, JSON.stringify(staff))
  fetchMock.get(/\/api\/v1\/users\/self\/todo.*/, MOCK_TODOS)
  fetchMock.put('/api/v1/users/self/settings', JSON.stringify({}))
  fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS)
  fetchMock.get(/\/api\/v1\/calendar_events\?type=event&important_dates=true&.*/, MOCK_EVENTS)
  fetchMock.post(
    /\/api\/v1\/calendar_events\/save_selected_contexts.*/,
    JSON.stringify({status: 'ok'})
  )

  global.ENV = defaultEnv
})

afterEach(() => {
  moxios.uninstall()
  fetchMock.restore()
  global.ENV = {}
  resetDashboardCards()
  resetPlanner()
  sessionStorage.clear()
  window.location.hash = ''
  destroyContainer()
  document.cookie = `${observedUserCookieName}=`
})

describe('K-5 Dashboard', () => {
  it('displays a welcome message to the logged-in user', () => {
    const {getByText} = render(<K5Dashboard {...defaultProps} />)
    expect(getByText('Welcome, Geoffrey Jellineck!')).toBeInTheDocument()
  })

  it('allows admins and teachers to turn off the elementary dashboard', async () => {
    const {getByRole} = render(<K5Dashboard {...defaultProps} canDisableElementaryDashboard />)
    const optionsButton = getByRole('button', {name: 'Dashboard Options'})
    act(() => optionsButton.click())

    // There should be an Homeroom View menu option already checked
    const elementaryViewOption = screen.getByRole('menuitemradio', {
      name: 'Homeroom View',
      checked: true
    })
    expect(elementaryViewOption).toBeInTheDocument()

    // There should be a Classic View menu option initially un-checked
    const classicViewOption = screen.getByRole('menuitemradio', {
      name: 'Classic View',
      checked: false
    })
    expect(classicViewOption).toBeInTheDocument()

    // Clicking the Classic View option should update the user's dashboard setting
    act(() => classicViewOption.click())
    await waitFor(() => {
      expect(fetchMock.called('/api/v1/users/self/settings', 'PUT')).toBe(true)
      expect(fetchMock.lastOptions('/api/v1/users/self/settings').body).toEqual(
        JSON.stringify({
          elementary_dashboard_disabled: true
        })
      )
    })
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

    it('shows a due today link pointing to the schedule tab of the course', async () => {
      const {findByRole} = render(<K5Dashboard {...defaultProps} plannerEnabled />)
      const dueTodayLink = await findByRole('link', {
        name: 'View 1 items due today for course Economics 101',
        timeout: 5000
      })
      expect(dueTodayLink).toBeInTheDocument()
      expect(dueTodayLink.getAttribute('href')).toMatch('/courses/1?focusTarget=today#schedule')
    })

    it('shows a missing items link pointing to the schedule tab of the course', async () => {
      const {findByRole} = render(<K5Dashboard {...defaultProps} plannerEnabled />)
      const dueTodayLink = await findByRole('link', {
        name: 'View 2 missing items for course Economics 101',
        timeout: 5000
      })
      expect(dueTodayLink).toBeInTheDocument()
      expect(dueTodayLink.getAttribute('href')).toMatch(
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

    it('displays an empty state on the homeroom and schedule tabs if the user has no cards', async () => {
      moxios.stubs.reset()
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
        status: 200,
        response: []
      })
      const {getByRole, getByTestId, getByText} = render(
        <K5Dashboard {...defaultProps} plannerEnabled />
      )
      await waitFor(() =>
        expect(getByText("You don't have any active courses yet.")).toBeInTheDocument()
      )
      expect(getByTestId('empty-dash-panda')).toBeInTheDocument()

      const scheduleTab = getByRole('tab', {name: 'Schedule'})
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
              response: MOCK_CARDS
            })
            .then(() => {
              // Expect just one announcement request for all cards
              expect(fetchMock.calls(/\/api\/v1\/announcements.*/).length).toBe(1)
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
              response: []
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

    // Skipping for flakiness. See https://instructure.atlassian.net/browse/LS-2243.
    it.skip('displays a list of missing assignments if there are any', async () => {
      const {findByRole, getByRole, getByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )

      const missingAssignments = await findByRole('button', {
        name: 'Show 2 missing items',
        timeout: 5000
      })
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
    })

    it('renders an "jump to navigation" button at the bottom of the schedule tab', async () => {
      const {findByRole} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )

      const jumpToNavButton = await findByRole('button', {name: 'Jump to navigation toolbar'})
      expect(jumpToNavButton).not.toBeVisible()

      act(() => jumpToNavButton.focus())
      expect(jumpToNavButton).toBeVisible()

      act(() => jumpToNavButton.click())
      expect(document.activeElement.id).toBe('weekly-header-active-button')
      expect(jumpToNavButton).not.toBeVisible()
    })

    it('allows navigating to next/previous weeks if there are plannable items in the future/past', async () => {
      const {findByRole, getByRole} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )
      const todayButton = await findByRole('button', {name: 'Jump to Today'})
      expect(todayButton).toBeEnabled()
      const previousButton = getByRole('button', {name: 'View previous week'})
      await waitFor(() => expect(previousButton).toBeEnabled())
      const nextButton = getByRole('button', {name: 'View next week'})
      expect(nextButton).toBeEnabled()
    })

    it('displays a teacher preview if the user has no student enrollments', async () => {
      const {findByTestId, getByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled={false} />
      )

      expect(await findByTestId('kinder-panda')).toBeInTheDocument()
      expect(getByText('Schedule Preview')).toBeInTheDocument()
      expect(
        getByText('Below is an example of how students will see their schedule')
      ).toBeInTheDocument()
      expect(getByText('Math')).toBeInTheDocument()
      expect(getByText('A wonderful assignment')).toBeInTheDocument()
      expect(getByText('Social Studies')).toBeInTheDocument()
      expect(getByText('Exciting discussion')).toBeInTheDocument()
    })

    it('preloads surrounding weeks only once schedule tab is visible', async done => {
      const {findByText, getByRole} = render(<K5Dashboard {...defaultProps} plannerEnabled />)
      expect(await findByText('Assignment 15')).toBeInTheDocument()
      expect(moxios.requests.count()).toBe(5)
      act(() => getByRole('tab', {name: 'Schedule'}).click())
      moxios.wait(() => {
        expect(moxios.requests.count()).toBe(7) // 2 more requests for prev and next week preloads
        done()
      })
    })

    it('reloads the planner with correct data when the selected observee is updated', async done => {
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user=1', {
        status: 200,
        response: MOCK_CARDS
      })

      const observerPlannerItem = cloneDeep(MOCK_PLANNER_ITEM)
      observerPlannerItem[0].plannable.title = 'Assignment for Observee'
      const observerList = [
        {
          id: currentUserId,
          name: 'Self'
        },
        {
          id: '2',
          name: 'Student 2'
        }
      ]

      const {findByText, findByRole, getByRole, getByText} = render(
        <K5Dashboard
          {...defaultProps}
          defaultTab="tab-schedule"
          plannerEnabled
          parentSupportEnabled
          canAddObservee
          currentUserRoles={['user', 'observer']}
          observerList={observerList}
        />
      )
      expect(await findByText('Assignment 15')).toBeInTheDocument()
      expect(
        await findByRole('button', {
          name: 'Show 2 missing items',
          timeout: 5000
        })
      ).toBeInTheDocument()

      moxios.uninstall()
      moxios.install()
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards?observed_user=2', {
        status: 200,
        response: MOCK_CARDS_2
      })
      moxios.stubRequest(/api\/v1\/planner\/items\?.*observed_user_id=2.*/, {
        status: 200,
        headers: {link: 'url; rel="current"'},
        response: observerPlannerItem
      })
      moxios.stubRequest(/\/api\/v1\/users\/self\/missing_submissions\?.*observed_user_id=2.*/, {
        status: 200,
        headers: {link: 'url; rel="current"'},
        response: [opportunities[0]]
      })

      const observerSelect = getByRole('combobox', {name: 'Select a student to view'})
      act(() => observerSelect.click())
      act(() => getByText('Student 2').click())
      expect(await findByText('Assignment for Observee')).toBeInTheDocument()
      expect(
        await findByRole('button', {
          name: 'Show 1 missing item',
          timeout: 10000
        })
      ).toBeInTheDocument()
      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        expect(request.url).toContain('observed_user_id=2')
        done()
      })
    })
  })

  describe('Grades Section', () => {
    it('does not show the grades tab to students if hideGradesTabForStudents is set', async () => {
      const {queryByRole} = render(
        <K5Dashboard {...defaultProps} currentUserRoles={['student']} hideGradesTabForStudents />
      )
      expect(queryByRole('tab', {name: 'Grades'})).not.toBeInTheDocument()
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
      expect(await wrapper.findByRole('button', {name: 'Google Apps'})).toBeInTheDocument()
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
      const {findByRole} = render(<K5Dashboard {...defaultProps} currentUserRoles={['teacher']} />)
      const todoTab = await findByRole('tab', {name: 'To Do'})
      expect(todoTab).toBeInTheDocument()

      act(() => todoTab.click())

      expect(await findByRole('link', {name: 'Grade Plant a plant'})).toBeInTheDocument()
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
    it('does not render any important dates if the flag is off', async () => {
      const {findByText, queryByText} = render(
        <K5Dashboard {...defaultProps} showImportantDates={false} />
      )
      expect(await findByText('My Subjects')).toBeInTheDocument()
      expect(queryByText('Important Dates')).not.toBeInTheDocument()
      expect(queryByText('View Important Dates')).not.toBeInTheDocument()
    })

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
      moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
        status: 200,
        response: MOCK_CARDS.map(c => ({...c, enrollmentState: 'active'}))
      })
      // Only return assignments associated with course_1 on next call
      fetchMock.get(ASSIGNMENTS_URL, MOCK_ASSIGNMENTS.slice(0, 1), {overwriteRoutes: true})

      const {getByRole, getByText, queryByText} = render(
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

      act(() =>
        getByRole('button', {name: 'Select calendars to retrieve important dates from'}).click()
      )
      act(() => getByRole('checkbox', {name: 'Economics 101', checked: true}).click())
      act(() => getByRole('checkbox', {name: 'The Maths', checked: false}).click())
      act(() => getByRole('button', {name: 'Submit'}).click())

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
  })

  describe('Parent Support', () => {
    beforeEach(() => {
      document.cookie = `${observedUserCookieName}=4;path=/`
    })

    const getLastRequest = async () => {
      const request = {}
      await waitFor(() => {
        const r = moxios.requests.mostRecent()
        request.url = r.url
        request.response = r.respondWith({
          status: 200,
          response: MOCK_CARDS
        })
      })
      return request
    }

    it('shows picker when user is an observer', () => {
      const {getByRole} = render(
        <K5Dashboard
          {...defaultProps}
          parentSupportEnabled
          canAddObservee
          currentUserRoles={['user', 'observer']}
        />
      )
      const select = getByRole('combobox', {name: 'Select a student to view'})
      expect(select).toBeInTheDocument()
      expect(select.value).toBe('Student 4')
    })

    it('prefetches dashboard cards with the correct url param', done => {
      moxios.withMock(async () => {
        const {getByRole} = render(
          <K5Dashboard
            {...defaultProps}
            currentUserRoles={['user', 'observer', 'teacher']}
            canAddObservee
            parentSupportEnabled
          />
        )
        const select = getByRole('combobox', {name: 'Select a student to view'})
        const preFetchedRequest = await getLastRequest()
        expect(preFetchedRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user=4')
        await preFetchedRequest.response.then(async () => {
          const onLoadRequest = await getLastRequest()
          expect(select.value).toBe('Student 4')
          // Same request
          expect(onLoadRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user=4')
        })
        done()
      })
    })

    it('does not make a request if the user has been already requested', done => {
      moxios.withMock(async () => {
        const {getByRole, getByText} = render(
          <K5Dashboard
            {...defaultProps}
            currentUserRoles={['user', 'observer', 'teacher']}
            parentSupportEnabled
            canAddObservee
          />
        )
        const select = getByRole('combobox', {name: 'Select a student to view'})
        const preFetchedRequest = await getLastRequest()
        expect(preFetchedRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user=4')
        await preFetchedRequest.response.then(async () => {
          const onLoadRequest = await getLastRequest()
          expect(select.value).toBe('Student 4')
          act(() => select.click())
          act(() => getByText('Student 2').click())
          return onLoadRequest.response.then(async () => {
            const onSelectRequest = await getLastRequest()
            expect(onSelectRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user=2')
            act(() => select.click())
            act(() => getByText('Student 4').click())
            return onSelectRequest.response.then(async () => {
              // It should not request Student 4, as it is already fetched
              const lastRequest = await getLastRequest()
              expect(select.value).toBe('Student 4')
              expect(lastRequest.url).toBe('/api/v1/dashboard/dashboard_cards?observed_user=2')
              expect(moxios.requests.count()).toBe(2)
            })
          })
        })
        done()
      })
    })
  })
})
