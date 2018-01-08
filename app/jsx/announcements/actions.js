/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import { createActions } from 'redux-actions'

import { getAnnouncements } from './apiClient'
import { createPaginationActions } from '../shared/reduxPagination'

function fetchAnnouncements(dispatch, getState, payload) {
  return (resolve, reject) => {
    getAnnouncements(getState(), payload)
      .then(resolve)
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading announcements') }))
  }
}
const announcementActions = createPaginationActions('announcements', fetchAnnouncements)

const types = [
  ...announcementActions.actionTypes,
  'UPDATE_ANNOUNCEMENTS_SEARCH',
]
const actions = Object.assign(
  createActions(...types),
  announcementActions.actionCreators,
)

actions.searchAnnouncements = function searchAnnouncements (searchOpts) {
  return (dispatch, getState) => {
    const oldTerm = getState().announcementsSearch.term
    const oldFilter = getState().announcementsSearch.filter
    dispatch(actions.updateAnnouncementsSearch(searchOpts))
    const newTerm = getState().announcementsSearch.term
    const newFilter = getState().announcementsSearch.filter
    if (oldTerm !== newTerm || oldFilter !== newFilter) {
      dispatch(actions.getAnnouncements({ page: 1, select: true, forceGet: true }))
    }
  }
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
