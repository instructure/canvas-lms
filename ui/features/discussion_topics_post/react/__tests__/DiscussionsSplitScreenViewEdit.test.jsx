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

describe('DiscussionsSplitScreenView Edit', () => {
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
  // The edit flow is adequately covered by:
  // - ThreadActions.test.jsx (tests onEdit callback)
  // - DiscussionsAttachment.test.jsx (tests updateDiscussionEntryMock mutation)
  // - SplitScreenParent.test.jsx (tests thread actions menu interactions)
  it.skip('should be able to edit a root entry', async () => {
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
      expect(setOnSuccess).toHaveBeenCalledWith('The reply was successfully updated.'),
    )
  })
})
