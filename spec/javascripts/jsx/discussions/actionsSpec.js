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
import * as apiClient from 'jsx/discussions/apiClient'
import $ from 'jquery';
import 'compiled/jquery.rails_flash_notifications' // eslint-disable-line

function getState() {
  return ([{ id: 1 }, { id: 2, shouldGetFocus: true }] )
}

let sandbox = []

const mockApiClient = (method, res) => {
  sandbox.push(sinon.sandbox.create())
  sandbox[sandbox.length - 1].stub(apiClient, method).returns(res)
}

const mockSuccess = (method, data = {}) => mockApiClient(method, Promise.resolve(data))
const mockFail = (method, err = new Error('Request Failed')) => mockApiClient(method, Promise.reject(err))

QUnit.module('Discussions redux actions', {
  teardown () {
    sandbox.forEach(mock => mock.restore())
    sandbox = []
  }
})

test('updateDiscussion dispatches UPDATE_DISCUSSION_SUCCESS', (assert) => {
  const done = assert.async()
  mockSuccess('updateDiscussion', { data: { locked: false, pinned: true } })
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: false, locked: false }
  const updateFields = { pinned: true }
  const dispatchSpy = sinon.spy()
  actions.updateDiscussion(discussion, updateFields, {})(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: {
            locked: false,
            pinned: true
          },
        },
        type: "UPDATE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('updateDiscussion calls apiClient.updateDiscussion', () => {
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: true}
  const updateFields = {pinned: false}
  const dispatchSpy = sinon.spy()

  mockSuccess('updateDiscussion', {})
  actions.updateDiscussion(discussion, updateFields, {})(dispatchSpy, () => state)
  deepEqual(apiClient.updateDiscussion.firstCall.args[1], discussion)
  deepEqual(apiClient.updateDiscussion.firstCall.args[2], updateFields)
})

test('updateDiscussion dispatches UPDATE_DISCUSSION_FAIL if promise fails', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const updateFields = {locked: true}
  const dispatchSpy = sinon.spy()

  mockFail('updateDiscussion', 'something bad happened')
  actions.updateDiscussion(discussion, updateFields, {})(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          err: "something bad happened",
          message: "Updating discussion failed"
        },
        type: "UPDATE_DISCUSSION_FAIL"
      }
    ]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('updateDiscussion calls screenReaderFlash if successful and success message present', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const updateFields = {locked: true}
  const flashMessages = { successMessage: 'success message' }
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockSuccess('updateDiscussion', {})
  actions.updateDiscussion(discussion, updateFields, flashMessages)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["success message"])
    flashStub.restore()
    done()
  })
})


test('updateDiscussion does not call screenReaderFlash if successful and no success message present', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const updateFields = {locked: true}
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockSuccess('updateDiscussion', {})
  actions.updateDiscussion(discussion, updateFields, {})(dispatchSpy, () => state)

  setTimeout(() => {
    equal(flashStub.callCount, 0)
    flashStub.restore()
    done()
  })
})

test('updateDiscussion calls screenReaderFlash if unsuccessful with custom flash message', (assert) => {
  const done = assert.async()
  const state = { discussions: { pages: { 1: { items: [] } }, currentPage: 1 } }
  const discussion = { pinned: true, locked: false}
  const updateFields = {locked: true}
  const flashMessages = { failMessage: 'fail message' }
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockFail('updateDiscussion', 'badness occurres')
  actions.updateDiscussion(discussion, updateFields, flashMessages)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["fail message"])
    flashStub.restore()
    done()
  })
})

test('handleDrop throws exception if updating a field that does not exist on the discussion', (assert) => {
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  const discussion = { pinned: true, locked: false}
  const updateFields = {foobar: true}
  const dispatchSpy = sinon.spy()

  assert.throws(
    function() {
      actions.handleDrop(discussion, updateFields, {})(dispatchSpy, () => state)
    },
    "field foobar does not exist in the discussion"
  )
})

test('handleDrop dispatches DRAG_AND_DROP_START', (assert) => {
  const done = assert.async()
  mockSuccess('updateDiscussion', {})
  mockSuccess('reorderPinnedDiscussions', {})
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  actions.handleDrop({id: 1, pinned: false}, {pinned: true}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: {id: 1, pinned: true},
          order: [1, 2]
        },
        type: "DRAG_AND_DROP_START"
      }
    ]
    deepEqual(dispatchSpy.firstCall.args, expected)
    done()
  })
})

test('handleDrop dispatches DRAG_AND_DROP_SUCCESS if no api calls fail', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockSuccess('updateDiscussion', {})
  mockSuccess('reorderPinnedDiscussions', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: true}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(dispatchSpy.secondCall.args, [{type: "DRAG_AND_DROP_SUCCESS" }])
    done()
  })
})

test('handleDrop dispatches DRAG_AND_DROP_FAIL if updateDiscussion api call fails', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockFail('updateDiscussion', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: true}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [{
      payload: {
        order: [2],
        discussion: {
          id: 1,
          pinned: false
        },
        err: {},
        message: "Failed to update discussion",
      },
      type: 'DRAG_AND_DROP_FAIL'
    }]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('handleDrop dispatches DRAG_AND_DROP_FAIL if reorderPinnedDiscussions api call fails', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockSuccess('updateDiscussion', {})
  mockFail('reorderPinnedDiscussions', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: true}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [{
      payload: {
        order: [2, 1],
        discussion: {
          id: 1,
          pinned: true
        },
        err: {},
        message: "Failed to update discussion",
      },
      type: 'DRAG_AND_DROP_FAIL'
    }]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('handleDrop calls reorderPinnedDiscussions if pinned and order present', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockSuccess('updateDiscussion', {})
  mockSuccess('reorderPinnedDiscussions', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: true}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(apiClient.reorderPinnedDiscussions.firstCall.args[1], [1, 2])
    done()
  })
})

test('handleDrop does not call reorderPinnedDiscussions if discussion is not pinned', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockSuccess('updateDiscussion', {})
  mockSuccess('reorderPinnedDiscussions', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: false}, [1, 2])(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(apiClient.reorderPinnedDiscussions.called, false)
    done()
  })
})

test('handleDrop does not call reorderPinnedDiscussions if ordering not present', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {
      1: {id: 1, pinned: false},
      2: {id: 2, pinned: true},
    },
    pinnedDiscussionIds: [2],
    unpinnedDiscussionIds: [1],
    closedForCommentsDiscussions: [],
  }
  mockSuccess('updateDiscussion', {})
  mockSuccess('reorderPinnedDiscussions', {})
  actions.handleDrop({id: 1, pinned: false}, {pinned: true})(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(apiClient.reorderPinnedDiscussions.called, false)
    done()
  })
})

test('does not call the API if the discussion has a subscription_hold', () => {
  const dispatchSpy = sinon.spy()
  const discussion = { subscription_hold: 'test hold' }
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)
  equal(dispatchSpy.callCount, 0)
})

test('calls unsubscribeFromTopic if the discussion is currently subscribed', () => {
  const dispatchSpy = sinon.spy()
  const discussion = { id: 1, subscribed: true }
  mockSuccess('unsubscribeFromTopic', {})
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)
  equal(apiClient.unsubscribeFromTopic.callCount, 1)
  deepEqual(apiClient.unsubscribeFromTopic.firstCall.args, [getState(), discussion])
})

test('calls subscribeToTopic if the discussion is currently unsubscribed', () => {
  const dispatchSpy = sinon.spy()
  const discussion = { id: 1, subscribed: false }
  mockSuccess('subscribeToTopic', {})
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)
  equal(apiClient.subscribeToTopic.callCount, 1)
  deepEqual(apiClient.subscribeToTopic.firstCall.args, [getState(), discussion])
})

test('dispatches toggleSubscribeSuccess with unsubscription status if currently subscribed', (assert) => {
  const dispatchSpy = sinon.spy()
  const done = assert.async()
  const discussion = { id: 1, subscribed: true }
  mockSuccess('unsubscribeFromTopic', {})
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { id: 1, subscribed: false },
      type: "TOGGLE_SUBSCRIBE_SUCCESS"
    }]
    deepEqual(dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('dispatches toggleSubscribeSuccess with subscription status if currently unsubscribed', (assert) => {
  const dispatchSpy = sinon.spy()
  const done = assert.async()
  const discussion = { id: 1, subscribed: false }
  mockSuccess('subscribeToTopic', {})
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { id: 1, subscribed: true },
      type: "TOGGLE_SUBSCRIBE_SUCCESS"
    }]
    deepEqual(dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('dispatches toggleSubscribeFail in an error occures on the API call', (assert) => {
  const dispatchSpy = sinon.spy()
  const done = assert.async()
  const flashStub = sinon.spy($, 'screenReaderFlashMessageExclusive')
  const discussion = { id: 1, subscribed: false }

  mockFail('subscribeToTopic', "test error message")
  actions.toggleSubscriptionState(discussion)(dispatchSpy, getState)

  setTimeout(() => {
    const expectedArgs = [{
      payload: { message: 'Subscribe failed', err: "test error message" },
      type: "TOGGLE_SUBSCRIBE_FAIL"
    }]
    deepEqual(dispatchSpy.secondCall.args, expectedArgs)
    deepEqual(flashStub.firstCall.args, ["Subscribe failed"]);
    flashStub.restore()
    done()
  })
})

test('saveSettings dispatches SAVING_SETTINGS_START', (assert) => {
  const done = assert.async()
  mockSuccess('saveUserSettings', {})
  mockSuccess('saveCourseSettings', {})

  const courseSettings = {
    allow_student_discussion_topics: true,
    allow_student_forum_attachments: true,
    allow_student_discussion_editing: true,
    grading_standard_enabled: false,
    grading_standard_id: null,
    allow_student_organized_groups: true,
    hide_final_grades: false,
    hide_distribution_graphs: false,
    lock_all_announcements: true,
    restrict_student_past_view: false,
    restrict_student_future_view: false,
    show_announcements_on_home_page: false,
    home_page_announcement_limit: 3,
    image_url: null,
    image_id: null,
    image: null,
  }
  const userSettings = {
    manual_mark_as_read: false,
    collapse_global_nav: false,
  }
  const state = {contextId: "1", currentUserId: "1", userSettings}
  const dispatchSpy = sinon.spy()
  actions.saveSettings(userSettings, courseSettings)(dispatchSpy, () => state)
  setTimeout(() => {
    const expected = [
      {
        type: "SAVING_SETTINGS_START"
      }
    ]
    deepEqual(dispatchSpy.firstCall.args, expected)
    done()
  })
})

test('saveSettings calls screenReaderFlash if successful with only user settings', (assert) => {
  const done = assert.async()
  const userSettings = {
    markAsRead: false,
    collapse_global_nav: false,
  }
  const state = {contextId: "1", currentUserId: "1", userSettings}
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockSuccess('saveUserSettings', {})
  actions.saveSettings(userSettings)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["Saved discussion settings successfully"])
    flashStub.restore()
    done()
  })
})

test('saveSettings calls screenReaderFlash if successful with course settings', (assert) => {
  const done = assert.async()
  const userSettings = {
    markAsRead: false,
    collapse_global_nav: false,
  }
  const courseSettings = {
    allow_student_discussion_topics: true,
    allow_student_forum_attachments: true,
    allow_student_discussion_editing: true,
    grading_standard_enabled: false,
    grading_standard_id: null,
    allow_student_organized_groups: true,
    hide_final_grades: false,
  }
  const state = {contextId: "1", currentUserId: "1", userSettings}
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockSuccess('saveUserSettings', {})
  mockSuccess('saveCourseSettings', {})
  actions.saveSettings(userSettings, courseSettings)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["Saved discussion settings successfully"])
    flashStub.restore()
    done()
  })
})

test('saveSettings calls screenReaderFlash if failed with course settings', (assert) => {
  const done = assert.async()
  const userSettings = {
    markAsRead: false,
    collapse_global_nav: false,
  }
  const courseSettings = {
    allow_student_discussion_topics: true,
    allow_student_forum_attachments: true,
    allow_student_discussion_editing: true,
    grading_standard_enabled: false,
    grading_standard_id: null,
    allow_student_organized_groups: true,
    hide_final_grades: false,
  }
  const state = {contextId: "1", currentUserId: "1", userSettings}
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')

  mockSuccess('saveUserSettings', {})
  mockFail('saveCourseSettings', {})
  actions.saveSettings(userSettings, courseSettings)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["Error saving discussion settings"])
    flashStub.restore()
    done()
  })
})

test('calls api for duplicating if requested', () => {
  const dispatchSpy = sinon.spy()
  mockSuccess('duplicateDiscussion', {})
  actions.duplicateDiscussion(1)(dispatchSpy, getState)
  equal(apiClient.duplicateDiscussion.callCount, 1)
  deepEqual(apiClient.duplicateDiscussion.firstCall.args, [getState(), 1])
})

test('dispatches duplicateDiscussionSuccess if api call succeeds', (assert) => {
  const dispatchSpy = sinon.spy()
  const done = assert.async()
  mockSuccess('duplicateDiscussion', { data: { id: 3 }})
  actions.duplicateDiscussion(1)(dispatchSpy, getState)
  setTimeout(() => {
    const expectedArgs = [{
      payload: { originalId: 1, newDiscussion: { id: 3, focusOn: "title" }},
      type: "DUPLICATE_DISCUSSION_SUCCESS"
    }]
    deepEqual(dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('dispatches duplicateDiscussionFail if api call fails', (assert) => {
  const dispatchSpy = sinon.spy()
  const done = assert.async()
  const discussion = { id: 1 }
  mockFail('duplicateDiscussion', "YOU FAILED, YOU IDIOT")
  actions.duplicateDiscussion(discussion.id)(dispatchSpy, getState)
  setTimeout(() => {
    const expectedArgs = [{
      payload: { message: 'Duplication failed', err: "YOU FAILED, YOU IDIOT" },
      type: "DUPLICATE_DISCUSSION_FAIL"
    }]
    deepEqual(dispatchSpy.secondCall.args, expectedArgs)
    done()
  })
})

test('searchDiscussions dispatches UPDATE_DISCUSSIONS_SEARCH', () => {
  const dispatchSpy = sinon.spy()
  const state = {
    allDiscussions: {},
    pinnedDiscussionIds: [],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  actions.searchDiscussions({ searchTerm: 'foobar', filter: 'unread' })(dispatchSpy, () => state)
  const expected = [
    {
      payload: {
        searchTerm: 'foobar',
        filter: 'unread',
      },
      type: "UPDATE_DISCUSSIONS_SEARCH"
    }
  ]
  deepEqual(dispatchSpy.firstCall.args, expected)
})

test('searchDiscussions announces number of results found to screenreader', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  const flashStub = sinon.spy($, 'screenReaderFlashMessageExclusive')
  const state = {
    allDiscussions: {
      1: {id: 1, filtered: true},
      2: {id: 2, filtered: false},
      3: {id: 3, filtered: true},
      4: {id: 4, filtered: false},
      5: {id: 5, filtered: true},
      6: {id: 6, filtered: false},
    },
    pinnedDiscussions: [1, 2],
    unpinnedDiscussions: [3, 4],
    closedForCommentsDiscussions: [5, 6],
  }
  actions.searchDiscussions({ searchTerm: 'foobar', filter: 'unread' })(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["3 discussions found."])
    flashStub.restore()
    done()
  })
})

test('deleteDiscussion dispatches DELETE_DISCUSSION_SUCCESS on success', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: { id: 1 },
          nextFocusDiscussion: {
            focusId: undefined,
            focusOn: undefined,
          },
        },
        type: "DELETE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.thirdCall.args, expected)
    done()
  })
})

test('deleteDiscussion dispatches DELETE_FOCUS_PENDING on success', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        type: "DELETE_FOCUS_PENDING"
      }
    ]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('deleteDiscussion dispatches DELETE_DISCUSSION_FAIL on failure', (assert) => {
  const done = assert.async()
  mockFail('deleteDiscussion', 'test_error')
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1, title: 'foo' }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          message: 'Failed to delete discussion foo',
          discussion: { id: 1, title: 'foo' },
          err: 'test_error'
        },
        type: "DELETE_DISCUSSION_FAIL"
      }
    ]
    deepEqual(dispatchSpy.secondCall.args, expected)
    done()
  })
})

test('deleteDiscussion calls screenReaderFlash on success', (assert) => {
  const done = assert.async()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1, title: 'foo' }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["Successfully deleted discussion foo"])
    flashStub.restore()
    done()
  })
})

test('deleteDiscussion calls screenReaderFlash on failure', (assert) => {
  const done = assert.async()
  const flashStub = sinon.spy($, 'screenReaderFlashMessage')
  mockFail('deleteDiscussion', 'test_error')
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1, title: 'foo' }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    deepEqual(flashStub.firstCall.args, ["Failed to delete discussion foo"])
    flashStub.restore()
    done()
  })
})

test('deleteDiscussion does not set focusOn if collection is empty after delete', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {1: {id: 1}},
    pinnedDiscussionIds: [1],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: { id: 1 },
          nextFocusDiscussion: {
            focusId: undefined,
            focusOn: undefined,
          },
        },
        type: "DELETE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.thirdCall.args, expected)
    done()
  })
})

test('deleteDiscussion sets focusOn to toggleButton if deleting first item in collection', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {
      1: {id: 1},
      2: {id: 2},
    },
    pinnedDiscussionIds: [1, 2],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 1 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: { id: 1 },
          nextFocusDiscussion: {
            focusId: 2,
            focusOn: 'toggleButton',
          },
        },
        type: "DELETE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.thirdCall.args, expected)
    done()
  })
})

test('deleteDiscussion sets focusOn to manageMenu if user has delete perms', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {
      1: {id: 1, permissions: {delete: true}},
      2: {id: 2, permissions: {delete: true}},
    },
    pinnedDiscussionIds: [1, 2],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 2 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: { id: 2 },
          nextFocusDiscussion: {
            focusId: 1,
            focusOn: 'manageMenu',
          },
        },
        type: "DELETE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.thirdCall.args, expected)
    done()
  })
})

test('deleteDiscussion sets focusOn to title if user does not have delete perms', (assert) => {
  const done = assert.async()
  mockSuccess('deleteDiscussion', {})
  const state = {
    allDiscussions: {
      1: {id: 1, permissions: {delete: false}},
      2: {id: 2, permissions: {delete: false}},
    },
    pinnedDiscussionIds: [1, 2],
    unpinnedDiscussionIds: [],
    closedForCommentsDiscussionIds: [],
  }
  const discussion = { id: 2 }
  const dispatchSpy = sinon.spy()
  actions.deleteDiscussion(discussion)(dispatchSpy, () => state)

  setTimeout(() => {
    const expected = [
      {
        payload: {
          discussion: { id: 2 },
          nextFocusDiscussion: {
            focusId: 1,
            focusOn: 'title',
          },
        },
        type: "DELETE_DISCUSSION_SUCCESS"
      }
    ]
    deepEqual(dispatchSpy.thirdCall.args, expected)
    done()
  })
})

test('deleteFocusDone dispatches DELETE_FOCUS_CLEANUP', (assert) => {
  const done = assert.async()
  const dispatchSpy = sinon.spy()
  actions.deleteFocusDone()(dispatchSpy, () => {})
  setTimeout(() => {
    const expected = [{ type: "DELETE_FOCUS_CLEANUP" }]
    deepEqual(dispatchSpy.firstCall.args, expected)
    done()
  })
})
