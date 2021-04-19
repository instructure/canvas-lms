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
import {MOCK_COURSE_APPS, MOCK_COURSE_TABS} from './mocks'
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
  courseOverview: '<h2>Time to learn!</h2>'
}
const FETCH_APPS_URL = '/api/v1/courses/30/external_tools/visible_course_nav_tools'
const FETCH_TABS_URL = '/api/v1/courses/30/tabs'

beforeAll(() => {
  moxios.install()
  fetchMock.get(FETCH_APPS_URL, JSON.stringify(MOCK_COURSE_APPS))
  fetchMock.get(FETCH_TABS_URL, JSON.stringify(MOCK_COURSE_TABS))
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

    it('displays a gray background on the hero header if no image is set', () => {
      const {getByTestId} = render(<K5Course {...defaultProps} />)
      const hero = getByTestId('k5-course-header-hero')

      expect(hero.style.getPropertyValue('background-color')).toBe('rgb(199, 205, 209)')
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

  describe('overview tab', () => {
    it('shows front page content if a front page is set', () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />)
      expect(getByText('Time to learn!')).toBeInTheDocument()
    })
  })

  describe('modules tab', () => {
    it('only shows modules container on modules tab', () => {
      const modulesContainer = document.createElement('div')
      modulesContainer.setAttribute('id', 'k5-modules-container')
      modulesContainer.style.display = 'none'
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(modulesContainer.style.display).toBe('none')
      getByRole('tab', {name: 'Modules'}).click()
      waitFor(() => expect(modulesContainer.style.display).toBe('block'))
    })
  })

  describe('resources tab', () => {
    it("displays user's apps", () => {
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
      waitFor(() => {
        expect(getByText('Studio')).toBeInTheDocument()
        expect(getByText('Student Applications')).toBeInTheDocument()
      })
    })

    it('shows a loading spinner while apps are loading', () => {
      const {getByText, queryByText} = render(
        <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />
      )
      waitFor(() => expect(getByText('Loading apps...')).toBeInTheDocument())
      expect(queryByText('Studio')).not.toBeInTheDocument()
    })

    it('shows an error if apps fail to load', () => {
      fetchMock.get(FETCH_APPS_URL, 400, {overwriteRoutes: true})
      const {getByText} = render(<K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />)
      waitFor(() =>
        expect(getByText('Failed to load apps for Arts and Crafts.')).toBeInTheDocument()
      )
    })
  })
})
