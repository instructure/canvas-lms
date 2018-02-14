/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import actions from 'jsx/discussions/actions'
import reducer from 'jsx/discussions/rootReducer'
import sampleData from './sampleData'

QUnit.module('Discussions reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('TOGGLE_PIN_START should update pinned discussions', () => {
  const discussion = { id: 1, pinned: false, locked: false }
  const newState = reduce(actions.togglePinStart({pinnedState: true, discussion, closedState: false}), {
    unpinnedDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.pinnedDiscussions, [{ id: 1, pinned: false, locked: false }])
})

test('TOGGLE_PIN_FAIL should update pinned discussion', () => {
  const discussion = { id: 1, pinned: false, locked: false }
  const newState = reduce(actions.togglePinFail({pinnedState: true, discussion, closedState: false}), {
    pinnedDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [{ id: 1, pinned: false, locked: false }])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_PIN_START should update unpinned discussions', () => {
  const discussion = { id: 1, pinned: true, locked: false }
  const newState = reduce(actions.togglePinStart({pinnedState: false, discussion, closedState: false}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.unpinnedDiscussions, [{ id: 1, pinned: true, locked: false }])
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_PIN_FAIL should update unpinned discussion', () => {
  const discussion = { id: 1, pinned: true, locked: false }
  const newState = reduce(actions.togglePinFail({pinnedState: false, discussion, closedState: false}), {
    unpinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [{ id: 1, pinned: true, locked: false }])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_PIN_FAIL should update closedForComments discussion', () => {
  const discussion = { id: 1, pinned: false, locked: true}
  const newState = reduce(actions.togglePinFail({pinnedState: false, discussion, closedState: false}), {
    unpinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, pinned: false, locked: true}])
})

test('CLOSE_FOR_COMMENTS_START should update pinned discussions', () => {
  const discussion = { id: 1, pinned: true, locked: false }
  const newState = reduce(actions.closeForCommentsStart({pinnedState: false, discussion, closedState: true}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, pinned: true, locked: false}])
})

test('CLOSE_FOR_COMMENTS_FAIL should update pinned discussion', () => {
  const discussion = { id: 1, pinned: true, locked: false }
  const newState = reduce(actions.closeForCommentsFail({pinnedState: true, discussion, closedState: true}), {
    closedForCommentsDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [{ id: 1, pinned: true, locked: false }])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('CLOSE_FOR_COMMENTS_START should update unpinned discussions', () => {
  const discussion = { id: 1, pinned: false, locked: false }
  const newState = reduce(actions.closeForCommentsStart({pinnedState: false, discussion, closedState: true}), {
    unpinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, pinned: false, locked: false}])
})

test('CLOSE_FOR_COMMENTS_FAIL should update unpinned discussion', () => {
  const discussion = { id: 1, pinned: false, locked: false }
  const newState = reduce(actions.closeForCommentsFail({pinnedState: false, discussion, closedState: true}), {
    closedForCommentsDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [{ id: 1, pinned: false, locked: false }])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_START should not change the state', () => {
  const newState = reduce(actions.toggleSubscribeStart({}), {})
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_FAIL should not change the state', () => {
  const newState = reduce(actions.toggleSubscribeStart({}), {})
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed to false when new state is false', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {
    pinnedDiscussions: [{ id: 1, subscribed: true }]
  })
  deepEqual(newState.pinnedDiscussions[0], {id: 1, subscribed: false})
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed to true when new state is true', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: true }), {
    pinnedDiscussions: [{ id: 1, subscribed: false }]
  })
  deepEqual(newState.pinnedDiscussions[0], {id: 1, subscribed: true})
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed status in pinnedDiscussions', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {
    pinnedDiscussions: [{ id: 1, subscribed: true }]
  })
  deepEqual(newState.pinnedDiscussions[0], {id: 1, subscribed: false})
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed status in unpinnedDiscussions', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {
    unpinnedDiscussions: [{ id: 1, subscribed: true }]
  })
  deepEqual(newState.unpinnedDiscussions[0], {id: 1, subscribed: false})
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed status in closedForCommentsDiscussions', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {
    closedForCommentsDiscussions: [{ id: 1, subscribed: true }]
  })
  deepEqual(newState.closedForCommentsDiscussions[0], {id: 1, subscribed: false})
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should not change the state if the id does not exist in the store', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {})
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should only update the state of the supplied id', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({ id: 1, subscribed: false }), {
    closedForCommentsDiscussions: [
      { id: 1, subscribed: true },
      { id: 2, subscribed: true }
    ]
  })
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, subscribed: false },
                                                    { id: 2, subscribed: true }])
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
})
