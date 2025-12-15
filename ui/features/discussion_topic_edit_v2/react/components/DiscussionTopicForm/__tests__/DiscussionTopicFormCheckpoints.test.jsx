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
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

// Tests for checkpoint due date validation (both allowed and blocked scenarios) are in:
// - DiscussionTopicFormCheckpointsSIS.test.jsx

describe('DiscussionTopicForm Checkpoints Disabled', () => {
  const mockOnSubmit = vi.fn()

  beforeEach(() => {
    setupDefaultEnv()
    mockOnSubmit.mockClear()
  })

  it('uses regular due date validation when checkpoints are disabled', () => {
    window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = false
    window.ENV.DUE_DATE_REQUIRED_FOR_ACCOUNT = true

    const topicData = DiscussionTopic.mock({
      assignment: Assignment.mock({
        pointsPossible: 10,
        postToSis: true,
      }),
    })

    const {queryByTestId, queryByRole, queryByLabelText} = setup({
      currentDiscussionTopic: topicData,
      onSubmit: mockOnSubmit,
    })

    const titleInput = queryByLabelText('Topic Title')
    titleInput.value = 'Test Checkpoint Discussion'
    titleInput.dispatchEvent(new Event('change', {bubbles: true}))

    expect(queryByTestId('checkpoints-checkbox')).not.toBeInTheDocument()

    const submitButton = queryByRole('button', {name: /save/i})
    submitButton.click()

    expect(mockOnSubmit).not.toHaveBeenCalled()
  })
})
