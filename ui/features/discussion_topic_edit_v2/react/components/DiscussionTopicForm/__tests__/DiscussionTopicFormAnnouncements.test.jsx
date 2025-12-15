/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Announcements', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  describe('when user is restricted', () => {
    it('sets all the sections as default sections', () => {
      vi.useFakeTimers()
      window.ENV.USER_HAS_RESTRICTED_VISIBILITY = true
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true

      const document = setup()
      expect(document.queryByText('Section 1')).toBeTruthy()
      expect(document.queryByText('Section 2')).toBeTruthy()
      vi.useRealTimers()
    })

    it('when there are section visibilities already it sets the visibilities as default', () => {
      vi.useFakeTimers()
      window.ENV.USER_HAS_RESTRICTED_VISIBILITY = true
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
      window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
      window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
      window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true

      const {getByText} = setup({
        currentDiscussionTopic: DiscussionTopic.mock({
          groupSet: false,
          courseSections: [{_id: '1', name: 'Section 1'}],
        }),
      })
      expect(getByText('Section 1')).toBeTruthy()
      vi.useRealTimers()
    })
  })

  it('renders comment related fields when participants commenting is enabled in an announcement', () => {
    vi.useFakeTimers()
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.has_threaded_replies = false
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.ANNOUNCEMENTS_COMMENTS_DISABLED = false

    const {queryByTestId, queryByLabelText} = setup()

    const allowCommentsCheckbox = queryByLabelText('Allow Participants to Comment')
    allowCommentsCheckbox.click()
    expect(allowCommentsCheckbox).toBeChecked()
    expect(queryByLabelText('Disallow threaded replies')).toBeInTheDocument()
    expect(queryByTestId('require-initial-post-checkbox')).toBeInTheDocument()
    vi.useRealTimers()
  })

  it('renders reset buttons for availability dates when creating/editing an announcement', () => {
    vi.useFakeTimers()
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true

    const document = setup()

    expect(document.queryAllByTestId('reset-available-from-button')).toHaveLength(1)
    expect(document.queryAllByTestId('reset-available-until-button')).toHaveLength(1)
    vi.useRealTimers()
  })
})
