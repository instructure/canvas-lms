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

import {Assignment} from '../../../../graphql/Assignment'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../../../util/constants'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

// Mock the flash alert to avoid heavy UI rendering during validation
vi.mock('@canvas/due-dates/util/differentiatedModulesUtil', async importOriginal => {
  const actual = await importOriginal()
  return {
    ...actual,
    showPostToSisFlashAlert: () => () => {},
  }
})

describe('DiscussionTopicForm Checkpoints SIS - Post to SIS Disabled', () => {
  const mockOnSubmit = vi.fn()

  const setupWithPreConfiguredCheckpoints = ({
    dueDateRequired = true,
    postToSis = true,
    checkpointDueAt = null,
  } = {}) => {
    window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
    window.ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = dueDateRequired

    const topicData = DiscussionTopic.mock({
      assignment: Assignment.mock({
        pointsPossible: 10,
        postToSis,
        hasSubAssignments: true,
        checkpoints: [
          {
            dueAt: checkpointDueAt,
            name: 'checkpoint discussion',
            onlyVisibleToOverrides: false,
            pointsPossible: 5,
            tag: REPLY_TO_TOPIC,
          },
          {
            dueAt: checkpointDueAt,
            name: 'checkpoint discussion',
            onlyVisibleToOverrides: false,
            pointsPossible: 5,
            tag: REPLY_TO_ENTRY,
          },
        ],
      }),
    })

    return setup({
      currentDiscussionTopic: topicData,
      onSubmit: mockOnSubmit,
    })
  }

  beforeEach(() => {
    setupDefaultEnv()
    mockOnSubmit.mockClear()
  })

  it('allows submission when post to SIS is disabled', () => {
    const {queryByRole, queryByLabelText} = setupWithPreConfiguredCheckpoints({
      dueDateRequired: true,
      postToSis: false,
      checkpointDueAt: null,
    })

    const titleInput = queryByLabelText('Topic Title')
    titleInput.value = 'Test Checkpoint Discussion'
    titleInput.dispatchEvent(new Event('change', {bubbles: true}))

    const submitButton = queryByRole('button', {name: /save/i})
    submitButton.click()

    expect(mockOnSubmit).toHaveBeenCalled()
  })
})
