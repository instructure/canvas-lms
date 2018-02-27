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

QUnit.module('Discussions reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('UPDATE_DISCUSSION_START should update pinned discussion', () => {
  const newState = reduce(actions.updateDiscussionStart({discussion: {id: 1, pinned: true, locked: false}}), {
    pinnedDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [{ id: 1, pinned: true, locked: false }])
})

test('UPDATE_DISCUSSION_FAIL should update pinned discussion', () => {
  const newState = reduce(actions.updateDiscussionFail({discussion: {id: 1, pinned: true, locked: false}}), {
    pinnedDiscussions: [{ id: 1, pinned: false, locked: false }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [{ id: 1, pinned: true, locked: false }])
})

test('UPDATE_DISCUSSION_START should update unpinned discussion', () => {
  const newState = reduce(actions.updateDiscussionStart({discussion: {id: 1, pinned: false, locked: false}}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [{ id: 1, pinned: false, locked: false }])
  deepEqual(newState.pinnedDiscussions, [])
})

test('UPDATE_DISCUSSION_FAIL should update unpinned discussion', () => {
  const newState = reduce(actions.updateDiscussionFail({discussion: {id: 1, pinned: false, locked: false}}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: false }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [{ id: 1, pinned: false, locked: false }])
  deepEqual(newState.pinnedDiscussions, [])
})

test('UPDATE_DISCUSSION_START should update closedForComments discussion', () => {
  const newState = reduce(actions.updateDiscussionStart({discussion: {id: 1, pinned: false, locked: true}}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: true }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, pinned: false, locked: true }])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [])
})

test('UPDATE_DISCUSSION_FAIL should update closedForComments discussion', () => {
  const newState = reduce(actions.updateDiscussionFail({discussion: {id: 1, pinned: false, locked: true}}), {
    pinnedDiscussions: [{ id: 1, pinned: true, locked: true }]
  })
  deepEqual(newState.closedForCommentsDiscussions, [{ id: 1, pinned: false, locked: true }])
  deepEqual(newState.unpinnedDiscussions, [])
  deepEqual(newState.pinnedDiscussions, [])
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

test('TOGGLE_MODAL_OPEN should toggle isSettingsModalOpen', () => {
  const newState = reduce(actions.toggleModalOpen())
  deepEqual(newState.isSettingsModalOpen, true)
})

test('SAVING_SETTINGS_SUCCESS should set isSettingsModalOpen to false', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: {}, userSettings: {}}))
  deepEqual(newState.isSettingsModalOpen, false)
})

test('SAVING_SETTINGS_FAIL should set isSettingsModalOpen to true', () => {
  const newState = reduce(actions.savingSettingsFail())
  deepEqual(newState.isSettingsModalOpen, true)
})

test('SAVING_SETTINGS_START should toggle isSavingSettings', () => {
  const newState = reduce(actions.savingSettingsStart())
  deepEqual(newState.isSavingSettings, true)
})

test('SAVING_SETTINGS_SUCCESS should set isSavingSettings to false', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: {}, userSettings: {}}))
  deepEqual(newState.isSavingSettings, false)
})

test('SAVING_SETTINGS_FAIL should toggle isSavingSettings', () => {
  const newState = reduce(actions.savingSettingsFail())
  deepEqual(newState.isSavingSettings, false)
})

test('GET_COURSE_SETTINGS_SUCCESS should return paylod', () => {
  const newState = reduce(actions.getCourseSettingsSuccess({courseSettings: "blah"}))
  deepEqual(newState.courseSettings, {courseSettings: "blah"})
})

test('SAVING_SETTINGS_SUCCESS should return paylod if returned', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: "blah", userSettings: 'blee'}))
  deepEqual(newState.courseSettings, "blah")
})

test('SAVING_SETTINGS_SUCCESS should return old state if nothing is returned', () => {
  const newState = reduce(actions.savingSettingsSuccess({userSettings: 'blee'}), {courseSettings: "blah"})
  deepEqual(newState.courseSettings, "blah")
})

test('GET_COURSE_SETTINGS_SUCCESS should return paylod for user settings', () => {
  const newState = reduce(actions.getUserSettingsSuccess({userSettings: "blah"}))
  deepEqual(newState.userSettings, {userSettings: "blah"})
})

test('SAVING_SETTINGS_SUCCESS should return paylod for user settings', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: "blah", userSettings: 'blee'}))
  deepEqual(newState.userSettings, "blee")
})
