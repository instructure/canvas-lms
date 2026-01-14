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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {MockedProviderWithPossibleTypes as MockedProvider} from '@canvas/util/react/testing/MockedProviderWithPossibleTypes'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import fakeENV from '@canvas/test-utils/fakeENV'
import useManagedCourseSearchApi from '../../../../../../shared/direct-sharing/react/effects/useManagedCourseSearchApi'
import {Discussion} from '../../../../graphql/Discussion'
import {responsiveQuerySizes} from '../../../utils'
import {DiscussionTopicContainer} from '../DiscussionTopicContainer'
import {ObserverContext} from '../../../utils/ObserverContext'

// Mock to avoid issues with React.lazy in DirectShareUserModal
vi.mock(
  '../../../../../../shared/direct-sharing/react/components/DirectShareUserPanel',
  () => ({
    default: () => (
      <div data-testid="mock-user-panel">
        <label>
          Send to:
          <input data-testid="user-search-input" />
        </label>
      </div>
    ),
  }),
)

// Mock the lazy-loaded component to avoid dynamic import issues in tests
vi.mock(
  '../../../../../../shared/direct-sharing/react/components/DirectShareCoursePanel',
  () => ({
    default: () => (
      <div data-testid="mock-course-panel">
        <span>Select a Course</span>
      </div>
    ),
  }),
)

vi.mock('../../../../../../shared/direct-sharing/react/effects/useManagedCourseSearchApi')
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('../../../utils', async () => ({
  ...(await vi.importActual('../../../utils')),
  responsiveQuerySizes: vi.fn(),
}))

describe('DiscussionTopicContainer Modal Tests', () => {
  const setOnFailure = vi.fn()
  const setOnSuccess = vi.fn()
  let liveRegion = null

  beforeAll(() => {
    fakeENV.setup({
      EDIT_URL: 'this_is_the_edit_url',
      PEER_REVIEWS_URL: 'this_is_the_peer_reviews_url',
      context_asset_string: 'course_1',
      course_id: '1',
      context_type: 'Course',
      context_id: '1',
      discussion_topic_menu_tools: [
        {
          base_url: 'example.com',
          canvas_icon_class: 'icon-commons',
          id: '1',
          title: 'Share to Commons',
        },
      ],
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

    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    window.INST = {
      editorButtons: [],
    }
  })

  beforeEach(() => {
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {maxWidth: '1000px'},
    }))
    useManagedCourseSearchApi.mockImplementation(() => {})
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
    vi.clearAllMocks()
  })

  afterAll(() => {
    if (liveRegion) {
      liveRegion.remove()
    }
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <ObserverContext.Provider
            value={{observerRef: {current: undefined}, nodesRef: {current: new Map()}}}
          >
            <DiscussionTopicContainer {...props} />
          </ObserverContext.Provider>
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
  }

  it('renders a modal to send content', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)

    const sendToButton = await container.findByText('Send To...')
    fireEvent.click(sendToButton)
    expect(await container.findByText('Send to:')).toBeInTheDocument()
  })

  it('renders a modal to copy content', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)

    const copyToButton = await container.findByText('Copy To...')
    fireEvent.click(copyToButton)
    expect(await container.findByText('Select a Course')).toBeInTheDocument()
  })
})
