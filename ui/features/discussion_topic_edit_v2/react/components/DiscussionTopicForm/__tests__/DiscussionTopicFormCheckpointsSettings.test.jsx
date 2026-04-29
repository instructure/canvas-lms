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

// Note: Tests involving setupCheckpoints() clicks were moved to separate files
// because they cause heavy re-renders that timeout in CI when combined:
// - DiscussionTopicFormCheckpointsToggle.test.jsx (toggle checkbox test)
// - DiscussionTopicFormCheckpointsAdditionalReplies.test.jsx (additional replies required tests)

describe('DiscussionTopicForm Checkpoints Settings', () => {
  beforeEach(() => {
    setupDefaultEnv()
  })

  it('sets the correct checkpoint settings values when there are existing checkpoints', () => {
    const {getByTestId} = setup({
      currentDiscussionTopic: DiscussionTopic.mock({
        replyToEntryRequiredCount: 5,
        assignment: Assignment.mock({
          hasSubAssignments: true,
          checkpoints: [
            {
              dueAt: null,
              name: 'checkpoint discussion',
              onlyVisibleToOverrides: false,
              pointsPossible: 6,
              tag: REPLY_TO_TOPIC,
            },
            {
              dueAt: null,
              name: 'checkpoint discussion',
              onlyVisibleToOverrides: false,
              pointsPossible: 7,
              tag: REPLY_TO_ENTRY,
            },
          ],
        }),
      }),
    })

    const numberInputReplyToTopic = getByTestId('points-possible-input-reply-to-topic')
    expect(numberInputReplyToTopic.value).toBe('6')
    const numberInputReplyToEntry = getByTestId('points-possible-input-reply-to-entry')
    expect(numberInputReplyToEntry.value).toBe('7')
    const numberInputAdditionalRepliesRequired = getByTestId('reply-to-entry-required-count')
    expect(numberInputAdditionalRepliesRequired.value).toBe('5')
  })
})
