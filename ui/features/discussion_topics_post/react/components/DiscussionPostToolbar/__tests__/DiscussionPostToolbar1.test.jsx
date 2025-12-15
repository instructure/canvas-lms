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

vi.mock('@canvas/util/globalUtils', () => ({
  assignLocation: vi.fn(),
  openWindow: vi.fn(),
}))

vi.mock('../../../utils', async () => ({
  ...await vi.importActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

vi.mock('../../../utils/constants', async () => ({
  ...await vi.importActual('../../../utils/constants'),
  isSpeedGraderInTopUrl: false,
}))

const onFailureStub = vi.fn()
const onSuccessStub = vi.fn()

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
  vi.clearAllMocks()
})

const setup = (
  props,
  mocks,
  discussionManagerProviderValues = {translationLanguages: {current: []}},
) => {
  const searchContextValues = {
    setAllThreadsStatus: vi.fn(),
    setExpandedThreads: vi.fn(),
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
              setUserSplitScreenPreference: vi.fn(),
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
              setUserSplitScreenPreference: vi.fn(),
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
            setUserSplitScreenPreference: vi.fn(),
            userSplitScreenPreference: true,
            closeView: vi.fn(),
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
            setUserSplitScreenPreference: vi.fn(),
            userSplitScreenPreference: false,
            closeView: vi.fn(),
          },
          updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
        )

        const splitscreenButton = getByTestId('splitscreenButton')
        expect(splitscreenButton).toHaveAttribute('data-action-state', 'splitscreenButtonToSplit')
      })

      it('should call updateUserDiscussionsSplitscreenView mutation when clicked', async () => {
        const setUserSplitScreenPreferenceMock = vi.fn()
        const closeViewMock = vi.fn()

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
      const onSearchChangeMock = vi.fn()
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
      const onViewFilterMock = vi.fn()
      const {getByText, getByLabelText} = setup({onViewFilter: onViewFilterMock})
      const simpleSelect = getByLabelText('Filter by')
      fireEvent.click(simpleSelect)
      const unread = getByText('Unread')
      fireEvent.click(unread)
      expect(onViewFilterMock.mock.calls).toHaveLength(1)
      expect(onViewFilterMock.mock.calls[0][1].id).toBe('unread')
    })
  })

  describe('Groups Menu Button', () => {
    it('should not render when the child topics is undefined', () => {
      const container = setup({
        childTopics: undefined,
        canViewGroupPages: true,
      })
      expect(container.queryByTestId('groups-menu-button')).toBeFalsy()
    })

    describe('when the user has student role', () => {
      it('should not render even if user has permission', () => {
        const container = setup({
          childTopics: [ChildTopic.mock()],
          canViewGroupPages: false,
        })
        expect(container.queryByTestId('groups-menu-button')).toBeNull()
      })
    })

    describe('when the user does not have student role', () => {
      let originalIsStudent

      beforeEach(() => {
        originalIsStudent = ENV.current_user_is_student
        ENV.current_user_is_student = false
      })

      afterEach(() => {
        ENV.current_user_is_student = originalIsStudent
      })

      it('should render when there are no child topics and the user has permission', () => {
        const container = setup({
          childTopics: [],
          canViewGroupPages: true,
        })

        expect(container.queryByTestId('groups-menu-button')).toBeTruthy()
      })

      it('should render when there are child topics and user the user has permission', () => {
        const container = setup({
          childTopics: [ChildTopic.mock()],
          canViewGroupPages: true,
        })
        expect(container.queryByTestId('groups-menu-button')).toBeTruthy()
      })

      it('should not render when the user does not have permission', () => {
        const container = setup({
          childTopics: [ChildTopic.mock()],
          canViewGroupPages: false,
        })
        expect(container.queryByTestId('groups-menu-button')).toBeNull()
      })
    })
  })
})
