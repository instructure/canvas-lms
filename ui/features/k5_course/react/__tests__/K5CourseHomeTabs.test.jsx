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

import {vi} from 'vitest'
import {TAB_IDS} from '@canvas/k5/react/utils'
import {render} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import React from 'react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {K5Course} from '../K5Course'
import {MOCK_GROUPS} from './mocks'
import fakeENV from '@canvas/test-utils/fakeENV'
import {
  defaultProps,
  defaultEnv,
  createModulesPartial,
  setupBasicFetchMocks,
  cleanupModulesContainer,
  getOneMonthAgo,
} from './K5CourseTestHelpers'

vi.mock('@canvas/util/globalUtils', () => ({
  reloadWindow: vi.fn(),
}))

const server = setupServer()

beforeAll(() => {
  server.listen()
})

afterAll(() => {
  server.close()
})

beforeEach(() => {
  setupBasicFetchMocks()
  server.use(
    http.get('/api/v1/courses/30/groups', () => {
      return HttpResponse.json(MOCK_GROUPS)
    }),
  )
  fakeENV.setup(defaultEnv)
  document.body.appendChild(createModulesPartial())
})

afterEach(() => {
  fakeENV.teardown()
  cleanupModulesContainer()
  localStorage.clear()
  fetchMock.restore()
  server.resetHandlers()
  window.location.hash = ''
})

describe('K-5 Subject Course', () => {
  describe('Subject announcements', () => {
    // LX-2162
    it.skip('shows the latest announcement, attachment, date, and edit button on the subject home', () => {
      const {getByText, getByRole} = render(<K5Course {...defaultProps} canManage={true} />)
      const button = getByRole('link', {name: 'Edit announcement Important announcement'})
      const attachment = getByRole('link', {name: 'hw.pdf'})
      const targetDate = new Date(`2021-${getOneMonthAgo()}-14T17:06:21Z`)
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

      expect(getByText('Important announcement')).toBeInTheDocument()
      expect(getByText('Read this closely.')).toBeInTheDocument()
      expect(button).toBeInTheDocument()
      expect(button.href).toContain('/courses/30/discussion_topics/12')
      expect(attachment).toBeInTheDocument()
      expect(attachment.href).toBe('http://address/to/hw.pdf')
      expect(getByText(new RegExp(`${datePortion} at ${timePortion}`, 'i'))).toBeInTheDocument()
    })

    it('hides the edit button if student', () => {
      const props = {...defaultProps}
      props.latestAnnouncement = {
        ...defaultProps.latestAnnouncement,
        permissions: {update: false},
      }
      const {queryByRole} = render(<K5Course {...props} />)
      expect(
        queryByRole('link', {name: 'Edit announcement Important announcement'}),
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

    it('shows an empty home state if the front page is not set', async () => {
      const {findByText, findByTestId} = render(
        <K5Course
          {...defaultProps}
          courseOverview={emptyCourseOverview}
          defaultTab={TAB_IDS.HOME}
        />,
      )
      expect(await findByTestId('empty-home-panda')).toBeInTheDocument()
      expect(
        await findByText("This is where you'll land when your home is complete."),
      ).toBeInTheDocument()
    })

    describe('manage home button', () => {
      it('shows the home manage button to teachers when the front page is not set ', () => {
        const {getByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
            canManage={true}
          />,
        )
        expect(getByTestId('manage-home-button')).toBeInTheDocument()
      })

      it('does not show the home manage button to students', () => {
        const {queryByTestId} = render(
          <K5Course
            {...defaultProps}
            courseOverview={emptyCourseOverview}
            defaultTab={TAB_IDS.HOME}
          />,
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
          />,
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
          />,
        )
        const manageHomeLink = getByTestId('manage-home-button')
        expect(manageHomeLink.href).toMatch('/courses/30/pages/home')
      })
    })
  })

  describe('Schedule tab', () => {
    // Skipped: PlannerPreview is lazy-loaded via React.lazy() and the dynamic
    // import doesn't resolve in Vitest test environment
    it.skip('shows a planner preview scoped to a single course if user has no student enrollments', async () => {
      const {findByTestId, getByText, queryByText} = render(
        <K5Course
          {...defaultProps}
          defaultTab={TAB_IDS.SCHEDULE}
          canManage={true}
          canReadAsAdmin={true}
          userIsStudent={false}
        />,
      )
      expect(await findByTestId('kinder-panda')).toBeInTheDocument()
      expect(getByText('Schedule Preview')).toBeInTheDocument()
      expect(
        getByText('Below is an example of how students will see their schedule'),
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
        <K5Course {...defaultProps} defaultTab={TAB_IDS.MODULES} />,
      )
      expect(
        getByText("Your modules will appear here after they're assembled."),
      ).toBeInTheDocument()
      expect(getByTestId('empty-modules-panda')).toBeInTheDocument()
      expect(contextModules).not.toBeVisible()
    })
  })
})
