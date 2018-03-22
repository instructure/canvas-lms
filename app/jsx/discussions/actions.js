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

import I18n from 'i18n!discussions_v2'
import { createActions } from 'redux-actions'
import $ from 'jquery'

import * as apiClient from './apiClient'
import { createPaginationActions } from '../shared/reduxPagination'

const getDiscussionOpts = {
  fetchAll: true,
  headThunk: apiClient.headDiscussions,
}
const discussionActions = createPaginationActions('discussions', apiClient.getDiscussions, getDiscussionOpts)

const types = [
  ...discussionActions.actionTypes,
  'DRAG_AND_DROP_START',
  'DRAG_AND_DROP_SUCCESS',
  'DRAG_AND_DROP_FAIL',
  'UPDATE_DISCUSSIONS_SEARCH',
  'TOGGLE_MODAL_OPEN',
  'TOGGLE_SUBSCRIBE_START',
  'ARRANGE_PINNED_DISCUSSIONS',
  'TOGGLE_SUBSCRIBE_START',
  'TOGGLE_SUBSCRIBE_SUCCESS',
  'TOGGLE_SUBSCRIBE_FAIL',
  'GET_USER_SETTINGS_START',
  'GET_USER_SETTINGS_SUCCESS',
  'GET_USER_SETTINGS_FAIL',
  'GET_COURSE_SETTINGS_START',
  'GET_COURSE_SETTINGS_SUCCESS',
  'GET_COURSE_SETTINGS_FAIL',
  'SAVING_SETTINGS_START',
  'SAVING_SETTINGS_SUCCESS',
  'SAVING_SETTINGS_FAIL',
  'UPDATE_DISCUSSION_START',
  'UPDATE_DISCUSSION_SUCCESS',
  'UPDATE_DISCUSSION_FAIL',
  'DUPLICATE_DISCUSSION_START',
  'DUPLICATE_DISCUSSION_SUCCESS',
  'DUPLICATE_DISCUSSION_FAIL',
  'DELETE_DISCUSSION_START',
  'DELETE_DISCUSSION_SUCCESS',
  'DELETE_DISCUSSION_FAIL',
  'CLEAN_DISCUSSION_FOCUS'
]

const actions = Object.assign(
  createActions(...types),
  discussionActions.actionCreators,
)

function copyAndUpdateDiscussion(discussion, updatedFields, focusOn) {
  const discussionCopy = Object.assign({}, discussion);
  Object.keys(updatedFields).forEach(key => {
    if (!Object.prototype.hasOwnProperty.call(discussion, key)) {
      throw new Error(`field ${key} does not exist in the discussion`)
    }
    discussionCopy[key] = updatedFields[key]
  })
  if (focusOn) {
    discussionCopy.focusOn = focusOn
  }
  return discussionCopy
}

const defaultFailMessage = I18n.t('Updating discussion failed')

// We are assuming success here (mostly for the sake of drag and drop, where
// it would look really awkward to drop it, have it snap back to the original
// position, and then snap to the new position shortly after).
// focusOn must be one of 'title' or 'manageMenu' (or can be left unspecified)
// If set to a value, it will cause focus to end up on the title or manage menu
// of the updated discussion.

// TODO change this to the onSuccess paradigm. Much easier
actions.updateDiscussion = function(discussion, updatedFields, { successMessage, failMessage }, focusOn) {
  return (dispatch, getState) => {
    const discussionCopy = copyAndUpdateDiscussion(discussion, updatedFields, focusOn)
    dispatch(actions.updateDiscussionStart({discussion: discussionCopy}))

    apiClient.updateDiscussion(getState(), discussion, updatedFields)
      .then(_ => {
        dispatch(actions.updateDiscussionSuccess())
        if (successMessage) {
          $.screenReaderFlashMessage(successMessage)
        }
      })
      .catch(err => {
        $.screenReaderFlashMessage(failMessage || defaultFailMessage)
        dispatch(actions.updateDiscussionFail({
          message: failMessage || defaultFailMessage,
          discussion,
          err
        }))
      })
  }
}


// We need to assume success here, so that when we drag and drop something
// it does not snap back to its current location and then move to the
// correct location after the API call succeeds. This is a bit more complex
// as we could be making two API calls here as well (pinning a discussion
// and setting the order of the pin). Start by updating the store with
// this information, then rollback based on if either of the API calls
// failed.
actions.handleDrop = function(discussion, updatedFields, order) {
  return (dispatch, getState) => {
    const originalOrder = order ? getState().pinnedDiscussions.map(d => d.id) : undefined
    const discussionCopy = copyAndUpdateDiscussion(discussion, updatedFields)
    dispatch(actions.dragAndDropStart({discussion: discussionCopy, order}))
    apiClient.updateDiscussion(getState(), discussion, updatedFields)
      .then(() => {
        // Only need to make this API call if reordering the pinned discussions
        const promise = (discussionCopy.pinned && order !== undefined)
          ? apiClient.reorderPinnedDiscussions(getState(), order)
          : new Promise(resolve => resolve())

        promise
          .then(() => {
            dispatch(actions.dragAndDropSuccess())
          })
          .catch(err => {
            // container state has already been updated, so we are only reverting
            // the pinned order here. By default, if this is a discussion that
            // that just got moved to the pinned container, we will move it to
            // the bottom of the pinned discussions on error
            if (discussionCopy.pinned) { originalOrder.push(discussionCopy.id) }
            dispatch(actions.dragAndDropFail({
              message: I18n.t('Failed to update discussion'),
              discussion: discussionCopy,
              order: originalOrder,
              err,
            }))
          })
      })
      .catch(err => {
        // reset order and discussion back to original state
        dispatch(actions.dragAndDropFail({
          message: I18n.t('Failed to update discussion'),
          discussion,
          order: originalOrder,
          err,
        }))
      })
  }
}


actions.searchDiscussions = function searchDiscussions ({ searchTerm, filter }) {
  return (dispatch, getState) => {
    dispatch(actions.updateDiscussionsSearch({ searchTerm, filter }))
    const state = getState()
    const pinned = state.pinnedDiscussions
    const unpinned = state.unpinnedDiscussions
    const closed = state.closedForCommentsDiscussions
    const allDiscussions = pinned.concat(unpinned).concat(closed)
    const numDisplayed = allDiscussions.filter(d => !d.filtered).length
    $.screenReaderFlashMessageExclusive(I18n.t('%{count} discussions found.', { count: numDisplayed }))
  }
}

actions.deleteDiscussion = function(discussion) {
  return (dispatch, getState) => {
    const discussionCopy = copyAndUpdateDiscussion(discussion, {})
    dispatch(actions.deleteDiscussionStart())
    apiClient.deleteDiscussion(getState(), {discussion: discussionCopy})
      .then(_ => {
        dispatch(actions.deleteDiscussionSuccess({discussion: discussionCopy}))
        $.screenReaderFlashMessage(I18n.t('Successfully deleted discussion %{title}', { title: discussion.title }))
      })
      .catch(err => {
        $.screenReaderFlashMessage(I18n.t('Failed to delete discussion %{title}', { title: discussion.title }))
        dispatch(actions.deleteDiscussionFails({
          message: I18n.t('Failed to delete discussion %{title}', { title: discussion.title }),
          discussion,
          err
        }))
      })
  }
}


actions.fetchUserSettings = function() {
  return (dispatch, getState) => {
    dispatch(actions.getUserSettingsStart())
    apiClient.getUserSettings(getState())
      .then(resp => {
        dispatch(actions.getUserSettingsSuccess(resp.data))
      })
      .catch(err => {
        dispatch(actions.getUserSettingsFail({err}))
      })
  }
}

actions.fetchCourseSettings = function() {
  return (dispatch, getState) => {
    dispatch(actions.getCourseSettingsStart())
    apiClient.getCourseSettings(getState())
      .then(resp => {
        dispatch(actions.getCourseSettingsSuccess(resp.data))
      })
      .catch(err => {
        dispatch(actions.getCourseSettingsFail({err}))
      })
  }
}

function saveCourseSettings(dispatch, getState, userSettings, courseSettings) {
  apiClient.saveCourseSettings(getState(), courseSettings)
    .then(resp => {
      $.screenReaderFlashMessage(I18n.t('Saved discussion settings successfully'))
      dispatch(actions.savingSettingsSuccess({userSettings, courseSettings: resp.data}))
    })
    .catch(err => {
      $.screenReaderFlashMessage(I18n.t('Error saving discussion settings'))
      dispatch(actions.savingSettingsFail({err}))
    })
}

actions.saveSettings = function(userSettings, courseSettings) {
  return (dispatch, getState) => {
    dispatch(actions.savingSettingsStart())
    const userSettingsCopy = Object.assign(getState().userSettings, {})
    userSettingsCopy.manual_mark_as_read = userSettings.markAsRead
    apiClient.saveUserSettings(getState(), userSettingsCopy)
      .then(resp => {
        if(courseSettings) {
          saveCourseSettings(dispatch, getState, resp.data, courseSettings)
        } else {
          $.screenReaderFlashMessage(I18n.t('Saved discussion settings successfully'))
          dispatch(actions.savingSettingsSuccess({userSettings: resp.data}))
        }
      })
      .catch(err => {
        $.screenReaderFlashMessage(I18n.t('Error saving discussion settings'))
        dispatch(actions.savingSettingsFail({err}))
      })
  }
}

actions.duplicateDiscussion = function(discussionId) {
  return (dispatch, getState) => {
    // This is a no-op, just here to maintain a pattern
    dispatch(actions.duplicateDiscussionStart())
    apiClient.duplicateDiscussion(getState(), discussionId).then(response => {
      const successMessage = I18n.t('Duplication of %{title} succeeded', { title: response.data.title })
      $.screenReaderFlashMessageExclusive(successMessage)
      dispatch(actions.duplicateDiscussionSuccess({ newDiscussion: response.data, originalId: discussionId }))
    }).catch(err => {
      const failMessage = I18n.t('Duplication failed')
      $.screenReaderFlashMessageExclusive(failMessage)
      dispatch(actions.duplicateDiscussionFail({
        message: failMessage,
        err
      }))
    })
  }
}

// This is a different action then the update discussion because it hits an
// entirely different endpoint on the backend.
actions.toggleSubscriptionState = function(discussion) {
  return (dispatch, getState) => {
    if (discussion.subscription_hold === undefined) {
      dispatch(actions.toggleSubscribeStart())
      const toggleFunc = discussion.subscribed ? apiClient.unsubscribeFromTopic : apiClient.subscribeToTopic

      toggleFunc(getState(), discussion)
        .then(_ => {
          const params = { id: discussion.id, subscribed: !discussion.subscribed }
          dispatch(actions.toggleSubscribeSuccess(params))
        })
        .catch(err => {
          const failMessage = discussion.subscribed ? I18n.t('Unsubscribed failed') : I18n.t('Subscribe failed')
          $.screenReaderFlashMessageExclusive(failMessage)
          dispatch(actions.toggleSubscribeFail({
            message: failMessage,
            err
          }))
        })
    }
  }
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
