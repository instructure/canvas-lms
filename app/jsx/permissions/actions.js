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

import I18n from 'i18n!announcements_v2'

import $ from 'jquery'
import * as apiClient from './apiClient'
// We probably will want these eventually
// import { notificationActions } from '../shared/reduxNotifications'

const actionTypes = {
  GET_PERMISSIONS_START: 'GET_PERMISSIONS_START',
  GET_PERMISSIONS_SUCCESS: 'GET_PERMISSIONS_SUCCESS'
}

const actions = {}

actions.getPermissionsStart = function(contextId) {
  return {
    type: actionTypes.GET_PERMISSIONS_START,
    payload: contextId
  }
}

actions.getPermissionsSuccess = function(response) {
  return {
    type: actionTypes.GET_PERMISSIONS_SUCCESS,
    payload: response
  }
}

actions.getPermissions = function(contextId) {
  return dispatch => {
    dispatch(actions.getPermissionsStart(contextId))
    apiClient.getPermissions(contextId)
      .then(response => {
        dispatch(actions.getPermissionsSuccess(response.data))
      })
      .catch(_response => {
        $.screenReaderFlashMessageExclusive(I18n.t('Loading permissions failed'))
      })
  }
}

export { actionTypes, actions as default }
