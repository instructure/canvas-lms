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

import actions from 'ui/features/discussion_topics_index/react/actions'
import reducer from 'ui/features/discussion_topics_index/react/rootReducer'

QUnit.module('Discussions reducer')

const reduce = (action, state = {}) => reducer(state, action)

test('GET_DISCUSSIONS_SUCCESS sets allDiscussions', () => {
  const dispatchData = {
    data: [
      {id: 1, pinned: true, locked: false, position: 2, last_reply_at: '2018-02-26T23:35:57Z'},
      {id: 2, pinned: false, locked: false, position: null, last_reply_at: '2018-02-26T23:35:57Z'},
    ],
  }
  const newState = reduce(actions.getDiscussionsSuccess(dispatchData), {allDiscussions: {}})
  const expectedData = {
    1: {
      id: 1,
      pinned: true,
      locked: false,
      position: 2,
      last_reply_at: '2018-02-26T23:35:57Z',
      filtered: false,
    },
    2: {
      id: 2,
      pinned: false,
      locked: false,
      position: null,
      last_reply_at: '2018-02-26T23:35:57Z',
      filtered: false,
    },
  }
  deepEqual(newState.allDiscussions, expectedData)
})

test('GET_DISCUSSIONS_SUCCESS properly sorts discussions', () => {
  const dispatchData = {
    data: [
      // Pinned is sorted by position
      {id: 1, pinned: true, locked: false, position: 2, last_reply_at: '2018-02-26T23:35:57Z'},
      {id: 2, pinned: true, locked: true, position: 1, last_reply_at: '2017-02-26T23:35:57Z'},

      // Unpinned is sorted by date last modified
      {id: 3, pinned: false, locked: false, position: null, last_reply_at: '2018-02-26T23:35:57Z'},
      {id: 4, pinned: false, locked: false, position: null, last_reply_at: '2017-02-26T23:35:57Z'},

      // Closed for comments is sorted by date last modified
      {id: 5, pinned: false, locked: true, position: null, last_reply_at: '2017-02-26T23:35:57Z'},
      {id: 6, pinned: false, locked: true, position: null, last_reply_at: '2018-02-26T23:35:57Z'},
    ],
  }

  const newState = reduce(actions.getDiscussionsSuccess(dispatchData), {
    pinnedDiscussionIds: [],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  })

  deepEqual(newState.pinnedDiscussionIds, [2, 1])
  deepEqual(newState.unpinnedDiscussionIds, [3, 4])
  deepEqual(newState.closedForCommentsDiscussionIds, [6, 5])
})

test('UPDATE_DISCUSSION_SUCCESS should update pinnedDiscussionIds when pinning a discussion', () => {
  const newState = reduce(
    actions.updateDiscussionSuccess({discussion: {id: 1, pinned: true, locked: false}}),
    {
      allDiscussions: {1: {id: 1, pinned: false, locked: false}},
      pinnedDiscussionIds: [1],
    }
  )
  deepEqual(newState.closedForCommentsDiscussionIds, [])
  deepEqual(newState.unpinnedDiscussionIds, [])
  deepEqual(newState.pinnedDiscussionIds, [1])
})

test('UPDATE_DISCUSSION_SUCCESS should update unpinnedDiscussinIds when unpinning a discussion', () => {
  const newState = reduce(
    actions.updateDiscussionSuccess({discussion: {id: 1, pinned: false, locked: false}}),
    {
      allDiscussions: {1: {id: 1, pinned: true, locked: false}},
      pinnedDiscussionIds: [1],
    }
  )
  deepEqual(newState.closedForCommentsDiscussionIds, [])
  deepEqual(newState.unpinnedDiscussionIds, [1])
  deepEqual(newState.pinnedDiscussionIds, [])
})

test('UPDATE_DISCUSSION_SUCCESS should not update closedForComments discussion', () => {
  const newState = reduce(
    actions.updateDiscussionSuccess({discussion: {id: 1, pinned: false, locked: true}}),
    {
      allDiscussions: {1: {id: 1, pinned: true, locked: false}},
      pinnedDiscussionIds: [1],
    }
  )
  deepEqual(newState.closedForCommentsDiscussionIds, [1])
  deepEqual(newState.unpinnedDiscussionIds, [])
  deepEqual(newState.pinnedDiscussionIds, [])
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed to false when new state is false', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({id: 1, subscribed: false}), {
    allDiscussions: {1: {id: 1, subscribed: true}},
  })
  deepEqual(newState.allDiscussions[1], {id: 1, subscribed: false})
})

test('TOGGLE_SUBSCRIBE_SUCCESS should update subscribed to true when new state is true', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({id: 1, subscribed: true}), {
    allDiscussions: {1: {id: 1, subscribed: false}},
  })
  deepEqual(newState.allDiscussions[1], {id: 1, subscribed: true})
})

test('TOGGLE_SUBSCRIBE_SUCCESS should only update the state of the supplied id', () => {
  const newState = reduce(actions.toggleSubscribeSuccess({id: 1, subscribed: false}), {
    allDiscussions: {
      1: {id: 1, subscribed: true},
      2: {id: 2, subscribed: true},
    },
  })

  deepEqual(newState.allDiscussions[1], {id: 1, subscribed: false})
  deepEqual(newState.allDiscussions[2], {id: 2, subscribed: true})
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
  const newState = reduce(actions.getCourseSettingsSuccess({courseSettings: 'blah'}))
  deepEqual(newState.courseSettings, {courseSettings: 'blah'})
})

test('SAVING_SETTINGS_SUCCESS should return payload if returned', () => {
  const newState = reduce(
    actions.savingSettingsSuccess({courseSettings: 'blah', userSettings: 'blee'})
  )
  deepEqual(newState.courseSettings, 'blah')
})

test('SAVING_SETTINGS_SUCCESS should return old state if nothing is returned', () => {
  const newState = reduce(actions.savingSettingsSuccess({userSettings: 'blee'}), {
    courseSettings: 'blah',
  })
  deepEqual(newState.courseSettings, 'blah')
})

test('GET_COURSE_SETTINGS_SUCCESS should return payload for user settings', () => {
  const newState = reduce(actions.getUserSettingsSuccess({userSettings: 'blah'}))
  deepEqual(newState.userSettings, {userSettings: 'blah'})
})

test('SAVING_SETTINGS_SUCCESS should return payload for user settings', () => {
  const newState = reduce(
    actions.savingSettingsSuccess({courseSettings: 'blah', userSettings: 'blee'})
  )
  deepEqual(newState.userSettings, 'blee')
})

test('ARRANGE_PINNED_DISCUSSIONS should update unpinned discussion', () => {
  const newState = reduce(actions.arrangePinnedDiscussions({order: [10, 5, 2, 1]}), {
    pinnedDiscussionIds: [1, 2, 5, 10],
  })
  deepEqual(newState.pinnedDiscussionIds, [10, 5, 2, 1])
})

test('DUPLICATE_DISCUSSIONS_SUCCESS should update discussion positions', () => {
  const originalState = {
    allDiscussions: {
      2: {title: 'landon', id: 2, position: 20, pinned: true, locked: false},
      3: {title: 'steven', id: 3, position: 21, pinned: true, locked: false},
      4: {title: 'aaron', id: 4, position: 22, pinned: true, locked: false},
    },
  }
  const payload = {
    originalId: 3,
    newDiscussion: {
      id: 5,
      title: 'steven Copy',
      position: 22,
      pinned: true,
      locked: false,
      new_positions: {2: 20, 3: 21, 5: 22, 4: 23},
    },
  }

  const newState = reduce(actions.duplicateDiscussionSuccess(payload), originalState)
  deepEqual(newState.allDiscussions[2].position, 20)
  deepEqual(newState.allDiscussions[3].position, 21)
  deepEqual(newState.allDiscussions[4].position, 23)
  deepEqual(newState.allDiscussions[5].position, 22)
})

test('UPDATE_DISCUSSIONS_SEARCH should set the filter flag on discussions', () => {
  const initialState = {
    allDiscussions: {
      1: {id: 1, title: 'foo', filtered: false, read_state: 'read', unread_count: 1},
      2: {id: 2, title: 'foo', filtered: false, read_state: 'read', unread_count: 0},

      3: {id: 3, title: 'foo', filtered: false, read_state: 'unread', unread_count: 1},
      4: {id: 4, title: 'foo', filtered: false, read_state: 'unread', unread_count: 0},

      5: {id: 5, title: 'bar', filtered: false, read_state: 'read', unread_count: 1},
      6: {id: 6, title: 'bar', filtered: false, read_state: 'read', unread_count: 0},
    },
  }
  const dispatchData = {
    searchTerm: 'foo',
    filter: 'unread',
  }

  const newState = reduce(actions.updateDiscussionsSearch(dispatchData), initialState)
  deepEqual(newState.allDiscussions[1].filtered, false)
  deepEqual(newState.allDiscussions[2].filtered, true)
  deepEqual(newState.allDiscussions[3].filtered, false)
  deepEqual(newState.allDiscussions[4].filtered, false)
  deepEqual(newState.allDiscussions[5].filtered, true)
  deepEqual(newState.allDiscussions[6].filtered, true)
})

test('UPDATE_DISCUSSIONS_SEARCH should search for discussions based on author', () => {
  const initialState = {
    allDiscussions: {
      1: {
        id: 1,
        title: 'foo',
        filtered: false,
        read_state: 'read',
        unread_count: 1,
        author: {display_name: 'wacko_steven'},
      },
      2: {
        id: 2,
        title: 'foo',
        filtered: false,
        read_state: 'read',
        unread_count: 0,
        author: {display_name: 'wacko_landon'},
      },

      3: {
        id: 3,
        title: 'foo',
        filtered: false,
        read_state: 'unread',
        unread_count: 1,
        author: {display_name: 'wacko_steven'},
      },
      4: {
        id: 4,
        title: 'foo',
        filtered: false,
        read_state: 'unread',
        unread_count: 0,
        author: {display_name: 'wacko_landon'},
      },

      5: {
        id: 5,
        title: 'bar',
        filtered: false,
        read_state: 'read',
        unread_count: 1,
        author: {display_name: 'wacko_steven'},
      },
      6: {
        id: 6,
        title: 'bar',
        filtered: false,
        read_state: 'read',
        unread_count: 0,
        author: {display_name: 'wacko_landon'},
      },
    },
  }
  const dispatchData = {
    searchTerm: 'steven',
    filter: 'read',
  }

  const newState = reduce(actions.updateDiscussionsSearch(dispatchData), initialState)
  const searchedDiscussions = Object.values(newState.allDiscussions).filter(disc => !disc.filtered)
  deepEqual(searchedDiscussions, [
    {
      id: 1,
      title: 'foo',
      filtered: false,
      read_state: 'read',
      unread_count: 1,
      author: {display_name: 'wacko_steven'},
    },
    {
      id: 3,
      title: 'foo',
      filtered: false,
      read_state: 'unread',
      unread_count: 1,
      author: {display_name: 'wacko_steven'},
    },
    {
      id: 5,
      title: 'bar',
      filtered: false,
      read_state: 'read',
      unread_count: 1,
      author: {display_name: 'wacko_steven'},
    },
  ])
})

test('UPDATE_DISCUSSIONS_SEARCH should search for anonymous author discussions when no author present', () => {
  const initialState = {
    allDiscussions: {
      1: {
        id: 1,
        title: 'foo',
        filtered: false,
        read_state: 'read',
        unread_count: 1,
      },
      2: {
        id: 2,
        title: 'foo',
        filtered: false,
        read_state: 'read',
        unread_count: 0,
        author: {display_name: 'wacko_landon'},
      },

      3: {
        id: 3,
        title: 'foo',
        filtered: false,
        read_state: 'unread',
        unread_count: 1,
        author: {display_name: 'wacko_steven'},
      },
      4: {
        id: 4,
        title: 'foo',
        filtered: false,
        read_state: 'unread',
        unread_count: 0,
      },

      5: {
        id: 5,
        title: 'bar',
        filtered: false,
        read_state: 'read',
        unread_count: 1,
        author: {display_name: 'wacko_steven'},
      },
      6: {
        id: 6,
        title: 'bar',
        filtered: false,
        read_state: 'read',
        unread_count: 0,
        author: {display_name: 'wacko_landon'},
      },
    },
  }
  const dispatchData = {
    searchTerm: 'anonymous',
    filter: 'read',
  }

  const newState = reduce(actions.updateDiscussionsSearch(dispatchData), initialState)
  const searchedDiscussions = Object.values(newState.allDiscussions).filter(disc => !disc.filtered)

  deepEqual(searchedDiscussions, [
    {
      id: 1,
      title: 'foo',
      filtered: false,
      read_state: 'read',
      unread_count: 1,
    },
    {
      id: 4,
      title: 'foo',
      filtered: false,
      read_state: 'unread',
      unread_count: 0,
    },
  ])
})

test('DELETE_DISCUSSION_SUCCESS should delete discussion and set focusOn', () => {
  const dispatchData = {
    discussion: {title: 'venk', id: 5, permissions: {delete: true}},
    nextFocusDiscussion: {
      focusId: 2,
      focusOn: 'manageMenu',
    },
  }
  const initialData = {
    allDiscussions: {
      1: {title: 'landon', id: 1, permissions: {delete: true}},
      2: {title: 'steven', id: 2, permissions: {delete: true}},
      5: {title: 'venk', id: 5, permissions: {delete: true}},
      10: {title: 'aaron', id: 10, permissions: {delete: true}},
    },
  }
  const newState = reduce(actions.deleteDiscussionSuccess(dispatchData), initialData)
  deepEqual(newState.allDiscussions, {
    1: {title: 'landon', id: 1, permissions: {delete: true}},
    2: {title: 'steven', id: 2, permissions: {delete: true}, focusOn: 'manageMenu'},
    10: {title: 'aaron', id: 10, permissions: {delete: true}},
  })
})

test('DRAG_AND_DROP should add order pinned discussion correctly', () => {
  const initialState = {
    allDiscussions: {
      1: {id: 1, pinned: true},
      2: {id: 2, pinned: true},
      3: {id: 3, pinned: true},
    },
    pinnedDiscussionIds: [1, 2, 3],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }

  const dispatchData = {
    order: [3, 2, 1],
    discussion: {id: 3, pinned: true},
  }

  // start and failure should do the same thing here, just called with
  // different arguments in the action.
  const states = [
    reduce(actions.dragAndDropStart(dispatchData), initialState),
    reduce(actions.dragAndDropFail(dispatchData), initialState),
  ]
  states.forEach(newState => {
    deepEqual(newState.pinnedDiscussionIds, [3, 2, 1])
    deepEqual(newState.unpinnedDiscussionIds, [])
    deepEqual(newState.closedForCommentsDiscussionIds, [])
  })
})

test('DRAG_AND_DROP should put pinned discussion without ordering at the bottom', () => {
  const initialState = {
    allDiscussions: {
      1: {id: 1, pinned: true},
      2: {id: 2, pinned: true},
      3: {id: 3, pinned: false},
    },
    pinnedDiscussionIds: [1, 2],
    unpinnedDiscussionIds: [3],
    closedForCommentsDiscussionIds: [],
  }

  const dispatchData = {
    order: undefined,
    discussion: {id: 3, pinned: true},
  }

  // start and failure should do the same thing here, just called with
  // different arguments in the action.
  const states = [
    reduce(actions.dragAndDropStart(dispatchData), initialState),
    reduce(actions.dragAndDropFail(dispatchData), initialState),
  ]
  states.forEach(newState => {
    deepEqual(newState.pinnedDiscussionIds, [1, 2, 3])
    deepEqual(newState.unpinnedDiscussionIds, [])
    deepEqual(newState.closedForCommentsDiscussionIds, [])
  })
})

test('DELETE_FOCUS_PENDING sets deleteFocusPending to true', () => {
  const initialState = {deleteFocusPending: false}
  const dispatchData = {}
  const newState = reduce(actions.deleteFocusPending(dispatchData), initialState)
  deepEqual(newState.deleteFocusPending, true)
})

test('DELETE_FOCUS_CLEANUP sets deleteFocusPending to false', () => {
  const initialState = {deleteFocusPending: true}
  const dispatchData = {}
  const newState = reduce(actions.deleteFocusCleanup(dispatchData), initialState)
  deepEqual(newState.deleteFocusPending, false)
})
