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

import {createActions} from 'redux-actions'
import axios from 'axios'
import {togglePlannerItemCompletion} from '.'
import {transformApiToInternalItem, findNextLink} from '../utilities/apiUtils'
import {identifiableThunk} from '../utilities/redux-identifiable-thunk'

export const {
  sidebarItemsLoading,
  sidebarItemsLoaded,
  sidebarItemsLoadingFailed,
  sidebarEnoughItemsLoaded
} = createActions(
  'SIDEBAR_ITEMS_LOADING',
  'SIDEBAR_ITEMS_LOADED',
  'SIDEBAR_ITEMS_LOADING_FAILED',
  'SIDEBAR_ENOUGH_ITEMS_LOADED'
)

export const ENOUGH_ITEMS_TO_SHOW_LIST = 7
export const DESIRED_ITEMS_TO_HAVE_LOADED = 14

function incompleteItems(state) {
  return state.sidebar.items.filter(item => !item.completed)
}

function enoughSidebarItemsAreLoaded(state) {
  return incompleteItems(state).length >= ENOUGH_ITEMS_TO_SHOW_LIST
}

function desiredSidebarItemsAreLoaded(state) {
  return incompleteItems(state).length >= DESIRED_ITEMS_TO_HAVE_LOADED
}

function handleSidebarLoadingResponse(response, dispatch, getState) {
  const nextUrl = findNextLink(response)
  const transformedItems = response.data.map(item =>
    transformApiToInternalItem(item, getState().courses, getState().groups, getState().timeZone)
  )
  dispatch(sidebarItemsLoaded({items: transformedItems, nextUrl}))
  if (!nextUrl || enoughSidebarItemsAreLoaded(getState())) {
    dispatch(sidebarEnoughItemsLoaded())
  }
  if (nextUrl && !desiredSidebarItemsAreLoaded(getState())) {
    return dispatch(sidebarLoadNextItems())
  }
}

export const sidebarLoadNextItems = identifiableThunk(() => (dispatch, getState) => {
  if (!getState().sidebar.loading && getState().sidebar.nextUrl) {
    dispatch(sidebarItemsLoading())
    const params = {
      order: 'asc'
    }
    if (getState().sidebar.course_id) {
      params.context_codes = [
        `course_${getState().sidebar.course_id}`,
        `user_${ENV.current_user_id}`
      ]
    }
    return axios
      .get(getState().sidebar.nextUrl, {params})
      .then(response => {
        return handleSidebarLoadingResponse(response, dispatch, getState)
      })
      .catch(response => dispatch(sidebarItemsLoadingFailed(response)))
  }
})

export const sidebarLoadInitialItems = (currentMoment, course_id) => (dispatch, getState) => {
  const firstMomentDate = currentMoment.clone().subtract(2, 'weeks')
  dispatch(sidebarItemsLoading({firstMoment: firstMomentDate, course_id}))
  const params = {
    start_date: firstMomentDate.toISOString(),
    order: 'asc'
  }
  if (course_id) {
    params.context_codes = [`course_${course_id}`, `user_${ENV.current_user_id}`]
  }
  return axios
    .get('/api/v1/planner/items', {params})
    .then(response => {
      return handleSidebarLoadingResponse(response, dispatch, getState)
    })
    .catch(response => dispatch(sidebarItemsLoadingFailed(response)))
}

export const sidebarCompleteItem = item => {
  return togglePlannerItemCompletion(item)
}

export const maybeUpdateTodoSidebar = identifiableThunk(
  updateItemPromise => (dispatch, getState) => {
    if (getState().sidebar.nextUrl == null) {
      return updateItemPromise
    }
    return updateItemPromise.then(payload => {
      if (!desiredSidebarItemsAreLoaded(getState())) {
        dispatch(sidebarLoadNextItems())
      }
      return payload
    })
  }
)
