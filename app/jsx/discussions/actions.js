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

function fetchDiscussions(dispatch, getState, payload) {
  return (resolve, reject) => {
    apiClient.getDiscussions(getState(), payload)
      .then(resolve)
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading discussions') }))
  }
}
const discussionActions = createPaginationActions('discussions', fetchDiscussions)

const types = [
  ...discussionActions.actionTypes,
  'TOGGLE_SUBSCRIBE_START',
  'TOGGLE_SUBSCRIBE_SUCCESS',
  'TOGGLE_SUBSCRIBE_FAIL',
  'UPDATE_DISCUSSION_START',
  'UPDATE_DISCUSSION_SUCCESS',
  'UPDATE_DISCUSSION_FAIL',
]
const actions = Object.assign(
  createActions(...types),
  discussionActions.actionCreators,
)

function copyAndUpdateDiscussion(discussion, updatedFields) {
  const discussionCopy = Object.assign({}, discussion);
  Object.keys(updatedFields).forEach(key => {
    if (!Object.prototype.hasOwnProperty.call(discussion, key)) {
      throw new Error(`field ${key} does not exist in the discussion`)
    }
    discussionCopy[key] = updatedFields[key]
  })
  return discussionCopy
}

const defaultFailMessage = I18n.t('Updating discussion failed')

// We are assuming success here (mostly for the sake of drag and drop, where
// it would look really awkward to drop it, have it snap back to the original
// position, and then snap to the new position shortly after).
actions.updateDiscussion = function(discussion, updatedFields, { successMessage, failMessage }) {
  return (dispatch, getState) => {
    const discussionCopy = copyAndUpdateDiscussion(discussion, updatedFields)
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
