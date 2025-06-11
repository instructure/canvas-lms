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
import {assignLocation, openWindow} from '@canvas/util/globalUtils'
import {waitFor} from '@testing-library/dom'
import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {ChildTopic} from '../../../../graphql/ChildTopic'
import {updateUserDiscussionsSplitscreenViewMock} from '../../../../graphql/Mocks'
import * as constants from '../../../utils/constants'
import {DiscussionManagerUtilityContext} from '../../../utils/constants'
import {DiscussionPostToolbar} from '../DiscussionPostToolbar'

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
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })

  window.ENV = {
    course_id: '1',
    SPEEDGRADER_URL_TEMPLATE: '/courses/1/gradebook/speed_grader?assignment_id=1&:student_id',
    DISCUSSION: {
      preferences: {
        discussions_splitscreen_view: false,
      },
    },
  }
})

afterEach(() => {
  onFailureStub.mockClear()
  onSuccessStub.mockClear()
  jest.clearAllMocks()
})

const setup = (
  props,
  mocks,
  discussionManagerProviderValues = {translationLanguages: {current: []}},
) => {
  return render(
    <MockedProvider mocks={mocks}>
      <AlertManagerContext.Provider
        value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
      >
        <DiscussionManagerUtilityContext.Provider value={discussionManagerProviderValues}>
          <DiscussionPostToolbar {...props} />
        </DiscussionManagerUtilityContext.Provider>
      </AlertManagerContext.Provider>
    </MockedProvider>,
  )
}

describe('DiscussionPostToolbar', () => {
  describe('Anonymous Indicator Avatar', () => {
    describe('discussion is anonymous', () => {
      it('should render discussionAnonymousState is not null', () => {
        ENV.current_user_roles = ['student']
        const container = setup({
          discussionAnonymousState: 'full_anonymity',
        })
        expect(container.queryByTestId('anonymous_avatar')).toBeTruthy()
      })
    })

    describe('discussion is not anonymous', () => {
      it('should render discussionAnonymousState is null', () => {
        ENV.current_user_roles = ['student']
        const container = setup({
          discussionAnonymousState: null,
        })
        expect(container.queryByTestId('anonymous_avatar')).toBeNull()
      })
    })
  })

  describe('Assign To', () => {
    it('renders the Assign To button if user can manageAssignTo and in a course discussion', () => {
      const {getByRole} = setup({
        manageAssignTo: true,
        showAssignTo: true,
      })
      expect(getByRole('button', {name: 'Assign To'})).toBeInTheDocument()
    })

    it('does not render the Assign To button if in speedGrader', () => {
      jest.mock('../../../utils/constants', () => ({
        ...jest.requireActual('../../../utils/constants'),
        isSpeedGraderInTopUrl: true,
      }))

      const container = setup({
        manageAssignTo: true,
        discussionTopic: {
          _id: '1',
          contextType: 'Course',
          groupSet: null,
          assignment: true,
        },
      })
      expect(container.queryByTestId('assign-to-button')).toBeNull()
    })

    it('does not render the Assign To button if user can not manageAssignTo', () => {
      const {queryByRole} = setup({
        manageAssignTo: false,
        contextType: 'Course',
      })
      expect(queryByRole('button', {name: 'Assign To'})).not.toBeInTheDocument()
    })

    it('does not render the Assign To button if a group discussion', () => {
      const {queryByText} = setup({
        manageAssignTo: true,
        contextType: 'Group',
      })
      expect(queryByText('Assign To')).not.toBeInTheDocument()
    })

    it('does not render the Assign To button if an ungraded group discussion in course context', () => {
      const {queryByTestId} = setup({
        manageAssignTo: true,
        contextType: 'Course',
        isGraded: false,
        isGroupDiscussion: true,
      })
      expect(queryByTestId('manage-assign-to')).not.toBeInTheDocument()
    })
  })

  describe('Splitscreen Button', () => {
    it('should call updateUserDiscussionsSplitscreenView mutation when clicked', async () => {
      // Reset mocks to ensure clean state
      jest.clearAllMocks()

      // Mock functions
      const setUserSplitScreenPreference = jest.fn()
      const closeView = jest.fn()

      const {getByTestId} = setup(
        {
          setUserSplitScreenPreference,
          userSplitScreenPreference: false,
          closeView,
        },
        updateUserDiscussionsSplitscreenViewMock({discussionsSplitscreenView: true}),
      )

      // Get and click the button
      const splitscreenButton = getByTestId('splitscreenButton')
      fireEvent.click(splitscreenButton)

      // Wait for the success callback to be called with a longer timeout
      await waitFor(
        () => {
          expect(onSuccessStub).toHaveBeenCalled()
        },
        {timeout: 2000},
      )

      // Verify the preference was updated
      expect(setUserSplitScreenPreference).toHaveBeenCalled()
    })
  })

  describe('Translate Button', () => {
    describe('when translationLanguages is empty', () => {
      it('does not render the translate button', () => {
        const {queryByTestId} = setup()
        expect(queryByTestId('translate-button')).toBeNull()
      })
    })

    describe('when the discussion topic is an announcement', () => {
      it('does render the translate button', () => {
        const {queryByTestId} = setup({isAnnouncement: true}, null, {
          translationLanguages: {current: ['en', 'es']},
        })
        expect(queryByTestId('translate-button')).toBeTruthy()
      })

      it('does render the new button label if the flag is on', () => {
        ENV.ai_translation_improvements = true
        const {getByText} = setup({isAnnouncement: true}, null, {
          translationLanguages: {current: ['en', 'es']},
        })
        expect(getByText('Open Translate')).toBeTruthy()
      })
    })

    describe('when the improvement flag is turned on', () => {
      beforeEach(() => {
        ENV.ai_translation_improvements = true
      })

      afterEach(() => {
        ENV.ai_translation_improvements = false
      })

      it('does render the translate button with improved text', () => {
        const {getByText} = setup(null, null, {
          translationLanguages: {current: ['en', 'es']},
        })

        expect(getByText('Open Translate')).toBeTruthy()
      })

      it('does render the translate button with improved text when the translation controls are on', () => {
        const {getByText, getByTestId} = setup(null, null, {
          translationLanguages: {current: ['en', 'es']},
          showTranslationControl: true,
        })

        expect(getByText('Close Translate')).toBeTruthy()
        expect(getByTestId('translate-button')).toHaveAttribute(
          'data-action-state',
          'disableTranslation',
        )
      })
    })

    it('does render the translate button', () => {
      const {getByTestId} = setup(null, null, {
        translationLanguages: {current: ['en', 'es']},
      })

      expect(getByTestId('translate-button')).toBeTruthy()
      expect(getByTestId('translate-button')).toHaveAttribute(
        'data-action-state',
        'enableTranslation',
      )
    })

    it('does call setShowTranslationControl when clicked', () => {
      const setShowTranslationControl = jest.fn()
      const {getByTestId} = setup(null, null, {
        translationLanguages: {current: ['en', 'es']},
        setShowTranslationControl,
      })
      const translateButton = getByTestId('translate-button')
      fireEvent.click(translateButton)
      expect(setShowTranslationControl).toHaveBeenCalled()
    })
  })
})
