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
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import {K5Course} from '../K5Course'
import fetchMock from 'fetch-mock'
import {MOCK_COURSE_APPS, MOCK_COURSE_TABS, MOCK_ASSIGNMENT_GROUPS, MOCK_ENROLLMENTS} from './mocks'
import {TAB_IDS} from '@canvas/k5/react/utils'

const currentUser = {
  id: '1',
  display_name: 'Geoffrey Jellineck'
}
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
  loadAllOpportunities: () => {},
  name: 'Arts and Crafts',
  id: '30',
  timeZone: defaultEnv.TIMEZONE,
  canManage: false,
  courseOverview: '<h2>Time to learn!</h2>',
  hideFinalGrades: false,
  userIsInstructor: false
}
const FETCH_APPS_URL = '/api/v1/courses/30/external_tools/visible_course_nav_tools'
const FETCH_TABS_URL = '/api/v1/courses/30/tabs'
const ASSIGNMENT_GROUPS_URL = encodeURI(
  '/api/v1/courses/30/assignment_groups?include[]=assignments&include[]=submission&include[]=read_state'
)
const ENROLLMENTS_URL = '/api/v1/courses/30/enrollments'

let modulesContainer

beforeAll(() => {
  moxios.install()
  fetchMock.get(FETCH_APPS_URL, JSON.stringify(MOCK_COURSE_APPS))
  fetchMock.get(FETCH_TABS_URL, JSON.stringify(MOCK_COURSE_TABS))
  fetchMock.get(ASSIGNMENT_GROUPS_URL, JSON.stringify(MOCK_ASSIGNMENT_GROUPS))
  fetchMock.get(ENROLLMENTS_URL, JSON.stringify(MOCK_ENROLLMENTS))
  if (!modulesContainer) {
    modulesContainer = document.createElement('div')
    modulesContainer.id = 'k5-modules-container'
    modulesContainer.style.display = 'none'
    modulesContainer.innerHTML = 'Course modules content'
    document.body.appendChild(modulesContainer)
  }
})

afterAll(() => {
  moxios.uninstall()
  fetchMock.restore()
  if (modulesContainer) {
    modulesContainer.remove()
  }
})

beforeEach(() => {
  global.ENV = defaultEnv
})

afterEach(() => {
  global.ENV = {}
})

describe('K-5 Subject Course', () => {
  describe('Tabs Header', () => {
    it('displays a huge version of the course image if set', () => {
      const imageUrl = 'https://example.com/path/to/image.png'
      const {getByTestId} = render(<K5Course {...defaultProps} imageUrl={imageUrl} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero).toBeInTheDocument()
      expect(hero.style.getPropertyValue('background-image')).toBe(`url(${imageUrl})`)
    })

    it('displays the course color if one is set but no course image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} color="#bb8" />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(187, 187, 136)')
    })

    it('displays a gray background on the hero header if no course color or image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(57, 75, 88)')
    })

    it('displays the course name', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      expect(getByText(defaultProps.name)).toBeInTheDocument()
    })

    it('shows Home, Schedule, Modules, Grades, and Resources options', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Home', 'Schedule', 'Modules', 'Grades', 'Resources'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument()
      )
    })

    it('defaults to the Home tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Home', selected: true})).toBeInTheDocument()
    })
  })

  describe('Manage course functionality', () => {
    it('Shows a manage button when the user has manage permissions', () => {
      const {getByRole} = render(<K5Course {...defaultProps} canManage />)
      expect(getByRole('button', {name: 'Manage'})).toBeInTheDocument()
    })

    it('The manage button opens a slide-out tray with the course navigation tabs when clicked', async () => {
      const {getByRole} = render(<K5Course {...defaultProps} canManage />)
      const manageButton = getByRole('button', {name: 'Manage'})

      act(() => manageButton.click())

      const validateLink = (name, href) => {
        const link = getByRole('link', {name})
        expect(link).toBeInTheDocument()
        expect(link.href).toBe(href)
      }

      await waitFor(() => {
        validateLink('Home', 'http://localhost/courses/30')
        validateLink('Modules', 'http://localhost/courses/30/modules')
        validateLink('Assignments', 'http://localhost/courses/30/assignments')
        validateLink('Settings', 'http://localhost/courses/30/settings')
      })
    })

    it('Displays an icon indicating that a nav link is hidden from students', async () => {
      const {findAllByTestId, getByRole, getByText} = render(
        <K5Course {...defaultProps} canManage />
      )
      const manageButton = getByRole('button', {name: 'Manage'})

      act(() => manageButton.click())

      const hiddenIcons = await findAllByTestId('k5-course-nav-hidden-icon')
      // Doesn't show the icon for settings, though
      expect(hiddenIcons.length).toBe(1)

      fireEvent.mouseOver(hiddenIcons[0])
      await waitFor(() =>
        expect(getByText('Disabled. Not visible to students')).toBeInTheDocument()
      )
    })

    it('Does not show a manage button when the user does not have manage permissions', () => {
      const {queryByRole} = render(<K5Course {...defaultProps} />)
      expect(queryByRole('button', {name: 'Manage'})).not.toBeInTheDocument()
    })
  })

  describe('home tab', () => {
    it('shows front page content if a front page is set', () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Time to learn!')).toBeInTheDocument()
    })
  })

  describe('modules tab', () => {
    it('shows modules content if modules tab is selected', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.MODULES} />)
      expect(getByText('Course modules content')).toBeVisible()
    })

    it('hides modules content if modules tab is not selected', async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Course modules content')).not.toBeVisible()
    })
  })

  describe('grades tab', () => {
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
  })

  describe('resources tab', () => {
    it("displays user's apps", async () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
      await waitFor(() => {
        expect(getByText('Studio')).toBeInTheDocument()
        expect(getByText('Student Applications')).toBeInTheDocument()
      })
    })

    it('shows a loading spinner while apps are loading', async () => {
      const {getByText, queryByText} = render(
        <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
      )
      await waitFor(() => {
        expect(getByText('Loading apps...')).toBeInTheDocument()
        expect(queryByText('Studio')).not.toBeInTheDocument()
      })
    })

    it('shows an error if apps fail to load', async () => {
      fetchMock.get(FETCH_APPS_URL, 400, {overwriteRoutes: true})
      const {getAllByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
      await waitFor(() =>
        expect(getAllByText('Failed to load apps for Arts and Crafts.')[0]).toBeInTheDocument()
      )
    })
  })
})
