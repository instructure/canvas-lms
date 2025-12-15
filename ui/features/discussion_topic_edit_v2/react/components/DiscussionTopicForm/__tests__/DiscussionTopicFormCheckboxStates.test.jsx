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

describe('DiscussionTopicForm Checkbox States', () => {
  beforeEach(() => {
    vi.useFakeTimers()
    setupDefaultEnv()
  })

  afterEach(() => {
    vi.useRealTimers()
  })

  describe('renders trackable states to checkboxes', () => {
    it('renders require initiator checkbox truth as default', () => {
      const {queryByTestId} = setup()

      let checkbox = queryByTestId('require-initial-post-checkbox')
      expect(checkbox).toHaveAttribute('data-action-state', 'enableInitiatorRequirement')

      checkbox = queryByTestId('enable-podcast-checkbox')
      expect(checkbox).toHaveAttribute('data-action-state', 'enablePodcast')

      checkbox = queryByTestId('graded-checkbox')
      expect(checkbox).toHaveAttribute('data-action-state', 'enableGrades')

      checkbox = queryByTestId('like-checkbox')
      expect(checkbox).toHaveAttribute('data-action-state', 'allowLiking')
    })

    describe('group discussion checkbox', () => {
      it('renders require initiator checkbox truth as default', () => {
        ENV = {
          FEATURES: {},
          SETTINGS: {},
          STUDENT_PLANNER_ENABLED: true,
          DISCUSSION_TOPIC: {
            ATTRIBUTES: {
              is_announcement: false,
            },
            PERMISSIONS: {
              CAN_SET_GROUP: true,
            },
          },
        }
        Object.assign(window.ENV, ENV)

        const {queryByTestId} = setup()
        const checkbox = queryByTestId('group-discussion-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'addGroupDiscussion')
      })

      describe('when checkbox is checked', () => {
        it('renders require initiator checkbox truth as default', () => {
          ENV = {
            FEATURES: {},
            SETTINGS: {},
            STUDENT_PLANNER_ENABLED: true,
            DISCUSSION_TOPIC: {
              ATTRIBUTES: {
                is_announcement: false,
              },
              PERMISSIONS: {
                CAN_SET_GROUP: true,
              },
            },
          }
          Object.assign(window.ENV, ENV)

          const {queryByTestId} = setup({currentDiscussionTopic: {groupSet: 'whateva'}})
          const checkbox = queryByTestId('group-discussion-checkbox')
          expect(checkbox).toHaveAttribute('data-action-state', 'removeGroupDiscussion')
        })
      })
    })

    describe('todo', () => {
      it('renders require initiator checkbox truth as default', () => {
        ENV = {
          FEATURES: {},
          SETTINGS: {},
          STUDENT_PLANNER_ENABLED: true,
          DISCUSSION_TOPIC: {
            ATTRIBUTES: {
              is_announcement: false,
            },
            PERMISSIONS: {
              CAN_MANAGE_CONTENT: true,
              CAN_CREATE_ASSIGNMENT: true,
            },
          },
        }
        Object.assign(window.ENV, ENV)

        const {queryByTestId} = setup()
        const checkbox = queryByTestId('add-todo-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'addToTodo')
      })

      describe('when checkbox is checked', () => {
        it('renders require initiator checkbox truth as default', () => {
          ENV = {
            FEATURES: {},
            STUDENT_PLANNER_ENABLED: true,
            DISCUSSION_TOPIC: {
              ATTRIBUTES: {
                is_announcement: false,
              },
              PERMISSIONS: {
                CAN_MANAGE_CONTENT: true,
                CAN_CREATE_ASSIGNMENT: true,
              },
            },
          }
          Object.assign(window.ENV, ENV)

          const {queryByTestId} = setup({
            currentDiscussionTopic: {todoDate: '2025-05-14T06:48:23.902Z'},
          })
          const checkbox = queryByTestId('add-todo-checkbox')
          expect(checkbox).toHaveAttribute('data-action-state', 'dontAddToTodo')
        })
      })
    })

    describe('when requireInitialPost is truthy', () => {
      it('sets trackable state to disable', () => {
        const {queryByTestId} = setup({currentDiscussionTopic: {requireInitialPost: true}})
        const checkbox = queryByTestId('require-initial-post-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'disableInitiatorRequirement')
      })
    })

    describe('when allowRating is truthy', () => {
      it('sets trackable state to disable', () => {
        const {queryByTestId} = setup({currentDiscussionTopic: {allowRating: true}})
        var checkbox = queryByTestId('like-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'disallowLiking')

        checkbox = queryByTestId('exclude-non-graders-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'excludeNonGradersLiking')
      })

      describe('when non graders are excluded', () => {
        it('sets trackable state to allow', () => {
          const {queryByTestId} = setup({
            currentDiscussionTopic: {allowRating: true, onlyGradersCanRate: true},
          })
          const checkbox = queryByTestId('exclude-non-graders-checkbox')
          expect(checkbox).toHaveAttribute('data-action-state', 'allowNonGradersLiking')
        })
      })
    })

    describe('when grading is enabled', () => {
      it('sets trackable state to disable and shows checkpoints checkbox', () => {
        const {queryByTestId} = setup({currentDiscussionTopic: {assignment: true}})
        const checkbox = queryByTestId('graded-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'disableGrades')

        expect(queryByTestId('checkpoints-checkbox')).toHaveAttribute(
          'data-action-state',
          'enableCheckpoints',
        )
      })

      describe('when checkpoints are enabled', () => {
        it('should set the trackable attributes accordingly', () => {
          window.ENV.DISCUSSION_CHECKPOINTS_ENABLED = true
          const {queryByTestId} = setup({currentDiscussionTopic: {assignment: true}})
          const checkbox = queryByTestId('checkpoints-checkbox')
          expect(checkbox).toHaveAttribute('data-action-state', 'enableCheckpoints')
        })
      })
    })

    describe('when enablePodcastFeed is truthy', () => {
      it('sets trackable state to disable', () => {
        const {queryByTestId} = setup({currentDiscussionTopic: {podcastEnabled: true}})
        const checkbox = queryByTestId('enable-podcast-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'disablePodcast')
      })

      it('sets trackable state to reply inclusion as well', () => {
        const {queryByTestId} = setup({currentDiscussionTopic: {podcastEnabled: true}})
        const checkbox = queryByTestId('include-replies-in-podcast-checkbox')
        expect(checkbox).toHaveAttribute('data-action-state', 'includeRepliesInFeed')
      })

      describe('when podcastHasStudentPosts is also truthy', () => {
        it('sets trackable state to reply inclusion to disableRepliesInFeed', () => {
          const {queryByTestId} = setup({
            currentDiscussionTopic: {podcastEnabled: true, podcastHasStudentPosts: true},
          })
          const checkbox = queryByTestId('include-replies-in-podcast-checkbox')
          expect(checkbox).toHaveAttribute('data-action-state', 'disableRepliesInFeed')
        })
      })
    })
  })
})
