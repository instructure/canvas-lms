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
import {updateDiscussionEntryMock} from '../../graphql/Mocks'
import {fireEvent, render, waitFor} from '@testing-library/react'
import {MockedProvider} from '@apollo/client/testing'
import React from 'react'
import {responsiveQuerySizes} from '../utils'
import {Discussion} from '../../graphql/Discussion'
import {DiscussionEntry} from '../../graphql/DiscussionEntry'
import {DiscussionThreadContainer} from '../containers/DiscussionThreadContainer/DiscussionThreadContainer'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'
import fakeENV from '@canvas/test-utils/fakeENV'

jest.mock('@canvas/util/globalUtils', () => ({
  openWindow: jest.fn(),
  windowPathname: jest.fn(() => '/courses/1'),
}))

injectGlobalAlertContainers()

jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  responsiveQuerySizes: jest.fn(),
}))

describe('DiscussionsAttachment', () => {
  const onFailureStub = jest.fn()
  const onSuccessStub = jest.fn()
  beforeAll(() => {
    fakeENV.setup({
      course_id: '1',
      SPEEDGRADER_URL_TEMPLATE: '/courses/1/gradebook/speed_grader?assignment_id=1&:student_id',
      RICH_CONTENT_CAN_UPLOAD_FILES: true,
      context_asset_string: 'course_1',
      current_user_id: '1',
    })

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

  afterAll(() => {
    fakeENV.teardown()
  })

  const defaultProps = ({
    discussionEntryOverrides = {},
    discussionOverrides = {},
    propOverrides = {},
  } = {}) => ({
    discussionTopic: Discussion.mock(discussionOverrides),
    discussionEntry: DiscussionEntry.mock(discussionEntryOverrides),
    ...propOverrides,
  })

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider
          value={{setOnFailure: onFailureStub, setOnSuccess: onSuccessStub}}
        >
          <DiscussionThreadContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>,
    )
  }

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '750px'},
      }))
    })
    it('updates the attachment', async () => {
      const container = setup(
        defaultProps({
          discussionEntryOverrides: {
            quotedEntry: {
              _id: '1337',
              message: 'Best Paladin in the world',
            },
          },
        }),
        updateDiscussionEntryMock({
          discussionEntryId: 'DiscussionEntry-default-mock',
          message: '<p>This is the parent reply</p>',
          fileId: null,
          removeAttachment: true,
          quotedEntryId: '1337',
          // Since we set up the mock with the quotedEntryId, the test will only pass if the mutation variables
          // match the id, else we'd get an error
        }),
      )

      expect(await container.findByText('This is the parent reply')).toBeInTheDocument()

      const actionsButton = await container.findByTestId('thread-actions-menu')
      fireEvent.click(actionsButton)
      fireEvent.click(container.getByTestId('edit'))

      await waitFor(() => {
        expect(tinymce.get('1337')).toBeDefined()
      })

      document.querySelectorAll('textarea')[0].value = ''

      await waitFor(() => expect(container.queryByTestId('remove-button')).toBeTruthy())
      const removeAttachButton = container.getAllByTestId('remove-button')[0]
      fireEvent.click(removeAttachButton)

      const submitButton = container.getAllByTestId('DiscussionEdit-submit')[0]
      fireEvent.click(submitButton)

      await waitFor(() =>
        expect(container.queryByText('This is the parent reply')).not.toBeInTheDocument(),
      )

      await waitFor(() => {
        expect(onSuccessStub).toHaveBeenCalledWith('The reply was successfully updated.')
      })
    })
  })
})
