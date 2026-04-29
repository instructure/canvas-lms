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

import {fireEvent} from '@testing-library/react'
import {Assignment} from '../../../../graphql/Assignment'
import {DiscussionTopic} from '../../../../graphql/DiscussionTopic'
import {REPLY_TO_ENTRY, REPLY_TO_TOPIC} from '../../../util/constants'
import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

// This test is isolated in its own file due to heavy initialization overhead
// that causes timeouts in CI when combined with other tests.
describe('DiscussionTopicForm Checkpoints Increment Range', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  const setupWithCheckpoints = (replyToEntryRequiredCount = 1) => {
    return setup({
      currentDiscussionTopic: DiscussionTopic.mock({
        replyToEntryRequiredCount,
        assignment: Assignment.mock({
          hasSubAssignments: true,
          checkpoints: [
            {
              dueAt: null,
              name: 'checkpoint discussion',
              onlyVisibleToOverrides: false,
              pointsPossible: 5,
              tag: REPLY_TO_TOPIC,
            },
            {
              dueAt: null,
              name: 'checkpoint discussion',
              onlyVisibleToOverrides: false,
              pointsPossible: 5,
              tag: REPLY_TO_ENTRY,
            },
          ],
        }),
      }),
    })
  }

  it('does not allow incrementing or decrementing if required count is not in the allowed range', () => {
    const {getByTestId} = setupWithCheckpoints()

    const numberInputReplyToEntryRequiredCount = getByTestId('reply-to-entry-required-count')
    expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

    fireEvent.click(numberInputReplyToEntryRequiredCount)

    fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 40})
    expect(numberInputReplyToEntryRequiredCount.value).toBe('1')

    fireEvent.change(numberInputReplyToEntryRequiredCount, {target: {value: '10'}})

    fireEvent.keyDown(numberInputReplyToEntryRequiredCount, {keyCode: 38})
    expect(numberInputReplyToEntryRequiredCount.value).toBe('10')
  })
})
