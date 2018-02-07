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
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
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
