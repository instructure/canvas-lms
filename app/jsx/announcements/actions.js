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
        $.screenReaderFlashMessageExclusive(I18n.t('%{count} announcements found.', { count: res.data.length }))
        resolve(res)
      })
      .catch(err => reject({ err, message: I18n.t('An error ocurred while loading announcements') }))
  }
}
const announcementActions = createPaginationActions('announcements', fetchAnnouncements)

const types = [
  ...announcementActions.actionTypes,
  'UPDATE_ANNOUNCEMENTS_SEARCH',
  'ADD_EXTERNAL_FEED_START',
  'ADD_EXTERNAL_FEED_SUCCESS',
  'ADD_EXTERNAL_FEED_FAIL',
  'DELETE_EXTERNAL_FEED_START',
  'DELETE_EXTERNAL_FEED_SUCCESS',
  'DELETE_EXTERNAL_FEED_FAIL',
  'LOADING_EXTERNAL_FEED_START',
  'LOADING_EXTERNAL_FEED_SUCCESS',
  'LOADING_EXTERNAL_FEED_FAIL',
  'SET_ANNOUNCEMENT_SELECTION',
  'CLEAR_ANNOUNCEMENT_SELECTIONS',
  'LOCK_ANNOUNCEMENTS_START',
  'LOCK_ANNOUNCEMENTS_SUCCESS',
  'LOCK_ANNOUNCEMENTS_FAIL',
  'DELETE_ANNOUNCEMENTS_START',
  'DELETE_ANNOUNCEMENTS_SUCCESS',
  'DELETE_ANNOUNCEMENTS_FAIL',
  'SET_ANNOUNCEMENTS_IS_LOCKING'
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

actions.getExternalFeeds = function () {
  return (dispatch, getState) => {
    dispatch(actions.loadingExternalFeedStart())
    apiClient.getExternalFeeds(getState())
      .then(resp => {
        dispatch(actions.loadingExternalFeedSuccess({ feeds: resp.data }))
      }).catch((err) => {
        dispatch(actions.loadingExternalFeedFail({
          message: I18n.t('Failed to Load External Feeds'),
          err
        }))
      })
  }
}

actions.deleteExternalFeed = function ({ feedId }) {
  return (dispatch, getState) => {
    if(!getState().externalRssFeed.isDeleting) {
      dispatch(actions.deleteExternalFeedStart())
      apiClient.deleteExternalFeed(getState(), feedId)
        .then(() => {
          dispatch(actions.deleteExternalFeedSuccess({ feedId }))
          const successMessage = I18n.t('External Feed deleted successfully')
          $.screenReaderFlashMessage(successMessage)
          dispatch(notificationActions.notifyInfo({ message: successMessage }))
        })
        .catch((err) => {
          const failMessage = I18n.t('Failed to delete external feed')
          $.screenReaderFlashMessage(failMessage)
          dispatch(actions.deleteExternalFeedFail({
            message: failMessage,
            err
          }))
        })
    }
  }
}

actions.toggleAnnouncementsLock = (announcements, isLocking = true) => (dispatch, getState) => {
  dispatch(actions.lockAnnouncementsStart())
  apiClient.lockAnnouncements(getState(), [].concat(announcements), isLocking)
    .then(res => {
      if (res.successes.length) {
        dispatch(actions.lockAnnouncementsSuccess({ res, locked: isLocking }))
        if (isLocking) {
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

actions.announcementSelectionChangeStart = ({ selected , id }) => (dispatch, getState) => {
  dispatch(actions.setAnnouncementSelection({ selected , id }))
  const state = getState()
  const { announcements } = state
  const { items } = announcements.pages[announcements.currentPage]

  const selectedItems = items.filter(item =>
    state.selectedAnnouncements.includes(item.id))

  // if all the selected items are locked, we want to unlock
  // if any of the selected items are unlocked, we lock everything
  const hasUnlockedItems = selectedItems
    .reduce((hasAnyUnlocked, item) => hasAnyUnlocked || !item.locked, false)

  dispatch(actions.setAnnouncementsIsLocking(hasUnlockedItems))
}

actions.toggleSelectedAnnouncementsLock = () => (dispatch, getState) => {
  const state = getState()
  const { announcements } = state
  const { items } = announcements.pages[announcements.currentPage]

  const selectedItems = items.filter(item =>
    state.selectedAnnouncements.includes(item.id))

  // if all the selected items are locked, we want to unlock
  // if any of the selected items are unlocked, we lock everything
  const hasUnlockedItems = selectedItems
    .reduce((hasAnyUnlocked, item) => hasAnyUnlocked || !item.locked, false)

  actions.toggleAnnouncementsLock(state.selectedAnnouncements, hasUnlockedItems)(dispatch, getState)
  dispatch(actions.setAnnouncementsIsLocking(!hasUnlockedItems)) // isLocking
}

actions.deleteAnnouncements = (announcements) => (dispatch, getState) => {
  dispatch(actions.deleteAnnouncementsStart())
  apiClient.deleteAnnouncements(getState(), [].concat(announcements))
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

actions.deleteSelectedAnnouncements = () => (dispatch, getState) => {
  const state = getState()
  actions.deleteAnnouncements(state.selectedAnnouncements)(dispatch, getState)
}

actions.addExternalFeed = function (payload) {
  return (dispatch, getState) => {
    dispatch(actions.addExternalFeedStart())
    apiClient.addExternalFeed(getState(), payload)
      .then(resp => {
        dispatch(actions.addExternalFeedSuccess({ feed: resp.data}))
        const successMessage = I18n.t('External feed successfully added')
        $.screenReaderFlashMessage(successMessage)
        dispatch(notificationActions.notifyInfo({ message: successMessage }))
      })
      .catch((err) => {
        const failMessage = I18n.t('Failed to add new feed')
        $.screenReaderFlashMessage(failMessage)
        dispatch(actions.addExternalFeedFail({
          message: failMessage,
          err
        }))
      })
  }
}

const actionTypes = types.reduce((typesMap, actionType) =>
  Object.assign(typesMap, { [actionType]: actionType }), {})

export { actionTypes, actions as default }
