/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {configure, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {initializePlanner, loadPlannerDashboard, renderToDoSidebar, resetPlanner} from '../index'
import {initialize as alertInitialize} from '../utilities/alertUtils'

configure({asyncUtilTimeout: 4000})

function defaultPlannerOptions() {
  return {
    env: {
      MOMENT_LOCALE: 'en',
      TIMEZONE: 'UTC',
      current_user: {
        id: '42',
        display_name: 'Arthur Dent',
        avatar_image_url: 'http://example.com',
      },
      PREFERENCES: {
        custom_colors: {},
      },
      K5_USER: false,
      K5_SUBJECT_COURSE: false,
    },
    flashError: vi.fn(),
    flashMessage: vi.fn(),
    srFlashMessage: vi.fn(),
    convertApiUserContent: vi.fn(),
  }
}

const server = setupServer(
  http.get('/api/v1/users/self/missing_submissions*', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
  http.get('/api/v1/planner/items*', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
  http.get('/api/v1/users/self/todo*', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
)

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  resetPlanner()
})
afterAll(() => server.close())

describe('planner rendering', () => {
  const sidebarRoot = null
  const plannerRoot = null
  const headerRoot = null

  beforeEach(() => {
    document.body.innerHTML = ''
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner-header'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner-header-aux'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-sidebar'

    window.matchMedia = vi.fn().mockImplementation(query => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }))

    alertInitialize({
      visualSuccessCallback: vi.fn(),
      visualErrorCallback: vi.fn(),
      srAlertCallback: vi.fn(),
    })
  })

  afterEach(async () => {
    // Wait for any pending React updates to complete
    await waitFor(() => {}, {timeout: 100}).catch(() => {})

    // Clean up any mounted React roots by clearing the DOM
    document.body.innerHTML = ''
  })

  describe('loadPlannerDashboard', () => {
    it('renders planner components into dashboard elements', async () => {
      await initializePlanner(defaultPlannerOptions())

      const plannerElement = document.getElementById('dashboard-planner')
      const headerElement = document.getElementById('dashboard-planner-header')

      expect(plannerElement).toBeTruthy()
      expect(headerElement).toBeTruthy()

      loadPlannerDashboard()

      // Wait for React to render something
      await waitFor(() => {
        expect(plannerElement.children.length).toBeGreaterThan(0)
      })
    })
  })

  describe('renderToDoSidebar', () => {
    it('renders into provided element', async () => {
      await initializePlanner(defaultPlannerOptions())

      const element = document.getElementById('dashboard-sidebar')

      renderToDoSidebar(element)

      // Wait for React to render something
      await waitFor(() => {
        expect(element.children.length).toBeGreaterThan(0)
      })
    })
  })
})
