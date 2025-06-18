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

import {MockedProvider} from '@apollo/client/testing'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {waitFor} from '@testing-library/dom'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {ChildTopic} from '../../../../graphql/ChildTopic'
import {updateUserDiscussionsSplitscreenViewMock} from '../../../../graphql/Mocks'
import {DiscussionManagerUtilityContext, SearchContext} from '../../../utils/constants'
import {DiscussionPostToolbar} from '../DiscussionPostToolbar'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
  openWindow: jest.fn(),
}))

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

jest.mock('../../../utils/constants', () => ({
  ...jest.requireActual('../../../utils/constants'),
  isSpeedGraderInTopUrl: false,
}))

const onFailureStub = jest.fn()
const onSuccessStub = jest.fn()

beforeEach(() => {
  fakeENV.setup()
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })

  ENV.course_id = '1'
  ENV.SPEEDGRADER_URL_TEMPLATE = '/courses/1/gradebook/speed_grader?assignment_id=1&:student_id'
  ENV.DISCUSSION = {
    preferences: {
      discussions_splitscreen_view: false,
    },
  }
})

afterEach(() => {
  fakeENV.teardown()
  onFailureStub.mockClear()
  onSuccessStub.mockClear()
  jest.clearAllMocks()
})

const setup = (
  props,
  mocks,
  discussionManagerProviderValues = {translationLanguages: {current: []}},
) => {
  const searchContextValues = {
    setAllThreadsStatus: jest.fn(),
    setExpandedThreads: jest.fn(),
  }

  return render(
    <MockedProvider mocks={mocks} addTypename={false}>
      <AlertManagerContext.Provider
        value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
      >
        <DiscussionManagerUtilityContext.Provider value={discussionManagerProviderValues}>
          <SearchContext.Provider value={searchContextValues}>
            <DiscussionPostToolbar {...props} />
          </SearchContext.Provider>
        </DiscussionManagerUtilityContext.Provider>
      </AlertManagerContext.Provider>
    </MockedProvider>,
  )
}

describe('DiscussionPostToolbar', () => {
  describe('Rendering', () => {
    it('should render', () => {
      const component = setup()
      expect(component).toBeTruthy()
    })

    it('should not render Collapse Toggle by default', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('collapseToggle')).toBeNull()
    })

    it('should not render clear search button by default', () => {
      const {queryByTestId} = setup()
      expect(queryByTestId('clear-search-button')).toBeNull()
    })
    describe('when the threads are inline', () => {
      describe('when threads are expanded', () => {
        it('should add pendo action id properly', () => {
          const {getByTestId} = setup(
            {
              setUserSplitScreenPreference: jest.fn(),
              userSplitScreenPreference: false,
              isExpanded: true,
            },
            updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
          )

          const collapseButton = getByTestId('ExpandCollapseThreads-button')
          expect(collapseButton).toHaveAttribute('data-action-state', 'collapseButton')
        })
      })

      describe('when the threads are collapsed', () => {
        it('should add pendo action id properly', () => {
          const {getByTestId} = setup(
            {
              setUserSplitScreenPreference: jest.fn(),
              userSplitScreenPreference: false,
              isExpanded: false,
            },
            updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
          )

          const collapseButton = getByTestId('ExpandCollapseThreads-button')
          expect(collapseButton).toHaveAttribute('data-action-state', 'expandButton')
        })
      })
    })
  })

  describe('Splitscreen Button', () => {
    describe('when user preference is to be split screen', () => {
      it('should render the button with the proper pendo attribute for further event tracking', async () => {
        const {getByTestId} = setup(
          {
            setUserSplitScreenPreference: jest.fn(),
            userSplitScreenPreference: true,
            closeView: jest.fn(),
          },
          updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
        )

        const splitscreenButton = getByTestId('splitscreenButton')
        expect(splitscreenButton).toHaveAttribute('data-action-state', 'splitscreenButtonToInline')
      })
    })

    describe('when user preference is to be inline', () => {
      it('should render the button with the proper pendo attribute for further event tracking', async () => {
        const {getByTestId} = setup(
          {
            setUserSplitScreenPreference: jest.fn(),
            userSplitScreenPreference: false,
            closeView: jest.fn(),
          },
          updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
        )

        const splitscreenButton = getByTestId('splitscreenButton')
        expect(splitscreenButton).toHaveAttribute('data-action-state', 'splitscreenButtonToSplit')
      })

      it('should call updateUserDiscussionsSplitscreenView mutation when clicked', async () => {
        const setUserSplitScreenPreferenceMock = jest.fn()
        const closeViewMock = jest.fn()

        const mocks = updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true})

        const {getByTestId} = setup(
          {
            setUserSplitScreenPreference: setUserSplitScreenPreferenceMock,
            userSplitScreenPreference: false,
            closeView: closeViewMock,
          },
          mocks,
        )

        const splitscreenButton = getByTestId('splitscreenButton')
        fireEvent.click(splitscreenButton)

        await waitFor(() => {
          expect(onSuccessStub).toHaveBeenCalledWith('Splitscreen preference updated!')
        })

        expect(setUserSplitScreenPreferenceMock).toHaveBeenCalledWith(true)
      })
    })
  })

  describe('Search Field', () => {
    it('should call onChange when typing occurs', async () => {
      const onSearchChangeMock = jest.fn()
      const {getByLabelText} = setup({onSearchChange: onSearchChangeMock})
      const searchInput = getByLabelText('Search entries or author...')

      fireEvent.change(searchInput, {target: {value: 'A'}})
      await waitFor(() => {
        expect(onSearchChangeMock).toHaveBeenCalledTimes(1)
      })

      fireEvent.change(searchInput, {target: {value: 'B'}})
      await waitFor(() => {
        expect(onSearchChangeMock).toHaveBeenCalledTimes(2)
      })
    })
  })

  describe('View Dropdown', () => {
    it('should call onChange when event is fired', () => {
      const onViewFilterMock = jest.fn()
      const {getByText, getByLabelText} = setup({onViewFilter: onViewFilterMock})
      const simpleSelect = getByLabelText('Filter by')
      fireEvent.click(simpleSelect)
      const unread = getByText('Unread')
      fireEvent.click(unread)
      expect(onViewFilterMock.mock.calls).toHaveLength(1)
      expect(onViewFilterMock.mock.calls[0][1].id).toBe('unread')
    })
  })

  describe('Sort control', () => {
    it('should show up arrow when ascending', () => {
      const {getByTestId} = setup({
        sortDirection: 'asc',
      })
      const upArrow = getByTestId('UpArrow')
      expect(upArrow).toBeTruthy()
    })

    it('should show down arrow when descending', () => {
      const {getByTestId} = setup({
        sortDirection: 'desc',
      })
      const downArrow = getByTestId('DownArrow')
      expect(downArrow).toBeTruthy()
    })

    it('should call onClick when clicked', () => {
      const onSortClickMock = jest.fn()
      const {getByTestId} = setup({
        onSortClick: onSortClickMock,
      })
      const button = getByTestId('sortButton')
      button.click()
      expect(onSortClickMock.mock.calls).toHaveLength(1)
    })
  })

  describe('Groups Menu Button', () => {
    it('should not render when the child topics is undefined', () => {
      const container = setup({
        childTopics: undefined,
        isAdmin: true,
      })
      expect(container.queryByTestId('groups-menu-button')).toBeFalsy()
    })

    it('should render when there are no child topics and the user is an admin', () => {
      const container = setup({
        childTopics: [],
        isAdmin: true,
      })

      expect(container.queryByTestId('groups-menu-button')).toBeTruthy()
    })

    it('should render when there are child topics and the user is an admin', () => {
      const container = setup({
        childTopics: [ChildTopic.mock()],
        isAdmin: true,
      })
      expect(container.queryByTestId('groups-menu-button')).toBeTruthy()
    })

    it('should not render when the user is not an admin', () => {
      const container = setup({
        childTopics: [ChildTopic.mock()],
        isAdmin: false,
      })
      expect(container.queryByTestId('groups-menu-button')).toBeNull()
    })
  })
})
