/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {ActionButton} from '../action_button'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

const server = setupServer()

const generateMigrationIssues = (length: number) => {
  const data = []
  for (let i = 1; i <= length; i++) {
    data.push({
      id: i,
      description: `My description ${i}`,
      workflow_state: 'active',
      fix_issue_html_url: 'https://mock.fix.url',
      issue_type: 'error',
      created_at: '1997-04-15T00:00:00Z',
      updated_at: '1997-04-15T00:00:00Z',
      content_migration_url: 'https://mock.migration.url',
      error_message: `My error message${i}`,
    })
  }
  return data
}

const renderComponent = (overrideProps?: any) =>
  render(
    <ActionButton
      migration_type_title="Canvas Cartridge Importer"
      migration_issues_count={1}
      migration_issues_url="https://mock.issues.url"
      {...{...overrideProps}}
    />,
  )

describe('ActionButton', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())
  afterEach(() => {
    server.resetHandlers()
    vi.clearAllMocks()
  })

  it('renders button when issues count is greater than zero', () => {
    renderComponent()
    expect(screen.getByRole('button', {name: 'View Issues'})).toBeInTheDocument()
  })

  it('does not render button when issues count is zero', () => {
    renderComponent({migration_issues_count: 0})
    expect(screen.queryByRole('button', {name: 'View Issues'})).not.toBeInTheDocument()
  })

  describe('modal', () => {
    beforeEach(() => {
      server.use(
        http.get('https://mock.issues.url', () => HttpResponse.json(generateMigrationIssues(1))),
      )
    })

    it('opens on click', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      expect(
        screen.getByRole('heading', {name: 'Canvas Cartridge Importer Issues'}),
      ).toBeInTheDocument()
    })

    it('fetch issues list', async () => {
      let requestMade = false
      server.use(
        http.get('https://mock.issues.url', () => {
          requestMade = true
          return HttpResponse.json(generateMigrationIssues(1))
        }),
      )

      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      await waitFor(() => expect(requestMade).toBe(true))
    })

    it('shows issues list', async () => {
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
      const link = await screen.findByRole('link')
      expect(link).toHaveAttribute('href', 'https://mock.fix.url')
      expect(link).toHaveTextContent('My description 1')
    })

    describe('has more issues', () => {
      beforeEach(() => {
        const issues = generateMigrationIssues(15)
        const page1 = issues.slice(0, 10)
        const page2 = issues.slice(10, 15)
        let callCount = 0
        server.use(
          http.get('https://mock.issues.url/*', ({request}) => {
            callCount++
            const url = new URL(request.url)
            const page = url.searchParams.get('page')
            if (page === '2') {
              return HttpResponse.json(page2)
            }
            return HttpResponse.json(page1)
          }),
        )
      })

      it('shows "Show More" button', async () => {
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        expect(await screen.findByRole('button', {name: 'Show More'})).toBeInTheDocument()
      })

      it('"Show More" button calls fetch', async () => {
        let page2Requested = false
        server.use(
          http.get('https://mock.issues.url/*', ({request}) => {
            const url = new URL(request.url)
            const page = url.searchParams.get('page')
            if (page === '2') {
              page2Requested = true
              return HttpResponse.json(generateMigrationIssues(15).slice(10, 15))
            }
            return HttpResponse.json(generateMigrationIssues(15).slice(0, 10))
          }),
        )

        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        await waitFor(() => expect(page2Requested).toBe(true))
      })

      it('"Show More" updates issues list', async () => {
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        expect(await screen.findByRole('link', {name: 'My description 1'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 2'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 3'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 4'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 5'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 6'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 7'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 8'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 9'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 10'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 11'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 12'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 13'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 14'})).toBeInTheDocument()
        expect(await screen.findByRole('link', {name: 'My description 15'})).toBeInTheDocument()
      })

      it('shows alert if fetch fails', async () => {
        let callCount = 0
        server.use(
          http.get('https://mock.issues.url/*', ({request}) => {
            callCount++
            if (callCount === 1) {
              return HttpResponse.json(generateMigrationIssues(10))
            }
            return new HttpResponse(null, {status: 500})
          }),
        )
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))

        expect(
          await screen.findByText('Failed to fetch migration issues data.'),
        ).toBeInTheDocument()
      })

      it('shows spinner when loading more issues', async () => {
        let callCount = 0
        server.use(
          http.get('https://mock.issues.url/*', async () => {
            callCount++
            if (callCount === 1) {
              return HttpResponse.json(generateMigrationIssues(10))
            }
            await new Promise(resolve => setTimeout(resolve, 5000))
            return HttpResponse.json(generateMigrationIssues(5))
          }),
        )
        renderComponent({migration_issues_count: 15})
        await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))
        await userEvent.click(await screen.findByRole('button', {name: 'Show More'}))
        expect(screen.getByText('Loading more issues')).toBeInTheDocument()
      })
    })

    it('shows alert if fetch fails', async () => {
      server.use(http.get('https://mock.issues.url', () => new HttpResponse(null, {status: 500})))
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))

      expect(await screen.findByText('Failed to fetch migration issues data.')).toBeInTheDocument()
    })

    it('shows spinner when loading', async () => {
      server.use(
        http.get(
          'https://mock.issues.url',
          () => new Promise(resolve => setTimeout(resolve, 5000)),
        ),
      )
      renderComponent()
      await userEvent.click(screen.getByRole('button', {name: 'View Issues'}))

      expect(screen.getByText('Loading issues')).toBeInTheDocument()
    })

    it('closes with x button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      await user.click(screen.getByRole('button', {name: 'View Issues'}))
      const xButton = screen.queryAllByText('Close')[0]
      await user.click(xButton)

      await waitFor(() => {
        expect(
          screen.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'}),
        ).not.toBeInTheDocument()
      })
    })

    it('closes with close button', async () => {
      const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
      renderComponent()
      await user.click(screen.getByRole('button', {name: 'View Issues'}))
      const closeButton = screen.queryAllByText('Close')[1]
      await user.click(closeButton)

      await waitFor(() => {
        expect(
          screen.queryByRole('heading', {name: 'Canvas Cartridge Importer Issues'}),
        ).not.toBeInTheDocument()
      })
    })
  })
})
