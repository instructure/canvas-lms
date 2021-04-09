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
import {render, waitFor} from '@testing-library/react'
import {K5Course} from '../K5Course'
import fetchMock from 'fetch-mock'
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
  timeZone: defaultEnv.TIMEZONE
}
const fetchAppsResponse = [
  {
    id: '7',
    course_navigation: {
      text: 'Studio',
      icon_url: 'studio.png'
    }
  }
]
const FETCH_APPS_URL = '/api/v1/courses/30/external_tools/visible_course_nav_tools'

beforeAll(() => {
  moxios.install()
  fetchMock.get(FETCH_APPS_URL, JSON.stringify(fetchAppsResponse))
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

    it('shows Overview, Schedule, Modules, Grades, and Resources options', () => {
      const {getByText} = render(<K5Course {...defaultProps} />)
      ;['Overview', 'Schedule', 'Modules', 'Grades', 'Resources'].forEach(label =>
        expect(getByText(label)).toBeInTheDocument()
      )
    })

    it('defaults to the Overview tab', () => {
      const {getByRole} = render(<K5Course {...defaultProps} />)
      expect(getByRole('tab', {name: 'Overview', selected: true})).toBeInTheDocument()
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
