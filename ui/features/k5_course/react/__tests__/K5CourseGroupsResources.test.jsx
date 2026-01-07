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
import {act, render, waitFor} from '@testing-library/react'
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
  FETCH_IMPORTANT_INFO_URL,
  FETCH_APPS_URL,
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
  describe('Groups tab', () => {
    describe('user is a student', () => {
      it('fetches and displays group information', async () => {
        const {findByText, getByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.GROUPS} />,
        )
        expect(await findByText('Fight Club')).toBeInTheDocument()
        ;['Student Clubs', '0 students'].forEach(t => expect(getByText(t)).toBeInTheDocument())
      })
    })

    describe('user is an instructor', () => {
      it('displays welcome page', () => {
        const {getByText} = render(
          <K5Course {...defaultProps} canReadAsAdmin={true} defaultTab={TAB_IDS.GROUPS} />,
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
            />,
          )
          expect(getByText('Manage Groups')).toBeInTheDocument()
        })
      })

      describe('can not manage groups', () => {
        it('displays a View Groups button', () => {
          const {getByText} = render(
            <K5Course {...defaultProps} canReadAsAdmin={true} defaultTab={TAB_IDS.GROUPS} />,
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
          <K5Course {...defaultProps} canManage={true} defaultTab={TAB_IDS.RESOURCES} />,
        )
        expect(await findByText('This is really important.')).toBeInTheDocument()
        const editLink = getByRole('link', {name: 'Edit important info for Arts and Crafts'})
        expect(editLink).toBeInTheDocument()
        expect(editLink.href).toContain('/courses/30/assignments/syllabus')
      })

      it("doesn't show an edit button if not canManage", async () => {
        const {findByText, queryByRole} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />,
        )
        expect(await findByText('This is really important.')).toBeInTheDocument()
        expect(
          queryByRole('link', {name: 'Edit important info for Arts and Crafts'}),
        ).not.toBeInTheDocument()
      })

      it('shows loading skeletons while loading', async () => {
        const {getByText, queryByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />,
        )
        expect(getByText('Loading important info')).toBeInTheDocument()
        await waitFor(() => {
          expect(queryByText('Loading important info')).not.toBeInTheDocument()
        })
      })

      it('shows an error if syllabus content fails to load', async () => {
        fetchMock.get(FETCH_IMPORTANT_INFO_URL, 400, {overwriteRoutes: true})
        const {findAllByText} = render(
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />,
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
          <K5Course {...defaultProps} defaultTab={TAB_IDS.RESOURCES} />,
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
        <K5Course {...defaultProps} defaultTab={TAB_IDS.HOME} />,
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
})
