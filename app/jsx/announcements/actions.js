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
import isEqual from 'lodash/isEqual'
import range from 'lodash/range'
import $ from 'jquery'
import 'compiled/jquery.rails_flash_notifications'

import * as apiClient from './apiClient'
import { createPaginationActions } from '../shared/reduxPagination'
import { notificationActions } from '../shared/reduxNotifications'

function fetchAnnouncements(dispatch, getState, payload) {
  return (resolve, reject) => {
    apiClient.getAnnouncements(getState(), payload)
      .then(res => {
        $.screenReaderFlashMessage(I18n.t('%{count} announcements found.', { count: res.data.length }))
        resolve(res)
      })
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading announcements') }))
  }
}
const announcementActions = createPaginationActions('announcements', fetchAnnouncements)

const types = [
  ...announcementActions.actionTypes,
  'UPDATE_ANNOUNCEMENTS_SEARCH',
  'SET_ANNOUNCEMENT_SELECTION',
  'CLEAR_ANNOUNCEMENT_SELECTIONS',
  'LOCK_ANNOUNCEMENTS_START',
  'LOCK_ANNOUNCEMENTS_SUCCESS',
  'LOCK_ANNOUNCEMENTS_FAIL',
  'DELETE_ANNOUNCEMENTS_START',
  'DELETE_ANNOUNCEMENTS_SUCCESS',
  'DELETE_ANNOUNCEMENTS_FAIL',
]
const actions = Object.assign(
  createActions(...types),
  announcementActions.actionCreators,
)

actions.searchAnnouncements = function searchAnnouncements (searchOpts) {
  return (dispatch, getState) => {
    const oldSearch = getState().announcementsSearch
    dispatch(actions.updateAnnouncementsSearch(searchOpts))
    const state = getState()
    const newSearch = state.announcementsSearch

    if (!isEqual(oldSearch, newSearch)) {
      // uncache pages if we change the search query
      dispatch(actions.clearAnnouncementsPage({ pages: range(1, state.announcements.lastPage + 1) }))
      dispatch(actions.getAnnouncements({ page: 1, select: true }))
    }
  }
}

actions.lockAnnouncements = () => (dispatch, getState) => {
  const state = getState()
  const { announcements } = state
  const { items } = announcements.pages[announcements.currentPage]

  const selectedItems = items.filter(item =>
    state.selectedAnnouncements.includes(item.id))

  // if all the selected items are locked, we want to unlock
  // if any of the selected items are unlocked, we lock everything
  const hasUnlockedItems = selectedItems
    .reduce((hasAnyUnlocked, item) => hasAnyUnlocked || !item.locked, false)

  dispatch(actions.lockAnnouncementsStart())
  apiClient.lockAnnouncements(state, state.selectedAnnouncements, hasUnlockedItems)
    .then(res => {
      if (res.successes.length) {
        dispatch(actions.lockAnnouncementsSuccess({ res, locked: hasUnlockedItems }))
        if (hasUnlockedItems) {
          dispatch(notificationActions.notifyInfo({ message: I18n.t('Announcements locked successfully') }))
        } else {
          dispatch(notificationActions.notifyInfo({ message: I18n.t('Announcements unlocked successfully') }))
        }
      } else if (res.failures.length) {
        dispatch(actions.lockAnnouncementsFail({
          err: res.failures,
          message: I18n.t('An error occurred while updating announcements locked state.'),
        }))
      }
    })
    .catch(err => {
      dispatch(actions.lockAnnouncementsFail({ err, message: I18n.t('An error occurred while locking announcements.') }))
    })
}

actions.deleteAnnouncements = () => (dispatch, getState) => {
  const state = getState()
  dispatch(actions.deleteAnnouncementsStart())
  apiClient.deleteAnnouncements(state, state.selectedAnnouncements)
    .then(res => {
      if (res.successes.length) {
        const pageState = getState().announcements
        dispatch(actions.deleteAnnouncementsSuccess(res))

        // uncache all pages after this page, as they are no longer correct once you delete items
        dispatch(actions.clearAnnouncementsPage({ pages: range(pageState.currentPage, pageState.lastPage + 1) }))

        dispatch(notificationActions.notifyInfo({ message: I18n.t('Announcements deleted successfully') }))

        // reload current page after deleting items
        dispatch(actions.getAnnouncements({ page: pageState.currentPage, select: true }))
      } else if (res.failures.length) {
        dispatch(actions.deleteAnnouncementsFail({
          err: res.failures,
          message: I18n.t('An error occurred while deleting announcements.'),
        }))
      }
    })
    .catch(err => {
      dispatch(actions.deleteAnnouncementsFail({
        err,
        message: I18n.t('An error occurred while deleting announcements.'),
      }))
    })
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
