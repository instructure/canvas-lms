/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import {Provider} from 'react-redux'
import AddExternalFeed from '../AddExternalFeed'

const defaultProps = () => ({
  defaultOpen: false,
  isSaving: false,
  addExternalFeed: () => {},
})

const mockStore = {
  getState: () => ({
    externalRssFeed: {
      feeds: [],
      hasLoadedFeed: false,
    },
  }),
  subscribe: () => () => {},
  dispatch: () => {},
}

const renderWithProvider = component => render(<Provider store={mockStore}>{component}</Provider>)

test('renders the AddExternalFeed component', () => {
  const {container} = renderWithProvider(<AddExternalFeed {...defaultProps()} />)
  expect(container).toBeTruthy()
})

test('does not show cancel button when tray is closed', () => {
  const {queryByTestId} = renderWithProvider(<AddExternalFeed {...defaultProps()} />)
  expect(queryByTestId('external-rss-feed__cancel-button')).not.toBeInTheDocument()
})

test('shows submit button when tray is open', () => {
  const props = defaultProps()
  props.defaultOpen = true
  const {getByTestId} = renderWithProvider(<AddExternalFeed {...props} />)
  expect(getByTestId('add-external-feed-button')).toBeInTheDocument()
})

test('closes the tray when cancel button is clicked', async () => {
  const user = userEvent.setup()
  const props = defaultProps()
  props.defaultOpen = true
  const {getByTestId, queryByTestId} = renderWithProvider(<AddExternalFeed {...props} />)

  const cancelButton = getByTestId('cancel-external-feed-button')
  await user.click(cancelButton)

  // Check that the Add Feed button is no longer visible (tray is closed)
  expect(queryByTestId('add-external-feed-button')).not.toBeInTheDocument()
})

test('submits feed with correct data when form is filled and submitted', async () => {
  const user = userEvent.setup()
  const addFeedSpy = vi.fn()
  const props = defaultProps()
  props.defaultOpen = true
  props.addExternalFeed = addFeedSpy

  const {getByTestId, getByLabelText, getByPlaceholderText} = renderWithProvider(
    <AddExternalFeed {...props} />,
  )

  // Fill out the URL field
  const urlInput = getByPlaceholderText(/URL/i)
  await user.type(urlInput, 'https://example.com/feed.rss')

  // Check the phrase checkbox
  const phraseCheckbox = getByLabelText(/only add posts with a specific phrase/i)
  await user.click(phraseCheckbox)

  // Fill out the phrase field
  const phraseInput = getByPlaceholderText(/enter specific phrase/i)
  await user.type(phraseInput, 'test phrase')

  // Select verbosity option
  const fullArticleRadio = getByLabelText(/full article/i)
  await user.click(fullArticleRadio)

  // Submit the form
  const addButton = getByTestId('add-external-feed-button')
  await user.click(addButton)

  expect(addFeedSpy).toHaveBeenCalledWith({
    header_match: 'test phrase',
    url: 'https://example.com/feed.rss',
    verbosity: 'full',
  })
})

test('enables submit button when required fields are filled', async () => {
  const user = userEvent.setup()
  const props = defaultProps()
  props.defaultOpen = true
  const {getByTestId, getByLabelText, getByPlaceholderText} = renderWithProvider(
    <AddExternalFeed {...props} />,
  )

  const addButton = getByTestId('add-external-feed-button')
  expect(addButton).toBeDisabled()

  // Fill out the required URL field
  const urlInput = getByPlaceholderText(/URL/i)
  await user.type(urlInput, 'https://example.com/feed.rss')

  expect(addButton).toBeEnabled()

  // Check the phrase checkbox (makes phrase field required)
  const phraseCheckbox = getByLabelText(/only add posts with a specific phrase/i)
  await user.click(phraseCheckbox)

  expect(addButton).toBeDisabled()

  // Fill out the phrase field
  const phraseInput = getByPlaceholderText(/enter specific phrase/i)
  await user.type(phraseInput, 'test phrase')

  expect(addButton).toBeEnabled()
})

test('keeps submit button disabled when URL is missing', async () => {
  const props = defaultProps()
  props.defaultOpen = true
  const {getByTestId} = renderWithProvider(<AddExternalFeed {...props} />)

  const addButton = getByTestId('add-external-feed-button')
  expect(addButton).toBeDisabled()
})

test('keeps submit button disabled when phrase is required but missing', async () => {
  const user = userEvent.setup()
  const props = defaultProps()
  props.defaultOpen = true
  const {getByTestId, getByLabelText, getByPlaceholderText} = renderWithProvider(
    <AddExternalFeed {...props} />,
  )

  // Fill out URL
  const urlInput = getByPlaceholderText(/URL/i)
  await user.type(urlInput, 'https://example.com/feed.rss')

  // Check the phrase checkbox (makes phrase field required)
  const phraseCheckbox = getByLabelText(/only add posts with a specific phrase/i)
  await user.click(phraseCheckbox)

  const addButton = getByTestId('add-external-feed-button')
  expect(addButton).toBeDisabled()
})
