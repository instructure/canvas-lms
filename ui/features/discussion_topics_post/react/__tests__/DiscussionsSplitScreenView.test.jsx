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
import {getDiscussionQueryMock} from '../../graphql/Mocks'
import DiscussionTopicManager from '../DiscussionTopicManager'
import {fireEvent, render} from '@testing-library/react'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import React from 'react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import {MockedQueryProvider} from '@canvas/test-utils/query'
import fakeENV from '@canvas/test-utils/fakeENV'

injectGlobalAlertContainers()

vi.mock('@canvas/rce/RichContentEditor')
vi.mock('../utils', async () => {
  const actual = await vi.importActual('../utils')
  return {
    ...actual,
    responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
  }
})
vi.mock('../utils/constants', async () => {
  const actual = await vi.importActual('../utils/constants')
  return {
    ...actual,
    SEARCH_TERM_DEBOUNCE_DELAY: 0,
  }
})

describe('DiscussionsSplitScreenView', () => {
  const setOnFailure = vi.fn()
  const setOnSuccess = vi.fn()

  beforeAll(() => {
    fakeENV.setup({
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
    })

    window.matchMedia = vi.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: vi.fn(),
        removeListener: vi.fn(),
      }
    })
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
  })

  const setup = mocks => {
    return render(
      <MockedQueryProvider>
        <MockedProvider mocks={mocks}>
          <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
            <DiscussionTopicManager discussionTopicId="Discussion-default-mock" />
          </AlertManagerContext.Provider>
        </MockedProvider>
      </MockedQueryProvider>,
    )
  }

  // Skip: This full-integration test through DiscussionTopicManager times out in CI (5s limit).
  // The split screen view opening flow is adequately covered by:
  // - SplitScreenViewContainer.test.jsx (tests reply button clicks, view rendering)
  // - Reply.test.jsx (tests reply button component behavior)
  it.skip('should render split screen view view container', async () => {
    const mocks = [...getDiscussionQueryMock()]
    const container = setup(mocks)
    const replyButton = await container.findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)
    expect(container.queryByTestId('discussions-split-screen-view-content')).toBeTruthy()
  })

  // Skip: Same as above - times out in CI due to full DiscussionTopicManager render.
  // Feature flag behavior is tested at the unit level in SplitScreenViewContainer.test.jsx.
  it.skip('should render Split-screen view container if split-screen and isolated view FF are enabled', async () => {
    window.ENV.isolated_view = true
    const mocks = [...getDiscussionQueryMock()]
    const container = setup(mocks)
    const replyButton = await container.findByTestId('threading-toolbar-reply')
    fireEvent.click(replyButton)
    expect(container.queryByTestId('isolated-view-container')).toBeNull()
    expect(container.queryByTestId('discussions-split-screen-view-content')).toBeTruthy()
    delete window.ENV.isolated_view
  })

  // Note: "go-to-reply" button never renders in split screen view (isSplitView=true)
  // This is tested at the unit level in ThreadingToolbar.test.jsx

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
