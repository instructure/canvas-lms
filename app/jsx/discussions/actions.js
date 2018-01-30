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

import { getDiscussions } from './apiClient'
import { notificationActions } from '../shared/reduxNotifications'
import { createPaginationActions } from '../shared/reduxPagination'

function fetchDiscussions(dispatch, getState, payload) {
  return (resolve, reject) => {
    getDiscussions(getState(), payload)
      .then((res) => {
        resolve(res)
        dispatch(notificationActions.notifyInfo(I18n.t('Discussions Loaded!'))) // dummy notification, remove me later
      })
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading discussions') }))
  }
}
const discussionActions = createPaginationActions('discussions', fetchDiscussions)

const types = [
  ...discussionActions.actionTypes,
]
const actions = Object.assign(
  createActions(...types),
  discussionActions.actionCreators,
)

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
