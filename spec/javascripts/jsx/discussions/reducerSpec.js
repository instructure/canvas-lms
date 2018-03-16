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

test('GET_DISCUSSIONS_SUCCESS properly sorts discussions', () => {
  const dispatchData = {
    data: [
      // Pinned is sorted by position
      {id: 1, pinned: true, locked: false, position: 2, last_reply_at: "2018-02-26T23:35:57Z"},
      {id: 2, pinned: true, locked: true, position: 1, last_reply_at: "2017-02-26T23:35:57Z"},

      // Unpinned is sorted by date last modified
      {id: 3, pinned: false, locked: false, position: null, last_reply_at: "2018-02-26T23:35:57Z"},
      {id: 4, pinned: false, locked: false, position: null, last_reply_at: "2017-02-26T23:35:57Z"},

      // Closed for comments is sorted by date last modified
      {id: 5, pinned: false, locked: true, position: null, last_reply_at: "2017-02-26T23:35:57Z"},
      {id: 6, pinned: false, locked: true, position: null, last_reply_at: "2018-02-26T23:35:57Z"},
    ]
  }

  const newState = reduce(actions.getDiscussionsSuccess(dispatchData), {
    pinnedDiscussions: [],
    unpinnedDiscussions: [],
    closedForCommentsDiscussions: [],
  })

  deepEqual(newState.pinnedDiscussions.map(d => d.id), [2, 1])
  deepEqual(newState.unpinnedDiscussions.map(d => d.id), [3, 4])
  deepEqual(newState.closedForCommentsDiscussions.map(d => d.id), [6, 5])
})

test('UPDATE_DISCUSSION_START should not update pinned discussion', () => {
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

test('UPDATE_DISCUSSION_START should not update unpinned discussion', () => {
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

test('UPDATE_DISCUSSION_START should not update closedForComments discussion', () => {
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

test('GET_COURSE_SETTINGS_SUCCESS should return payload', () => {
  const newState = reduce(actions.getCourseSettingsSuccess({courseSettings: "blah"}))
  deepEqual(newState.courseSettings, {courseSettings: "blah"})
})

test('SAVING_SETTINGS_SUCCESS should return payload if returned', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: "blah", userSettings: 'blee'}))
  deepEqual(newState.courseSettings, "blah")
})

test('SAVING_SETTINGS_SUCCESS should return old state if nothing is returned', () => {
  const newState = reduce(actions.savingSettingsSuccess({userSettings: 'blee'}), {courseSettings: "blah"})
  deepEqual(newState.courseSettings, "blah")
})

test('GET_COURSE_SETTINGS_SUCCESS should return payload for user settings', () => {
  const newState = reduce(actions.getUserSettingsSuccess({userSettings: "blah"}))
  deepEqual(newState.userSettings, {userSettings: "blah"})
})

test('SAVING_SETTINGS_SUCCESS should return payload for user settings', () => {
  const newState = reduce(actions.savingSettingsSuccess({courseSettings: "blah", userSettings: 'blee'}))
  deepEqual(newState.userSettings, "blee")
})
test('ARRANGE_PINNED_DISCUSSIONS should update unpinned discussion', () => {
  const newState = reduce(actions.arrangePinnedDiscussions({ order: [10, 5, 2, 1] }), {
    pinnedDiscussions: [
      { title: "landon", id: 1, pinned: true, locked: false },
      { title: "venk", id: 5, pinned: true, locked: false },
      { title: "steven", id: 2, pinned: true, locked: false },
      { title: "aaron", id: 10, pinned: true, locked: false }
    ]
  })
  deepEqual(newState.pinnedDiscussions, [
    { title: "aaron", id: 10, pinned: true, locked: false },
    { title: "venk", id: 5, pinned: true, locked: false },
    { title: "steven", id: 2, pinned: true, locked: false },
    { title: "landon", id: 1, pinned: true, locked: false }
  ])
})

test('DUPLICATE_DISCUSSIONS_SUCCESS should update pinned discussion positions', () => {
  const originalState = {
    pinnedDiscussions: [
      { title: "landon", id: 2, position: 20, pinned: true, locked: false },
      { title: "steven", id: 3, position: 21, pinned: true, locked: false },
      { title: "aaron", id: 4, position: 22, pinned: true, locked: false }
    ],
    closedForCommentsDiscussions: [],
    unpinnedDiscussions: []
  }
  const payload = {
    originalId: 3,
    newDiscussion: {
      id: 5,
      title: "steven Copy",
      position: 22,
      pinned: true,
      locked: false,
      new_positions: { 2: 20, 3: 21, 5: 22, 4: 23 }
    }
  }

  const newState = reduce(actions.duplicateDiscussionSuccess(payload), originalState)
  const expectedPinnedDiscussions = [
    { title: "landon", id: 2, position: 20, pinned: true, locked: false },
    { title: "steven", id: 3, position: 21, pinned: true, locked: false },
    { title: "steven Copy", id: 5, position: 22, pinned: true, locked: false, focusOn: 'title'},
    { title: "aaron", id: 4, position: 23, pinned: true, locked: false },
  ]
  deepEqual(newState.pinnedDiscussions, expectedPinnedDiscussions)
  deepEqual(newState.closedForCommentsDiscussions, [])
  deepEqual(newState.unpinnedDiscussions, [])

})

test('DUPLICATE_DISCUSSIONS_SUCCESS should work properly for unpinned discussions', () => {
  const originalState = {
    pinnedDiscussions: [],
    closedForCommentsDiscussions: [],
    unpinnedDiscussions: [
      { title: "landon", id: 2, pinned: false, locked: false },
      { title: "steven", id: 5,  pinned: false, locked: false },
      { title: "aaron", id: 1, pinned: false, locked: false }
    ],
  }
  const payload = {
    originalId: 5,
    newDiscussion: {
      id: 6,
      title: "steven Copy",
      pinned: false,
      locked: false,
    }
  }

  const newState = reduce(actions.duplicateDiscussionSuccess(payload), originalState)
  const expectedUnpinnedDiscussions = [
    { title: "landon", id: 2, pinned: false, locked: false },
    { title: "steven", id: 5, pinned: false, locked: false },
    { title: "steven Copy", id: 6, pinned: false, locked: false, focusOn: 'title'},
    { title: "aaron", id: 1, pinned: false, locked: false },
  ]
  deepEqual(newState.unpinnedDiscussions, expectedUnpinnedDiscussions)
  deepEqual(newState.pinnedDiscussions, [])
  deepEqual(newState.closedForCommentsDiscussions, [])
})

test('UPDATE_DISCUSSIONS_SEARCH should set the filter flag on discussions', () => {
  const initialState = {
    pinnedDiscussions: [
      {title: 'foo', pinned: true, locked: false, filtered: false, read_state: 'read',   unread_count: 1},
      {title: 'foo', pinned: true, locked: false, filtered: false, read_state: 'read',   unread_count: 0},
      {title: 'foo', pinned: true, locked: true,  filtered: false, read_state: 'unread', unread_count: 0},
      {title: 'bar', pinned: true, locked: true,  filtered: false, read_state: 'unread', unread_count: 1},
    ],
    unpinnedDiscussions: [
      {title: 'foo', pinned: false, locked: false, filtered: false, read_state: 'read',   unread_count: 1},
      {title: 'foo', pinned: false, locked: false, filtered: false, read_state: 'read',   unread_count: 0},
      {title: 'foo', pinned: true, locked: true,  filtered: false, read_state: 'unread', unread_count: 0},
      {title: 'bar', pinned: false, locked: false, filtered: false, read_state: 'unread', unread_count: 1},
    ],
    closedForCommentsDiscussions: [
      {title: 'foo', pinned: false, locked: true, filtered: false, read_state: 'read',   unread_count: 1},
      {title: 'foo', pinned: false, locked: true, filtered: false, read_state: 'read',   unread_count: 0},
      {title: 'foo', pinned: true, locked: true,  filtered: false, read_state: 'unread', unread_count: 0},
      {title: 'bar', pinned: false, locked: true, filtered: false, read_state: 'unread', unread_count: 1},
    ]
  }

  const dispatchData = {
    searchTerm: 'foo',
    filter: 'unread',
  }

  const newState = reduce(actions.updateDiscussionsSearch(dispatchData), initialState)

  deepEqual(newState.pinnedDiscussions.map(d => d.filtered), [false, true, false, true])
  deepEqual(newState.unpinnedDiscussions.map(d => d.filtered), [false, true, false, true])
  deepEqual(newState.closedForCommentsDiscussions.map(d => d.filtered), [false, true, false, true])
})
