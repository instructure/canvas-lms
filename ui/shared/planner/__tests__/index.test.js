/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import moxios from 'moxios'
import {findByTestId, render} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'
import {
  store,
  initializePlanner,
  loadPlannerDashboard,
  resetPlanner,
  renderToDoSidebar,
  renderWeeklyPlannerHeader,
  reloadPlannerForObserver,
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
    flashError: jest.fn(),
    flashMessage: jest.fn(),
    srFlashMessage: jest.fn(),
    convertApiUserContent: jest.fn(),
  }
}

const defaultState = {
  courses: [],
  currentUser: {id: 13},
}

afterEach(() => {
  resetPlanner()
})

describe('with mock api', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div id="application"></div>
      <div id="dashboard-planner"></div>
      <div id="dashboard-planner-header"></div>
      <div id="dashboard-planner-header-aux"></div>
      <div id="dashboard-sidebar"></div>
    `
    moxios.install()
    alertInitialize({
      visualSuccessCallback: jest.fn(),
      visualErrorCallback: jest.fn(),
      srAlertCallback: jest.fn(),
    })
  })

  afterEach(() => {
    moxios.uninstall()
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
          })
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

  describe('loadPlannerDashboard', () => {
    beforeEach(() => {
      initializePlanner(defaultPlannerOptions())
    })

    it('renders into provided divs', async () => {
      loadPlannerDashboard()
      await findByTestId(document.body, 'PlannerApp')
      await findByTestId(document.body, 'PlannerHeader')
      expect(document.querySelector('.PlannerApp')).toBeTruthy()
      expect(document.querySelector('.PlannerHeader')).toBeTruthy()
    })

    it('dispatches getPlannerItems and getInitialOpportunities', async () => {
      const originalDispatch = store.dispatch
      store.dispatch = jest.fn().mockImplementationOnce(() => Promise.resolve())
      loadPlannerDashboard()
      await findByTestId(document.body, 'PlannerHeader')
      expect(store.dispatch).toHaveBeenCalledTimes(2)
      store.dispatch = originalDispatch
    })
  })

  describe('renderToDoSidebar', () => {
    beforeEach(() => {
      initializePlanner(defaultPlannerOptions())
    })

    it('renders into provided element', async () => {
      renderToDoSidebar(document.querySelector('#dashboard-sidebar'))
      await findByTestId(document.body, 'ToDoSidebar')
      expect(document.querySelector('.todo-list-header')).toBeTruthy()
    })
  })

  describe('renderWeeklyPlannerHeader', () => {
    beforeEach(() => {
      const opts = defaultPlannerOptions()
      opts.env.K5_USER = true
      opts.env.K5_SUBJECT_COURSE = true
      initializePlanner(opts)
    })

    it('renders the WeeklyPlannerHeader', async () => {
      // eslint-disable-next-line @typescript-eslint/no-shadow
      const {findByTestId} = render(renderWeeklyPlannerHeader({visible: false}))

      const wph = await findByTestId('WeeklyPlannerHeader')
      expect(wph).toBeInTheDocument()
    })
  })

  describe('reloadPlannerForObserver', () => {
    beforeEach(() => {
      window.ENV ||= {}
      store.dispatch = jest.fn()
      store.getState = () => defaultState
    })

    afterEach(() => {
      jest.resetAllMocks()
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
