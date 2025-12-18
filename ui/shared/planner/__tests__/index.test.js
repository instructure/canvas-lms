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

import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {
  initializePlanner,
  reloadPlannerForObserver,
  renderWeeklyPlannerHeader,
  resetPlanner,
  store,
} from '../index'
import {initialize as alertInitialize} from '../utilities/alertUtils'

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

const defaultState = {
  courses: [],
  currentUser: {id: 13},
  loading: {
    isLoading: false,
    hasSomeItems: true,
    allPastItemsLoaded: false,
    allFutureItemsLoaded: false,
    loadingPast: false,
    loadingFuture: false,
  },
  days: [],
  opportunities: {
    items: [],
    nextUrl: null,
  },
  sidebar: {
    items: [],
    loaded: true,
    loading: false,
    loadingError: null,
  },
  todo: {
    updateTodoItem: null,
    showTodoDetails: false,
    todos: [],
  },
  weeklyDashboard: {
    weekStart: null,
    weekEnd: null,
    wayPastItemDate: null,
    wayFutureItemDate: null,
  },
  locale: 'en',
  today: new Date(),
}

const server = setupServer(
  http.get('/api/v1/users/self/missing_submissions*', () =>
    HttpResponse.json([], {headers: {link: 'url; rel="current"'}}),
  ),
)

beforeAll(() => server.listen())
afterEach(() => {
  server.resetHandlers()
  resetPlanner()
})
afterAll(() => server.close())

describe('with mock api', () => {
  beforeEach(async () => {
    document.body.innerHTML = ''
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner-header'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-planner-header-aux'
    document.body.appendChild(document.createElement('div')).id = 'dashboard-sidebar'

    // Setup mock for window.matchMedia
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

  describe('initializePlanner', () => {
    it('cannot be called twice', async () => {
      await initializePlanner(defaultPlannerOptions())
      return expect(initializePlanner(defaultPlannerOptions())).rejects.toThrow()
    })

    it('requires flash methods', async () => {
      ;(
        await Promise.allSettled(
          ['flashError', 'flashMessage', 'srFlashMessage'].map(flash => {
            const options = defaultPlannerOptions()
            options[flash] = null
            return initializePlanner(options)
          }),
        )
      ).forEach(({status}) => expect(status).toBe('rejected'))
    })

    it('requires convertApiUserContent', () => {
      const options = defaultPlannerOptions()
      options.convertApiUserContent = null
      return expect(initializePlanner(options)).rejects.toBeDefined()
    })

    it('requires timezone', () => {
      const options = defaultPlannerOptions()
      options.env.TIMEZONE = null
      return expect(initializePlanner(options)).rejects.toBeDefined()
    })

    it('requires locale', () => {
      const options = defaultPlannerOptions()
      options.env.MOMENT_LOCALE = null
      return expect(initializePlanner(options)).rejects.toBeDefined()
    })
  })

  describe('renderWeeklyPlannerHeader', () => {
    beforeEach(() => {
      const opts = defaultPlannerOptions()
      opts.env.K5_USER = true
      opts.env.K5_SUBJECT_COURSE = true
      initializePlanner(opts)
    })

    it('renders the WeeklyPlannerHeader', () => {
      // Just test that the function returns a React element without error
      const result = renderWeeklyPlannerHeader({visible: false})
      expect(result).toBeTruthy()
      expect(typeof result).toBe('object')
      expect(result.type).toBeDefined()
    })
  })

  describe('reloadPlannerForObserver', () => {
    beforeEach(() => {
      window.ENV ||= {}
      store.dispatch = vi.fn()
      store.getState = () => defaultState
    })

    afterEach(() => {
      vi.resetAllMocks()
    })

    it('throws an exception unless the planner is initialized', () => {
      expect(() => reloadPlannerForObserver('1')).toThrow()
    })

    it('dispatches reloadWithObservee if not passed an observee id', () => {
      // if no observee_id is passed means the observer is observing himself
      return initializePlanner(defaultPlannerOptions()).then(() => {
        store.dispatch.mockClear()
        reloadPlannerForObserver(null)
        expect(store.dispatch).toHaveBeenCalled()
      })
    })

    it('does nothing if given the existing selectedObservee id', () => {
      store.getState = () => ({
        ...defaultState,
        selectedObservee: '17',
      })

      return initializePlanner(defaultPlannerOptions()).then(() => {
        store.dispatch.mockClear()
        reloadPlannerForObserver('17')
        expect(store.dispatch).not.toHaveBeenCalled()
      })
    })

    it('dispatches reloadWithObservee when all conditions are met', () => {
      store.getState = () => ({
        ...defaultState,
        selectedObservee: '1',
        weeklyDashboard: {},
      })

      return initializePlanner(defaultPlannerOptions()).then(() => {
        store.dispatch.mockClear()
        reloadPlannerForObserver('17')
        expect(store.dispatch).toHaveBeenCalled()
      })
    })
  })
})
