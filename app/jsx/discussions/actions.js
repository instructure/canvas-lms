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

import { getDiscussions, updateDiscussion } from './apiClient'
import { createPaginationActions } from '../shared/reduxPagination'

function fetchDiscussions(dispatch, getState, payload) {
  return (resolve, reject) => {
    getDiscussions(getState(), payload)
      .then(resolve)
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading discussions') }))
  }
}
const discussionActions = createPaginationActions('discussions', fetchDiscussions)

const types = [
  ...discussionActions.actionTypes,
  'TOGGLE_PIN_START',
  'TOGGLE_PIN_SUCCESS',
  'TOGGLE_PIN_FAIL',
  'CLOSE_FOR_COMMENTS_START',
  'CLOSE_FOR_COMMENTS_SUCCESS',
  'CLOSE_FOR_COMMENTS_FAIL',
]
const actions = Object.assign(
  createActions(...types),
  discussionActions.actionCreators,
)

actions.togglePin = function ({pinnedState, discussion, closedState}) {
  return (dispatch, getState) => {
    if( pinnedState !== discussion.pinned || discussion.locked !== closedState) {
      const discussionCopy = Object.assign({}, discussion);
      discussionCopy.pinned = pinnedState
      discussionCopy.locked = false
      dispatch(actions.togglePinStart({discussion: discussionCopy, pinnedState, closedState}))
      updateDiscussion(getState(), discussion, pinnedState, closedState)
        .then(_ => {
          dispatch(actions.togglePinSuccess())
            const successMessage = pinnedState ? I18n.t('Discussion pinned successfully') : I18n.t('Discussion unpinned successfully')
            $.screenReaderFlashMessage(successMessage)
        })
        .catch((err) => {
          const failMessage = pinnedState ? I18n.t('Failed to pin discussion') : I18n.t('Failed to unpin discussion')
          $.screenReaderFlashMessage(failMessage)
          dispatch(actions.togglePinFail({
            discussion,
            closedState,
            pinnedState,
            message: failMessage,
            err
          }))
        })
    }
  }
}

actions.closeForComments = function ({closedState, discussion, pinnedState}) {
  return (dispatch, getState) => {
    if( closedState !== discussion.locked) {
      const discussionCopy = Object.assign({}, discussion);
      discussionCopy.pinned = pinnedState
      discussionCopy.locked = closedState
      dispatch(actions.closeForCommentsStart({discussion: discussionCopy, closedState, pinnedState}))
      updateDiscussion(getState(), discussion, pinnedState, closedState)
        .then(_ => {
          dispatch(actions.closeForCommentsSuccess())
          const successMessage = I18n.t('Discussion closed for comments successfully')
          $.screenReaderFlashMessage(successMessage)
        })
        .catch((err) => {
          const failMessage = I18n.t('Failed to close discussion for comments')
          $.screenReaderFlashMessage(failMessage)
          dispatch(actions.closeForCommentsFail({
            discussion,
            closedState,
            pinnedState,
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
