/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'
import fakeENV from '@canvas/test-utils/fakeENV'
import PortfolioPortal from '../PortfolioPortal'

const portfolio = {
  id: 1,
  name: 'Test Portfolio',
  public: true,
  profile_url: '/users/1',
}

const sections = [
  {id: 10, name: 'Home', position: 1, category_url: '/eportfolios/1/home'},
  {id: 11, name: 'About Me', position: 2, category_url: '/eportfolios/1/about'},
]

const server = setupServer(
  http.get('/eportfolios/1', () => HttpResponse.json(portfolio)),
  http.get('/eportfolios/1/categories', () => HttpResponse.json(sections)),
)

describe('PortfolioPortal', () => {
  let queryClient: QueryClient
  let sectionListNode: HTMLElement
  let pageListNode: HTMLElement

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    fakeENV.setup({owner_view: false, category_id: 10})
    queryClient = new QueryClient({defaultOptions: {queries: {retry: false}}})
    sectionListNode = document.createElement('div')
    pageListNode = document.createElement('div')
    document.body.appendChild(sectionListNode)
    document.body.appendChild(pageListNode)
  })

  afterEach(() => {
    queryClient.clear()
    fakeENV.teardown()
    sectionListNode.remove()
    pageListNode.remove()
  })

  it('renders section list when submissionNode is null', async () => {
    render(
      <QueryClientProvider client={queryClient}>
        <PortfolioPortal
          portfolioId={1}
          sectionListNode={sectionListNode}
          pageListNode={pageListNode}
          submissionNode={null}
          onPageUpdate={vi.fn()}
        />
      </QueryClientProvider>,
    )

    expect(await screen.findByText('Home')).toBeInTheDocument()
    expect(await screen.findByText('About Me')).toBeInTheDocument()
  })
})
