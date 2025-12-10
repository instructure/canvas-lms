// Copyright (C) 2020 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import {replaceLocation} from '@canvas/util/globalUtils'
import {fireEvent, render as testingLibraryRender, waitFor} from '@testing-library/react'
import React from 'react'
import HelpLinks from '../HelpLinks'
import {setupServer} from 'msw/node'
import {http, HttpResponse} from 'msw'

jest.mock('@canvas/util/globalUtils', () => ({
  replaceLocation: jest.fn(),
}))

const server = setupServer()

const render = children =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

describe('HelpLinks', () => {
  const featuredLink = {
    id: 'search_the_canvas_guides',
    type: 'default',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    text: 'Search the Canvas Guides',
    subtext: 'Find answers to common questions',
    url: 'https://community.canvaslms.test/t5/Canvas/ct-p/canvas',
    is_featured: true,
    is_new: false,
    feature_headline: 'Little Lost? Try here first!',
  }
  const newLink = {
    id: 'link1',
    text: 'Google',
    subtext: 'Have you tried google?',
    url: 'https://google.com',
    type: 'custom',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    is_featured: false,
    is_new: true,
  }
  const regularLink = {
    id: 'report_a_problem',
    type: 'default',
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    text: 'Report a Problem',
    subtext: 'If Canvas misbehaves, tell us about it',
    url: '#create_ticket',
    is_featured: false,
    is_new: false,
  }
  const noWindowLink = {
    id: 'inline_help_link',
    type: 'default',
    no_new_window: true,
    available_to: ['user', 'student', 'teacher', 'admin', 'observer', 'unenrolled'],
    text: 'Support Centre',
    subtext: 'Ask ur question',
    url: '?enjoy=this',
    is_featured: false,
    is_new: false,
  }
  const props = {
    onClick() {},
  }

  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    // Default handler for any help links API calls
    server.use(
      http.get('/api/v1/accounts/*/help_links', () => HttpResponse.json([])),
    )
    queryClient.setQueryData(['helpLinks'], [featuredLink, newLink, regularLink])
  })

  afterEach(() => {
    server.resetHandlers()
    jest.clearAllMocks()
  })

  it('renders all the links', () => {
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('Google')).toBeInTheDocument()
    expect(queryByText('Search the Canvas Guides')).toBeInTheDocument()
    expect(queryByText('Report a Problem')).toBeInTheDocument()
  })

  it('renders the separator when there is a featured link, additional links, and the FF is enabled', () => {
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('OTHER RESOURCES')).toBeInTheDocument()
  })

  it('does not render the separator if there is no featured link', () => {
    queryClient.setQueryData(['helpLinks'], [newLink, regularLink])
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('OTHER RESOURCES')).not.toBeInTheDocument()
  })

  it('does not render the separator if there is only a featured link', () => {
    queryClient.setQueryData(['helpLinks'], [featuredLink])
    const {queryByText} = render(<HelpLinks {...props} links={[featuredLink]} />)
    expect(queryByText('OTHER RESOURCES')).not.toBeInTheDocument()
  })

  it('tries to load a new URL in place if the no_new_window flag is set', async () => {
    queryClient.setQueryData(['helpLinks'], [featuredLink, newLink, regularLink, noWindowLink])
    const {getByText} = render(<HelpLinks {...props} />)
    const link = getByText('Support Centre')
    fireEvent.click(link)
    await waitFor(() => expect(replaceLocation).toHaveBeenCalledWith('?enjoy=this'))
  })

  it('renders a "NEW" pill when a link is tagged with is_new', () => {
    const expectedPillId = `help-link-${newLink.id}`
    queryClient.setQueryData(['helpLinks'], [newLink])
    const {queryByText, getByText} = render(<HelpLinks {...props} />)

    // Verify the "NEW" pill is rendered
    const pillElement = queryByText('NEW')?.closest('span')
    expect(pillElement).toBeInTheDocument()
    expect(pillElement).toHaveTextContent('NEW')

    // Verify that the pill has the right id
    const pillId = pillElement?.getAttribute('id')
    expect(pillId).toBe(expectedPillId)

    // Verify the Link has the corresponding aria-describedby attribute
    const linkElement = getByText('Google')
    expect(linkElement).toHaveAttribute('aria-describedby', expectedPillId)
  })

  it('does not render a "NEW" pill if there is no link tagged with is_new', () => {
    queryClient.setQueryData(['helpLinks'], [featuredLink, regularLink])
    const {queryByText} = render(<HelpLinks {...props} />)
    expect(queryByText('NEW')).not.toBeInTheDocument()
  })
})
