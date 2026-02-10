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

import {MockedProvider} from '@apollo/client/testing'
import {render} from '@testing-library/react'
import React from 'react'
import DiscussionTopicToolbarContainer from '../DiscussionTopicToolbarContainer'
import {DiscussionManagerUtilityContext, SearchContext} from '../../../utils/constants'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
  openWindow: vi.fn(),
}))

vi.mock('../../../utils', async () => ({
  ...(await vi.importActual('../../../utils')),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
  hideStudentNames: false,
}))

beforeEach(() => {
  fakeENV.setup()
  window.matchMedia = vi.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
    }
  })

  ENV.FEATURES = {
    instui_nav: false,
  }
  ENV.current_user_is_student = false
})

afterEach(() => {
  fakeENV.teardown()
  vi.clearAllMocks()
})

const setup = (props: any) => {
  const searchContextValues = {
    searchTerm: '',
    filter: 'all',
    setSearchTerm: vi.fn(),
    setFilter: vi.fn(),
    pageNumber: 0,
    setPageNumber: vi.fn(),
    allThreadsStatus: 0,
    setAllThreadsStatus: vi.fn(),
    expandedThreads: [],
    setExpandedThreads: vi.fn(),
    perPage: '20',
    discussionID: '1',
  }

  const discussionManagerProviderValues = {
    replyFromId: '',
    setReplyFromId: vi.fn() as () => void,
    userSplitScreenPreference: false,
    setUserSplitScreenPreference: vi.fn() as () => void,
    highlightEntryId: '',
    setHighlightEntryId: vi.fn() as () => void,
    expandedThreads: '',
    setExpandedThreads: vi.fn() as () => void,
    focusSelector: '',
    setFocusSelector: vi.fn() as () => void,
    setPageNumber: vi.fn() as () => void,
    isGradedDiscussion: false,
    setIsGradedDiscussion: vi.fn() as () => void,
    usedThreadingToolbarChildRef: null,
    translationLanguages: {current: []},
    showTranslationControl: false,
    setShowTranslationControl: vi.fn() as () => void,
    isSearchLaunch: false,
    setIsSearchLaunch: vi.fn() as () => void,
    isSummaryEnabled: false,
  }

  return render(
    <MockedProvider mocks={[]} addTypename={false}>
      <DiscussionManagerUtilityContext.Provider value={discussionManagerProviderValues}>
        <SearchContext.Provider value={searchContextValues}>
          <DiscussionTopicToolbarContainer {...props} />
        </SearchContext.Provider>
      </DiscussionManagerUtilityContext.Provider>
    </MockedProvider>,
  )
}

const childTopicFixture = {
  _id: '2',
  title: 'Group 1',
  contextName: 'Group 1',
  contextId: '100',
  entryCounts: {unreadCount: 0},
}

const baseDiscussionTopic = {
  _id: '1',
  __typename: 'Discussion',
  title: 'Test Discussion',
  anonymousState: null,
  canReplyAnonymously: false,
  isAnnouncement: false,
  contextType: 'Course',
  sortOrderLocked: false,
  expandedLocked: false,
  assignment: null,
  groupSet: null,
  childTopics: [],
  rootTopic: null,
  participant: {
    sortOrder: 'asc',
    expanded: true,
  },
  permissions: {
    update: false,
    viewGroupPages: false,
    manageAssignTo: false,
  },
}

const breakpoints = {
  ICEDesktop: true,
  mobileOnly: false,
}

const defaultProps = {
  breakpoints,
  onSortClick: vi.fn(),
  sortDirection: 'asc',
}

describe('DiscussionTopicToolbarContainer', () => {
  describe('Group Discussions Navigation', () => {
    describe('root topic (has childTopics)', () => {
      const rootTopicDiscussion = {
        ...baseDiscussionTopic,
        groupSet: {_id: '1', name: 'Group Set 1'},
        childTopics: [childTopicFixture],
        permissions: {
          ...baseDiscussionTopic.permissions,
          viewGroupPages: true,
        },
      }

      it('shows the Group button for teachers', () => {
        ENV.current_user_is_student = false
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: rootTopicDiscussion,
        })
        expect(queryByTestId('groups-menu-button')).toBeInTheDocument()
      })

      it('does not show the Group button for students', () => {
        ENV.current_user_is_student = true
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: rootTopicDiscussion,
        })
        expect(queryByTestId('groups-menu-button')).not.toBeInTheDocument()
      })

      it('does not show the Group button when viewGroupPages is false', () => {
        ENV.current_user_is_student = false
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: {
            ...rootTopicDiscussion,
            permissions: {...rootTopicDiscussion.permissions, viewGroupPages: false},
          },
        })
        expect(queryByTestId('groups-menu-button')).not.toBeInTheDocument()
      })
    })

    describe('child topic (inside a group discussion)', () => {
      const childTopicDiscussion = {
        ...baseDiscussionTopic,
        childTopics: [],
        groupSet: null,
        permissions: {
          ...baseDiscussionTopic.permissions,
          viewGroupPages: false,
        },
        rootTopic: {
          _id: '1',
          groupSet: {_id: '1', name: 'Group Set 1'},
          childTopics: [childTopicFixture],
          permissions: {
            viewGroupPages: true,
          },
        },
      }

      it('shows the Group button for teachers using rootTopic permission', () => {
        ENV.current_user_is_student = false
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: childTopicDiscussion,
        })
        expect(queryByTestId('groups-menu-button')).toBeInTheDocument()
      })

      it('does not show the Group button for students', () => {
        ENV.current_user_is_student = true
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: childTopicDiscussion,
        })
        expect(queryByTestId('groups-menu-button')).not.toBeInTheDocument()
      })

      it('does not show the Group button when rootTopic.viewGroupPages is false', () => {
        ENV.current_user_is_student = false
        const {queryByTestId} = setup({
          ...defaultProps,
          discussionTopic: {
            ...childTopicDiscussion,
            rootTopic: {
              ...childTopicDiscussion.rootTopic,
              permissions: {viewGroupPages: false},
            },
          },
        })
        expect(queryByTestId('groups-menu-button')).not.toBeInTheDocument()
      })
    })
  })
})
