/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, waitForElement, within} from '@testing-library/react'
import K5Dashboard from '../K5Dashboard'
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
    id: 'test',
    assetString: 'course_1',
    href: '/courses/1',
    shortName: 'Econ 101',
    originalName: 'Economics 101',
    courseCode: 'ECON-001'
  }
]
const defaultEnv = {
  current_user: currentUser,
  FEATURES: {
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
  env: defaultEnv,
  plannerEnabled: false
}

const getSelectedTab = wrapper => {
  const selectedTabs = wrapper.getAllByRole('tab').filter(tab => tab.getAttribute('aria-selected'))
  expect(selectedTabs.length).toBe(1)
  return selectedTabs[0]
}

const expectSelectedTabText = (wrapper, text) => {
  const tab = getSelectedTab(wrapper)
  expect(within(tab).getByText(text)).toBeInTheDocument()
}

// We often have to wait for the Dashboard cards to be rendered on the Homeroom
// tab, otherwise the test finishes too early and Jest cleans up the context
// passed to the card components (e.g. window.ENV). This causes the test to fail
// with undefined errors even if the actual test really succeeds.
const waitForCardsToLoad = async wrapper => {
  await waitForElement(() => wrapper.getByText('My Subjects'))
}

beforeAll(() => {
  moxios.install()
  moxios.stubRequest('/api/v1/dashboard/dashboard_cards', {
    status: 200,
    response: dashboardCards
  })
  moxios.stubRequest(/\/api\/v1\/planner\/items.*/, {
    status: 200,
    response: [],
    headers: {
      link: ''
    }
  })
  fetchMock.get('/api/v1/courses/test/activity_stream/summary', JSON.stringify(cardSummary))
})

afterAll(() => {
  moxios.uninstall()
  fetchMock.restore()
})

beforeEach(() => {
  jest.resetModules()
  window.ENV = defaultEnv
})

afterEach(() => {
  window.ENV = {}
})

describe('K-5 Dashboard', () => {
  jest.spyOn(window, 'fetch').mockImplementation(() =>
    Promise.resolve().then(() => ({
      status: 200,
      json: () => Promise.resolve().then(() => [])
    }))
  )

  it('displays a welcome message to the logged-in user', async () => {
    const wrapper = render(<K5Dashboard {...defaultProps} />)
    await waitForCardsToLoad(wrapper)

    expect(wrapper.getByText('Welcome, Geoffrey Jellineck!')).toBeInTheDocument()
  })

  describe('Tabs', () => {
    it('show Homeroom, Schedule, Grades, and Resources options', async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} />)
      await waitForCardsToLoad(wrapper)
      ;['Homeroom', 'Schedule', 'Grades', 'Resources'].forEach(label => {
        expect(wrapper.getByText(label)).toBeInTheDocument()
      })
    })

    it('default to the Homeroom tab', async () => {
      const wrapper = render(<K5Dashboard {...defaultProps} />)
      await waitForCardsToLoad(wrapper)

      expectSelectedTabText(wrapper, 'Homeroom')
    })

    describe('store current tab ID to URL', () => {
      afterEach(() => {
        window.location.hash = ''
      })

      it('and start at that tab if it is valid', () => {
        window.location.hash = '#grades'
        const wrapper = render(<K5Dashboard {...defaultProps} />)

        expectSelectedTabText(wrapper, 'Grades')
      })

      it('and start at the default tab if it is invalid', async () => {
        window.location.hash = 'tab-not-a-real-tab'
        const wrapper = render(<K5Dashboard {...defaultProps} />)
        await waitForElement(() => wrapper.getByText('My Subjects'))

        expectSelectedTabText(wrapper, 'Homeroom')
      })

      it('and update the current tab as tabs are changed', async () => {
        const wrapper = render(<K5Dashboard {...defaultProps} />)
        await waitForCardsToLoad(wrapper)

        within(wrapper.getByRole('tablist'))
          .getByText('Grades')
          .click()
        expect(window.location.hash).toBe('#grades')
        expectSelectedTabText(wrapper, 'Grades')

        within(wrapper.getByRole('tablist'))
          .getByText('Resources')
          .click()
        expect(window.location.hash).toBe('#resources')
        expectSelectedTabText(wrapper, 'Resources')
      })
    })
  })

  describe('Homeroom Section', () => {
    it('displays "My Subjects" heading', async () => {
      const {getByText} = render(<K5Dashboard {...defaultProps} />)
      await waitForElement(() => getByText('My Subjects'))
    })

    it('shows course cards', async () => {
      const {getByText} = render(<K5Dashboard {...defaultProps} />)
      await waitForElement(() => getByText('Econ 101'))
    })
  })

  describe('Schedule Section', () => {
    it('displays an empty state when no items are fetched', async () => {
      const {getByText} = render(
        <K5Dashboard {...defaultProps} defaultTab="tab-schedule" plannerEnabled />
      )
      await waitForElement(() => getByText("Looks like there isn't anything here"))
    })
  })
})
