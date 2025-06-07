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

import '@instructure/canvas-theme'
import React from 'react'
import {render} from '@testing-library/react'
import {Provider} from 'react-redux'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import configureStore from '../../store'
import ExternalFeedsTray from '../ExternalFeedsTray'

const defaultProps = () => ({
  atomFeedUrl: 'www.test.com',
  permissions: {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  },
})

const renderWithRedux = ui => {
  const store = configureStore({})

  const result = render(<Provider store={store}>{ui}</Provider>)

  return result
}

const server = setupServer(
  http.get('/api/v1/courses/1/external_feeds', () => HttpResponse.json([])),
  http.get('/api/v1/*/external_feeds', () => HttpResponse.json([])),
)

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

it('renders the ExternalFeedsTray component', () => {
  const ref = React.createRef()
  const {getByText} = render(<ExternalFeedsTray {...defaultProps()} ref={ref} />)
  expect(ref.current).not.toBeNull()
  expect(getByText('External Feeds')).toBeInTheDocument()
})

it('renders the AddExternalFeed component when user has permissions', async () => {
  const props = defaultProps()
  props.permissions = {
    create: true,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = renderWithRedux(<ExternalFeedsTray {...props} defaultOpen={true} />)
  await tree.findByTestId('announcements-tray__content')
  expect(tree.getByTestId('announcements-tray__add-rss-root')).toBeInTheDocument()
})

it('does not render the AddExternalFeed component when user is student', async () => {
  const props = defaultProps()
  props.permissions = {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = renderWithRedux(<ExternalFeedsTray {...props} defaultOpen={true} />)
  await tree.findByTestId('announcements-tray__content')
  expect(tree.queryByTestId('announcements-tray__add-rss-root')).not.toBeInTheDocument()
})

it('does not render the RSSFeedList component when user is student', () => {
  const props = defaultProps()
  props.permissions = {
    create: false,
    manage_course_content_edit: false,
    manage_course_content_delete: false,
    moderate: false,
  }
  const tree = renderWithRedux(<ExternalFeedsTray {...props} defaultOpen={true} />)
  expect(tree.queryByTestId('external-rss-feed')).not.toBeInTheDocument()
})

it('renders the external feeds link', async () => {
  const tree = renderWithRedux(<ExternalFeedsTray {...defaultProps()} defaultOpen={true} />)
  expect(await tree.findByTestId('external-feed-link')).toBeInTheDocument()
  expect(tree.getAllByText('External Feeds')).toHaveLength(2) // the Link and the Tray
})

it('renders the RSS feed link', async () => {
  const tree = renderWithRedux(<ExternalFeedsTray {...defaultProps()} defaultOpen={true} />)
  expect(await tree.findByTestId('rss-feed-link')).toBeInTheDocument()
  expect(tree.getByText('RSS Feed')).toBeInTheDocument()
})
