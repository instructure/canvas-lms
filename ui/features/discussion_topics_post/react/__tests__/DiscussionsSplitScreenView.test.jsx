/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {
  getDiscussionQueryMock,
  getDiscussionSubentriesQueryMock,
  updateDiscussionEntryMock,
} from '../../graphql/Mocks'
import DiscussionTopicManager from '../DiscussionTopicManager'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))
jest.mock('../utils/constants', () => ({
  ...jest.requireActual('../utils/constants'),
  SEARCH_TERM_DEBOUNCE_DELAY: 0,
}))

describe('DiscussionsSplitScreenView', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  beforeAll(() => {
    window.ENV = {
      per_page: 20,
      split_screen_view_initial_page_size: 5,
      current_page: 0,
      discussion_topic_id: '1',
      course_id: '1',
      current_user: {
        id: '2',
        avatar_image_url:
          'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==',
        display_name: 'Hank Mccoy',
      },
      DISCUSSION: {
        preferences: {
          discussions_splitscreen_view: true,
        },
      },
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn(),
      }
    })
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  const setup = mocks => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicManager discussionTopicId="Discussion-default-mock" />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  it('should render split screen view view container', async () => {
    const mocks = [...getDiscussionQueryMock()]
    const container = setup(mocks)
    const replyButton = await container.findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)
    expect(container.queryByTestId('discussions-split-screen-view-content')).toBeTruthy()
  })

  it('should render Split-screen view container if split-screen and isolated view FF are enabled', async () => {
    window.ENV.isolated_view = true
    const mocks = [...getDiscussionQueryMock()]
    const container = setup(mocks)
    const replyButton = await container.findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)
    expect(container.queryByTestId('isolated-view-container')).toBeNull()
    expect(container.queryByTestId('discussions-split-screen-view-content')).toBeTruthy()
  })

  it('should be able to edit a root entry', async () => {
    const mocks = [
      ...getDiscussionQueryMock(),
      ...getDiscussionSubentriesQueryMock({
        includeRelativeEntry: false,
        last: 5,
      }),
      ...getDiscussionSubentriesQueryMock({
        beforeRelativeEntry: false,
        first: 0,
        includeRelativeEntry: false,
      }),
      ...updateDiscussionEntryMock(),
    ]
    const {findByText, findByTestId, findAllByTestId} = setup(mocks)

    const expandButton = await findByTestId('expand-button')
    fireEvent.click(expandButton)

    const actionsButtons = await findAllByTestId('thread-actions-menu')
    fireEvent.click(actionsButtons[0]) // Root Entry kebab

    const editButton = await findByText('Edit')
    fireEvent.click(editButton)

    const saveButton = await findByText('Save')
    fireEvent.click(saveButton)

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The reply was successfully updated.')
    )
  }, 10000)

  it('should not render go to reply button with single character search term', async () => {
    const mocks = [
      ...getDiscussionQueryMock(),
      ...getDiscussionQueryMock({searchTerm: 'a', rootEntries: false}),
    ]
    const container = setup(mocks)
    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'a'},
    })

    await waitFor(() => expect(container.queryByTestId('go-to-reply')).toBeNull())
  })

  it('should clear input when button is pressed', async () => {
    const mocks = [
      ...getDiscussionQueryMock(),
      ...getDiscussionQueryMock({searchTerm: 'A new Search', rootEntries: false}),
      ...getDiscussionQueryMock(),
    ]
    const container = setup(mocks)
    let searchInput = container.findByTestId('search-filter')

    fireEvent.change(await container.findByTestId('search-filter'), {
      target: {value: 'A new Search'},
    })
    let clearSearchButton = container.queryByTestId('clear-search-button')
    searchInput = container.getByLabelText('Search entries or author...')
    expect(searchInput.value).toBe('A new Search')
    expect(clearSearchButton).toBeInTheDocument()

    fireEvent.click(clearSearchButton)
    clearSearchButton = container.queryByTestId('clear-search-button')
    searchInput = container.getByLabelText('Search entries or author...')
    expect(searchInput.value).toBe('')
    expect(clearSearchButton).toBeNull()
  })
})
