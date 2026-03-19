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

import {setup, setupDefaultEnv} from './DiscussionTopicFormTestHelpers'

vi.mock('@canvas/rce/react/CanvasRce')

describe('DiscussionTopicForm Rendering', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    setupDefaultEnv()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  it('renders', () => {
    const document = setup()
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()

    expect(document.queryByTestId('graded-checkbox')).toBeTruthy()
    expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
  })

  it('renders expected default teacher discussion options', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true

    const document = setup()
    // Default teacher options in order top to bottom
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()
    expect(document.queryByTestId('discussion-assign-to-section')).toBeTruthy()
    expect(document.queryAllByText('Anonymous Discussion')).toBeTruthy()
    expect(document.queryByLabelText('Disallow threaded replies')).toBeInTheDocument()
    expect(document.queryByTestId('require-initial-post-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByTestId('graded-checkbox')).toBeTruthy()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
    expect(document.queryByLabelText('Add to student to-do')).toBeInTheDocument()
    expect(document.queryByTestId('group-discussion-checkbox')).toBeTruthy()
    expect(document.queryAllByText('Available from')).toBeTruthy()
    expect(document.queryAllByText('Until')).toBeTruthy()
    expect(document.queryByTestId('discussion-topic-message-editor')).toBeTruthy()

    // Hides announcement options
    expect(document.queryByLabelText('Allow Participants to Comment')).not.toBeInTheDocument()
  })

  it('renders expected default teacher announcement options', () => {
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MODERATE = true
    window.ENV.DISCUSSION_TOPIC.PERMISSIONS.CAN_MANAGE_CONTENT = true
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES.is_announcement = true
    window.ENV.CONDITIONAL_RELEASE_SERVICE_ENABLED = true

    const document = setup()
    // Default teacher options in order top to bottom
    expect(document.getByText('Topic Title')).toBeInTheDocument()
    expect(document.queryByText('Attach')).toBeTruthy()
    expect(document.queryByTestId('section-select')).toBeTruthy()
    expect(document.queryByText('All Sections')).toBeTruthy()
    expect(document.queryByLabelText('Allow Participants to Comment')).toBeInTheDocument()
    expect(document.queryByLabelText('Enable podcast feed')).toBeInTheDocument()
    expect(document.queryByLabelText('Allow liking')).toBeInTheDocument()
    expect(document.queryByTestId('non-graded-date-options')).toBeTruthy()
    expect(document.queryAllByText('Available from')).toBeTruthy()
    expect(document.queryAllByText('Until')).toBeTruthy()

    // Hides discussion only options
    expect(document.queryByLabelText('Add to student to-do')).not.toBeInTheDocument()
    expect(document.queryByText('Anonymous Discussion')).not.toBeTruthy()
    expect(document.queryByTestId('graded-checkbox')).not.toBeTruthy()
    expect(document.queryByTestId('group-discussion-checkbox')).not.toBeTruthy()

    // hides mastery paths
    expect(document.queryByText('Mastery Paths')).toBeFalsy()

    // hides conditional alert
    expect(document.queryByTestId('schedule-info-alert')).toBeFalsy()
  })

  it('does not render rce when mastercourse is locked', () => {
    window.ENV.DISCUSSION_CONTENT_LOCKED = true
    const document = setup()
    expect(document.queryByTestId('discussion-topic-message-locked')).toBeTruthy()
  })

  it('initializes form with query parameters from ENV for new graded discussion', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
      title: 'Test Discussion from Assignment Index',
      assignment: {
        points_possible: '50',
        due_at: '2026-02-25T06:59:00.000Z',
        assignment_group_id: '26',
      },
    }

    const currentDiscussionTopic = {
      title: 'Test Discussion from Assignment Index',
      assignment: {
        pointsPossible: 50,
        dueAt: '2026-02-25T06:59:00.000Z',
        assignmentGroup: {_id: '26'},
        assignmentOverrides: {
          nodes: [
            {
              id: 'everyone',
              dueAt: '2026-02-25T06:59:00.000Z',
              unlockAt: null,
              lockAt: null,
              set: {
                __typename: 'Course',
                _id: '1',
              },
            },
          ],
        },
      },
    }

    const document = setup({currentDiscussionTopic})
    expect(document.getByDisplayValue('Test Discussion from Assignment Index')).toBeInTheDocument()
    expect(document.getByDisplayValue('50')).toBeInTheDocument()
  })

  it('converts points_possible string to float', () => {
    window.ENV.DISCUSSION_TOPIC.ATTRIBUTES = {
      title: 'Test',
      assignment: {
        points_possible: '43',
        due_at: '2026-02-25T06:59:00.000Z',
        assignment_group_id: '26',
      },
    }

    const currentDiscussionTopic = {
      title: 'Test',
      assignment: {
        pointsPossible: 43,
        dueAt: '2026-02-25T06:59:00.000Z',
        assignmentGroup: {_id: '26'},
        assignmentOverrides: {
          nodes: [
            {
              id: 'everyone',
              dueAt: '2026-02-25T06:59:00.000Z',
              unlockAt: null,
              lockAt: null,
              set: {
                __typename: 'Course',
                _id: '1',
              },
            },
          ],
        },
      },
    }

    const document = setup({currentDiscussionTopic})
    expect(document.getByDisplayValue('43')).toBeInTheDocument()
  })
})
