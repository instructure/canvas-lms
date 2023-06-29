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
import {render, waitFor, act} from '@testing-library/react'
import {K5Course} from '../K5Course'
import fetchMock from 'fetch-mock'
import {
  MOCK_COURSE_SYLLABUS,
  MOCK_COURSE_APPS,
  MOCK_COURSE_TABS,
  MOCK_GRADING_PERIODS_EMPTY,
  MOCK_ASSIGNMENT_GROUPS,
  MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS,
  MOCK_ENROLLMENTS,
  MOCK_ENROLLMENTS_WITH_OBSERVED_USERS,
  MOCK_GROUPS,
} from './mocks'
import {TAB_IDS} from '@canvas/k5/react/utils'
import {MOCK_OBSERVED_USERS_LIST} from '@canvas/observer-picker/react/__tests__/fixtures'
import sinon from 'sinon'
import {OBSERVER_COOKIE_PREFIX} from '@canvas/observer-picker/ObserverGetObservee'

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck',
  avatar_image_url: 'http://avatar',
}
const observedUserCookieName = `${OBSERVER_COOKIE_PREFIX}${currentUser.id}`
const defaultEnv = {
  current_user: currentUser,
  course_id: '30',
  K5_USER: true,
  FEATURES: {},
  PREFERENCES: {
    hide_dashcard_color_overlays: false,
  },
  MOMENT_LOCALE: 'en',
  TIMEZONE: 'America/Denver',
}

const dtf = new Intl.DateTimeFormat('en', {
  // MMM D, YYYY h:mma
  weekday: 'short',
  month: 'short',
  day: 'numeric',
  year: 'numeric',
  hour: 'numeric',
  minute: 'numeric',
  timeZone: defaultEnv.TIMEZONE,
})

const dateFormatter = d => dtf.format(d instanceof Date ? d : new Date(d))

const defaultTabs = [
  {id: '0'},
  {id: '19'},
  {id: '10'},
  {id: '7'},
  {id: '5'},
  {id: 'context_external_tool_1'},
]
const defaultProps = {
  currentUser,
  loadAllOpportunities: () => {},
  name: 'Arts and Crafts',
  id: '30',
  timeZone: defaultEnv.TIMEZONE,
  canManage: false,
  canReadAnnouncements: true,
  canReadAsAdmin: false,
  courseOverview: {
    body: '<h2>Time to learn!</h2>',
    url: 'home',
    canEdit: true,
  },
  hideFinalGrades: false,
  userIsStudent: true,
  showStudentView: false,
  studentViewPath: '/courses/30/student_view/1',
  showLearningMasteryGradebook: false,
  tabs: defaultTabs,
  settingsPath: '/courses/30/settings',
  groupsPath: '/courses/30/groups',
  latestAnnouncement: {
    id: '12',
    title: 'Important announcement',
    message: '<p>Read this closely.</p>',
    html_url: '/courses/30/discussion_topics/12',
    attachments: [
      {
        filename: 'hw.pdf',
        display_name: 'hw.pdf',
        url: 'http://address/to/hw.pdf',
      },
    ],
    permissions: {
      update: true,
    },
    posted_at: '2021-05-14T17:06:21-06:00',
  },
  pagesPath: '/courses/30/pages',
  hasWikiPages: true,
  hasSyllabusBody: true,
  observedUsersList: [{id: currentUser.id, name: currentUser.display_name}],
  selfEnrollment: {
    option: null,
    url: null,
  },
  assignmentsDueToday: {},
  assignmentsMissing: {},
  assignmentsCompletedForToday: {},
  currentUserRoles: ['user', 'student', 'teacher'],
  isMasterCourse: false,
  showImmersiveReader: false,
}
const FETCH_IMPORTANT_INFO_URL = encodeURI('/api/v1/courses/30?include[]=syllabus_body')
const FETCH_APPS_URL = '/api/v1/external_tools/visible_course_nav_tools?context_codes[]=course_30'

const FETCH_TABS_URL = '/api/v1/courses/30/tabs'
const GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/30?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores'
)
const OBSERVER_GRADING_PERIODS_URL = encodeURI(
  '/api/v1/courses/30?include[]=grading_periods&include[]=current_grading_period_scores&include[]=total_scores&include[]=observed_users'
)
const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/30/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments'
)
const OBSERVER_ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/30/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state&include[]=submission_comments&include[]=observed_users'
)
const ENROLLMENTS_URL = '/api/v1/courses/30/enrollments?user_id=1'
const OBSERVER_ENROLLMENTS_URL = '/api/v1/courses/30/enrollments?user_id=1&include=observed_users'
const ANNOUNEMENTS_URL_REGEX = /\/api\/v1\/announcements\.*/

const GROUPS_URL = encodeURI(
  '/api/v1/courses/30/groups?include[]=users&include[]=group_category&include[]=permissions&include_inactive_users=true&section_restricted=true&filter='
)

const createModulesPartial = () => {
  const modulesContainer = document.createElement('div')
  modulesContainer.id = 'k5-modules-container'
  modulesContainer.style.display = 'none'
  const contextModules = document.createElement('div')
  contextModules.id = 'context_modules'
  modulesContainer.appendChild(contextModules)
  const moduleItem = document.createElement('p')
  moduleItem.innerHTML = 'Course modules content'
  contextModules.appendChild(moduleItem)
  return modulesContainer
}

const createStudentView = () => {
  const resetStudentBtn = document.createElement('a')
  resetStudentBtn.className = 'reset_test_student'
  resetStudentBtn.href = '/courses/30/test_student'
  resetStudentBtn.innerHTML = 'Reset student'
  resetStudentBtn.setAttribute('data-method', 'delete')

  const leaveStudentViewBtn = document.createElement('a')
  leaveStudentViewBtn.className = 'leave_student_view'
  leaveStudentViewBtn.href = '/courses/30/student_view'
  leaveStudentViewBtn.innerHTML = 'Leave student view'
  leaveStudentViewBtn.setAttribute('data-method', 'delete')

  const studentViewBarContainer = document.createElement('div')
  studentViewBarContainer.id = 'student-view-bar-container'
  studentViewBarContainer.appendChild(resetStudentBtn)
  studentViewBarContainer.appendChild(leaveStudentViewBtn)
  return studentViewBarContainer
}

let fakeXhrServer

beforeEach(() => {
  fakeXhrServer = sinon.fakeServer.create({autoRespond: true})
  moxios.install()
  fetchMock.get(FETCH_IMPORTANT_INFO_URL, JSON.stringify(MOCK_COURSE_SYLLABUS))
  fetchMock.get(FETCH_APPS_URL, JSON.stringify(MOCK_COURSE_APPS))
  fetchMock.get(FETCH_TABS_URL, JSON.stringify(MOCK_COURSE_TABS))
  fetchMock.get(GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_EMPTY))
  fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
  fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
  fetchMock.get(ANNOUNEMENTS_URL_REGEX, JSON.stringify([]))
  fakeXhrServer.respondWith('GET', GROUPS_URL, [
    200,
    {'Content-Type': 'application/json'},
    JSON.stringify(MOCK_GROUPS),
  ])
  global.ENV = defaultEnv
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  global.ENV = {}

  // K5Course moves this element into the mounted React container, which gets auto-cleaned
  // by RTL
  const modulesContainer = document.getElementById('k5-modules-container')
  modulesContainer?.remove()

  localStorage.clear()
  moxios.uninstall()
  fetchMock.restore()
  fakeXhrServer.restore()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Tabs Header', () => {
    const bannerImageUrl = 'https://example.com/path/to/banner.jpeg'
    const cardImageUrl = 'https://example.com/path/to/image.png'

    it('displays a huge version of the course banner image if set', () => {
      const {getByTestId} = render(
        <K5Course {...defaultProps} bannerImageUrl={bannerImageUrl} cardImageUrl={cardImageUrl} />
      )
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${bannerImageUrl})`)
    })

    it('displays a huge version of the course card image if set and no banner image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} cardImageUrl={cardImageUrl} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${cardImageUrl})`)
    })

    it('displays the course color if one is set but no course images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} color="#bb8" />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(187, 187, 136)')
    })

    it('displays a gray background on the hero header if no course color or images are set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(57, 75, 88)')
    })

    it('displays the course name', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      expect(getByText(defaultProps.name)).toBeInTheDocument()
    })

    it('shows Home, Schedule, Modules, Grades, and Resources options if configured', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources'].forEach(label => {
        expect(getByText(label)).toBeInTheDocument()
        expect(getByText('Arts and Crafts ' + label)).toBeInTheDocument()
      })
    })

    it('defaults to the first tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Arts and Crafts Home', selected: true})).toBeInTheDocument()
    })

    it('only renders non-hidden tabs, in the order they are provided', () => {
      const tabs = [
        {id: '10'},
        {id: '5', hidden: true},
        {id: '19'},
        {id: 'context_external_tool_3', hidden: true},
      ]
      const {getAllByRole} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />
      )
      const renderedTabs = getAllByRole('tab')
      expect(renderedTabs.map(({id}) => id.replace('tab-', ''))).toEqual([
        TAB_IDS.MODULES,
        TAB_IDS.SCHEDULE,
      ])
    })

    it('still renders Resource tab if course has no LTIs but has Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {getByText} = render(<K5Course {...defaultProps} tabs={tabs} />)
      expect(getByText('Resources')).toBeInTheDocument()
      expect(getByText('Arts and Crafts Resources')).toBeInTheDocument()
    })

    it('does not render Resource tab if course has no LTIs nor Important Info', () => {
      const tabs = [{id: '10'}, {id: '5'}, {id: '19'}]
      const {queryByText} = render(
        <K5Course {...defaultProps} tabs={tabs} hasSyllabusBody={false} />
      )
      expect(queryByText('Resources')).not.toBeInTheDocument()
      expect(queryByText('Arts and Crafts Resources')).not.toBeInTheDocument()
    })

    it('renders an empty state instead of any tabs if none are provided', () => {
      const {getByTestId, getByText, queryByRole} = render(
        <K5Course {...defaultProps} tabs={[]} hasSyllabusBody={false} />
      )
      expect(getByText(defaultProps.name)).toBeInTheDocument()
      expect(queryByRole('tab')).not.toBeInTheDocument()
      expect(getByTestId('space-panda')).toBeInTheDocument()
      expect(getByText('Welcome to the cold, dark void of Arts and Crafts.')).toBeInTheDocument()
    })

    it('renders a link to update tab settings if no tabs are provided and the user has manage permissions', () => {
      const {getByRole} = render(
        <K5Course {...defaultProps} canManage={true} tabs={[]} hasSyllabusBody={false} />
      )
      const link = getByRole('link', {name: 'Reestablish your world'})
      expect(link).toBeInTheDocument()
      expect(link.href).toBe('http://localhost/courses/30/settings#tab-navigation')
    })

    it('does not render anything when tabContentOnly is true', () => {
      const {queryByText} = render(<K5Course {...defaultProps} tabContentOnly={true} />)

      // Course hero shouldn't be shown
      expect(queryByText(defaultProps.name)).not.toBeInTheDocument()

      // Tabs should not be shown
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources', 'Groups'].forEach(t =>
        expect(queryByText(t)).not.toBeInTheDocument()
      )
    })
  })

  describe('Manage course functionality', () => {
    it('Shows a manage button when the user has read_as_admin permissions', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      expect(getByRole('link', {name: 'Manage Subject: Arts and Crafts'})).toBeInTheDocument()
      expect(getByText('Manage Subject')).toBeInTheDocument()
    })

    it('Should redirect to course settings path when clicked', async () => {
      const {getByRole} = render(<K5Course {...defaultProps} canReadAsAdmin={true} />)
      const manageSubjectBtn = getByRole('link', {name: 'Manage Subject: Arts and Crafts'})
      expect(manageSubjectBtn.href).toBe('http://localhost/courses/30/settings')
    })

    it('Does not show a manage button when the user does not have read_as_admin permissions', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} />)
      expect(queryByRole('link', {name: 'Manage Subject: Arts and Crafts'})).not.toBeInTheDocument()
    })
  })

  describe('Student View Button functionality', () => {
    it('Shows the Student View button when the user has student view mode access', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
      expect(queryByRole('link', {name: 'Student View'})).toBeInTheDocument()
    })

    it('Does not show the Student View button when the user does not have student view mode access', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} />)
      expect(queryByRole('link', {name: 'Student View'})).not.toBeInTheDocument()
    })

    it('Should open student view path when clicked', () => {
      const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
      const studentViewBtn = getByRole('link', {name: 'Student View'})
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1')
    })

    it('Should keep the navigation tab when accessing student view mode', () => {
      const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
      getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
      const studentViewBtn = getByRole('link', {name: 'Student View'})
      expect(studentViewBtn.href).toBe('http://localhost/courses/30/student_view/1#grades')
    })

    describe('Student View mode enable', () => {
      beforeEach(() => {
        document.body.appendChild(createStudentView())
      })
      afterEach(() => {
        const studentViewBarContainer = document.getElementById('student-view-bar-container')
        studentViewBarContainer.remove()
      })

      it('Should keep the navigation tab when the fake student is reset', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const resetStudentBtn = getByRole('link', {name: 'Reset student'})
        getByRole('tab', {name: 'Arts and Crafts Resources'}).click()
        expect(resetStudentBtn.href).toBe('http://localhost/courses/30/test_student#resources')
      })

      it('Should keep the navigation tab when leaving student view mode', () => {
        const {getByRole} = render(<K5Course {...defaultProps} showStudentView={true} />)
        const leaveStudentViewBtn = getByRole('link', {name: 'Leave student view'})
        getByRole('tab', {name: 'Arts and Crafts Grades'}).click()
        expect(leaveStudentViewBtn.href).toBe('http://localhost/courses/30/student_view#grades')
      })
    })
  })

  describe('Self-enrollment buttons', () => {
    it("renders a join button if selfEnrollment.option is 'enroll'", () => {
      const selfEnrollment = {
        option: 'enroll',
        url: 'http://enroll_url/',
      }
      const {getByRole} = render(<K5Course {...defaultProps} selfEnrollment={selfEnrollment} />)
      const button = getByRole('link', {name: 'Join this Subject'})
      expect(button).toBeInTheDocument()
      expect(button.href).toBe('http://enroll_url/')
    })

    it("renders a drop button and modal if selfEnrollment.option is 'unenroll'", () => {
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />
      )
      const button = getByRole('button', {name: 'Drop this Subject'})
      expect(button).toBeInTheDocument()
      act(() => button.click())
      expect(getByText('Drop Arts and Crafts')).toBeInTheDocument()
      expect(getByText('Confirm Unenrollment')).toBeInTheDocument()
      expect(
        getByText(
          'Are you sure you want to unenroll in this subject? You will no longer be able to see the subject roster or communicate directly with the teachers, and you will no longer see subject events in your stream and as notifications.'
        )
      ).toBeInTheDocument()
      expect(getByRole('button', {name: 'Cancel'})).toBeInTheDocument()
    })

    it('sends a POST to drop the course after confirming in the modal', () => {
      fetchMock.post('http://unenroll_url/', 200)
      const selfEnrollment = {
        option: 'unenroll',
        url: 'http://unenroll_url/',
      }
      const {getByRole, getAllByRole, getByText} = render(
        <K5Course {...defaultProps} selfEnrollment={selfEnrollment} />
      )
      const openModalButton = getByRole('button', {name: 'Drop this Subject'})
      act(() => openModalButton.click())
      const dropButton = getAllByRole('button', {name: 'Drop this Subject'})[1]
      act(() => dropButton.click())
      expect(getByText('Dropping subject')).toBeInTheDocument()
      expect(fetchMock.called(selfEnrollment.url)).toBeTruthy()
    })

    it('renders neither if selfEnrollment is nil', () => {
      const {getByText, queryByText} = render(<K5Course {...defaultProps} />)
      expect(getByText('Arts and Crafts')).toBeInTheDocument()
      expect(queryByText('Join this Subject')).not.toBeInTheDocument()
      expect(queryByText('Drop this Subject')).not.toBeInTheDocument()
    })
  })

  describe('Subject announcements', () => {
    it('shows the latest announcement, attachment, date, and edit button on the subject home', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canManage={true} />)
      expect(getByText('Important announcement')).toBeInTheDocument()
      expect(getByText('Read this closely.')).toBeInTheDocument()
      const button = getByRole('link', {name: 'Edit announcement Important announcement'})
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/30/discussion_topics/12')
      const attachment = getByRole('link', {name: 'hw.pdf'})
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://address/to/hw.pdf')
      const targetDate = new Date('2021-05-14T17:06:21Z')
      const datePortion = new Intl.DateTimeFormat('en', {
        month: 'short',
        day: 'numeric',
        timeZone: defaultEnv.TIMEZONE,
      }).format(targetDate)
      const timePortion = new Intl.DateTimeFormat('en', {
        hour: 'numeric',
        minute: 'numeric',
        timeZone: defaultEnv.TIMEZONE,
      })
        .format(targetDate)
        .replace(/ [AP]M$/i, '')
      expect(getByText(new RegExp(datePortion))).toBeInTheDocument()
      expect(getByText(new RegExp(timePortion))).toBeInTheDocument()
    })

    it('hides the edit button if student', () => {
      const props = defaultProps
      props.latestAnnouncement.permissions.update = false
      const {queryByRole} = render(<K5Course {...props} />)
      expect(
        queryByRole('link', {name: 'Edit announcement Important announcement'})
      ).not.toBeInTheDocument()
    })

    it('puts the announcement on whichever tab is set as main tab', () => {
      const tabs = [{id: '10'}, {id: '0'}]
      const {getByText} = render(<K5Course {...defaultProps} tabs={tabs} />)
      expect(getByText('Important announcement')).toBeInTheDocument()
    })
  })

  describe('Home tab', () => {
    it('shows front page content if a front page is set', () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Time to learn!')).toBeInTheDocument()
    })

    it('shows an edit button when front page is set', () => {
      const {getByRole} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      const button = getByRole('link', {name: 'Edit home page'})
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/30/pages/home/edit')
    })

    const emptyCourseOverview = {
      body: null,
      url: null,
      canEdit: null,
    }

    it('shows an empty home state if the front page is not set', () => {
      const {getByText, getByTestId} = render(
        <K5Course
          {...defaultProps}
          courseOverview={emptyCourseOverview}
          defaultTab={TAB_IDS.HOME}
        />
      )
      expect(getByTestId('empty-home-panda')).toBeInTheDocument()
      expect(getByText('This is where you’ll land when your home is complete.')).toBeInTheDocument()
    })

    describe('manage home button', () => {
      it('shows the home manage button to teachers when the front page is not set ', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />
        )
        expect(getByTestId('manage-home-button')).toBeInTheDocument()
      })

      it('does not show the home manage button to students', () => {
        const {queryByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
          />
        )
        expect(queryByTestId('manage-home-button')).not.toBeInTheDocument()
      })

      it('sends the user to the course pages list if the course has wiki pages', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />
        )
        const manageHomeLink = getByTestId('manage-home-button')
        expect(manageHomeLink.href).toMatch('/courses/30/pages')
      })

      it('sends the user to create a new page if the course does not have any wiki page', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            hasWikiPages={false}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />
        )
        const manageHomeLink = getByTestId('manage-home-button')
        expect(manageHomeLink.href).toMatch('/courses/30/pages/home')
      })
    })
  })

  describe('Schedule tab', () => {
    it('shows a planner preview scoped to a single course if user has no student enrollments', async () => {
      const {findByTestId, getByText, queryByText} = render(
        <K5Course
          {...defaultProps}
          defaultTab={TAB_IDS.SCHEDULE}
          canManage={true}
          canReadAsAdmin={true}
          userIsStudent={false}
        />
      )
      expect(await findByTestId('kinder-panda')).toBeInTheDocument()
      expect(getByText('Schedule Preview')).toBeInTheDocument()
      expect(
        getByText('Below is an example of how students will see their schedule')
      ).toBeInTheDocument()
      expect(queryByText('Math')).not.toBeInTheDocument()
      expect(getByText('A wonderful assignment')).toBeInTheDocument()
      expect(queryByText('Exciting discussion')).not.toBeInTheDocument()
    })
  })

  describe('Modules tab', () => {
    it('shows modules content if modules tab is selected', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.MODULES} />)
      expect(getByText('Course modules content')).toBeVisible()
    })

    it('hides modules content if modules tab is not selected', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Course modules content')).not.toBeVisible()
    })

    it('moves the modules div inside the main content div on render', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      const mainContent = getByTestId('main-content')
      const modules = document.getElementById('k5-modules-container')
      expect(mainContent.contains(modules)).toBeTruthy()
    })

    it('shows an empty state if no modules exist', () => {
      const contextModules = document.getElementById('context_modules')
      contextModules.removeChild(contextModules.firstChild)
      const {getByText, getByTestId} = render(
        <K5Course {...defaultProps} defaultTab={TAB_IDS.MODULES} />
      )
      expect(
        getByText("Your modules will appear here after they're assembled.")
      ).toBeInTheDocument()
      expect(getByTestId('empty-modules-panda')).toBeInTheDocument()
      expect(contextModules).not.toBeVisible()
    })
  })

  describe('Grades tab', () => {
    it('fetches and displays grade information', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.GRADES} />)
      await waitFor(() => expect(getByText('WWII Report')).toBeInTheDocument())
      ;['Reports', '9.5 pts', 'Out of 10 pts'].forEach(t => {
        expect(getByText(t)).toBeInTheDocument()
      })
      expect(getByText('Submitted', {exact: false})).toBeInTheDocument()
    })

    it('shows course total', async () => {
      const {findByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.GRADES} />)
      expect(await findByText('Total: 89.39%')).toBeInTheDocument()
    })

    it('shows tab for LMGB if enabled', () => {
      const {getByRole} = render(
        <K5Course
          {...defaultProps}
          showLearningMasteryGradebook={true}
          defaultTab={TAB_IDS.GRADES}
        />
      )
      expect(getByRole('tab', {name: 'Learning Mastery'})).toBeInTheDocument()
    })
  })

  describe('Groups tab', () => {
    describe('user is a student', () => {
      it('fetches and displays group information', async () => {
        const {findByText, getByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.GROUPS} />
        )
        expect(await findByText('Fight Club')).toBeInTheDocument()
        ;['Student Clubs', '0 students'].forEach(t => expect(getByText(t)).toBeInTheDocument())
      })
    })

    describe('user is an instructor', () => {
      it('displays welcome page', () => {
        const {getByText} = render(
          <K5Course {...defaultProps} canReadAsAdmin={true} defaultTab={TAB_IDS.GROUPS} />
        )
        expect(getByText('This is where students can see their groups.')).toBeInTheDocument()
      })

      describe('can manage groups', () => {
        it('displays a Manage Groups button', () => {
          const {getByText} = render(
            <K5Course
              {...defaultProps}
              canManageGroups={true}
              canReadAsAdmin={true}
              defaultTab={TAB_IDS.GROUPS}
            />
          )
          expect(getByText('Manage Groups')).toBeInTheDocument()
        })
      })

      describe('can not manage groups', () => {
        it('displays a View Groups button', () => {
          const {getByText} = render(
            <K5Course {...defaultProps} canReadAsAdmin={true} defaultTab={TAB_IDS.GROUPS} />
          )
          expect(getByText('View Groups')).toBeInTheDocument()
        })
      })
    })
  })

  describe('Resources tab', () => {
    describe('important info section', () => {
      it('shows syllabus content with link to edit if teacher', async () => {
        const {findByText, getByRole} = render(
          <K5Course {...defaultProps} canManage={true} defaultTab={TAB_IDS.RESOURCES} />
        )
        expect(await findByText('This is really important.')).toBeInTheDocument()
        const editLink = getByRole('link', {name: 'Edit important info for Arts and Crafts'})
        expect(editLink).toBeInTheDocument()
        expect(editLink.href).toContain('/courses/30/assignments/syllabus')
      })

      it("doesn't show an edit button if not canManage", async () => {
        const {findByText, queryByRole} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
        )
        expect(await findByText('This is really important.')).toBeInTheDocument()
        expect(
          queryByRole('link', {name: 'Edit important info for Arts and Crafts'})
        ).not.toBeInTheDocument()
      })

      it('shows loading skeletons while loading', async () => {
        const {getByText, queryByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
        )
        expect(getByText('Loading important info')).toBeInTheDocument()
        await waitFor(() => {
          expect(queryByText('Loading important info')).not.toBeInTheDocument()
        })
      })

      it('shows an error if syllabus content fails to load', async () => {
        fetchMock.get(FETCH_IMPORTANT_INFO_URL, 400, {overwriteRoutes: true})
        const {findAllByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
        )
        const errors = await findAllByText('Failed to load important info.')
        expect(errors[0]).toBeInTheDocument()
      })
    })

    describe('apps section', () => {
      afterEach(() => {
        fetchMock.restore()
      })
      it("displays user's apps", async () => {
        const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
        await waitFor(() => {
          expect(getByText('Studio')).toBeInTheDocument()
          expect(getByText('Student Applications')).toBeInTheDocument()
        })
      })

      it('shows some loading skeletons while apps are loading', async () => {
        const {getAllByText, queryByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
        )
        await waitFor(() => {
          expect(getAllByText('Loading apps...')[0]).toBeInTheDocument()
          expect(queryByText('Studio')).not.toBeInTheDocument()
        })
      })

      it('shows an error if apps fail to load', async () => {
        fetchMock.get(FETCH_APPS_URL, 400, {overwriteRoutes: true})
        const {getAllByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
        await waitFor(() => expect(getAllByText('Failed to load apps.')[0]).toBeInTheDocument())
      })
    })

    it('does not load content until tab is active', async () => {
      const {getByText, findByText} = render(
        <K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />
      )
      expect(getByText('Time to learn!')).toBeInTheDocument()
      expect(fetchMock.called(FETCH_IMPORTANT_INFO_URL)).toBeFalsy()
      expect(fetchMock.called(FETCH_APPS_URL)).toBeFalsy()
      act(() => getByText('Resources').click())
      expect(await findByText('This is really important.')).toBeInTheDocument()
      expect(fetchMock.called(FETCH_IMPORTANT_INFO_URL)).toBeTruthy()
      expect(fetchMock.called(FETCH_APPS_URL)).toBeTruthy()
    })
  })

  describe('Observer Support', () => {
    beforeEach(() => {
      fetchMock.get(OBSERVER_GRADING_PERIODS_URL, JSON.stringify(MOCK_GRADING_PERIODS_EMPTY))
      fetchMock.get(
        OBSERVER_ASSIGNMENT_GROUPS_URL,
        JSON.stringify(MOCK_ASSIGNMENT_GROUPS_WITH_OBSERVED_USERS)
      )
      fetchMock.get(OBSERVER_ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS_WITH_OBSERVED_USERS))
    })

    afterEach(() => {
      document.cookie = `${observedUserCookieName}=`
    })

    it('shows picker when user is an observer', () => {
      const {getByRole} = render(
        <K5Course {...defaultProps} observedUsersList={MOCK_OBSERVED_USERS_LIST} />
      )
      const select = getByRole('combobox', {name: 'Select a student to view'})
      expect(select).toBeInTheDocument()
      expect(select.value).toBe('Zelda')
    })

    it('shows the observee grades on the Grades Tab', async () => {
      const {getByRole, getByText} = render(
        <K5Course
          {...defaultProps}
          observedUsersList={MOCK_OBSERVED_USERS_LIST}
          defaultTab={TAB_IDS.GRADES}
        />
      )
      const formattedSubmittedDate = `Submitted ${dateFormatter('2021-09-20T23:55:08Z')}`
      const select = getByRole('combobox', {name: 'Select a student to view'})
      act(() => select.click())
      act(() => getByText('Student 5').click())
      await waitFor(() => {
        ;['Assignment 3', formattedSubmittedDate, 'Assignments', '6 pts', 'Out of 10 pts'].forEach(
          label => {
            expect(getByText(label)).toBeInTheDocument()
          }
        )
      })
    })
  })
})
