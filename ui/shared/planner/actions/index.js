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
import {createActions, createAction} from 'redux-actions'
import axios from 'axios'
import {asAxios, getPrefetchedXHR} from '@canvas/util/xhr'
import parseLinkHeader from '@canvas/parse-link-header'
import configureAxios from '../utilities/configureAxios'
import {alert} from '../utilities/alertUtils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {maybeUpdateTodoSidebar} from './sidebar-actions'
import {
  getPlannerItems,
  getWeeklyPlannerItems,
  clearLoading,
  startLoadingGradesSaga,
} from './loading-actions'
import {
  transformInternalToApiItem,
  transformInternalToApiOverride,
  transformPlannerNoteApiToInternalItem,
  getResponseHeader,
  buildURL,
} from '../utilities/apiUtils'

const I18n = useI18nScope('planner')

configureAxios(axios)

export const {
  initialOptions,
  addOpportunities,
  startLoadingOpportunities,
  startLoadingAllOpportunities,
  startDismissingOpportunity,
  allOpportunitiesLoaded,
  savingPlannerItem,
  savedPlannerItem,
  dismissedOpportunity,
  deletingPlannerItem,
  deletedPlannerItem,
  updateTodo,
  clearUpdateTodo,
  openEditingPlannerItem,
  setNaiAboveScreen,
  setGradesTrayState,
  scrollToNewActivity,
  scrollToToday,
  toggleMissingItems,
  selectedObservee,
  clearWeeklyItems,
  clearOpportunities,
  clearDays,
  clearCourses,
  clearSidebar,
} = createActions(
  'INITIAL_OPTIONS',
  'ADD_OPPORTUNITIES',
  'START_LOADING_OPPORTUNITIES',
  'START_LOADING_ALL_OPPORTUNITIES',
  'START_DISMISSING_OPPORTUNITY',
  'ALL_OPPORTUNITIES_LOADED',
  'SAVING_PLANNER_ITEM',
  'SAVED_PLANNER_ITEM',
  'DISMISSED_OPPORTUNITY',
  'DELETING_PLANNER_ITEM',
  'DELETED_PLANNER_ITEM',
  'UPDATE_TODO',
  'CLEAR_UPDATE_TODO',
  'OPEN_EDITING_PLANNER_ITEM',
  'SET_NAI_ABOVE_SCREEN',
  'SET_GRADES_TRAY_STATE',
  'SCROLL_TO_NEW_ACTIVITY',
  'SCROLL_TO_TODAY',
  'TOGGLE_MISSING_ITEMS',
  'SELECTED_OBSERVEE',
  'CLEAR_WEEKLY_ITEMS',
  'CLEAR_OPPORTUNITIES',
  'CLEAR_DAYS',
  'CLEAR_COURSES',
  'CLEAR_SIDEBAR'
)

export * from './loading-actions'
export * from './sidebar-actions'

function saveExistingPlannerItem(apiItem) {
  return axios({
    method: 'put',
    url: `/api/v1/planner_notes/${apiItem.id}`,
    data: apiItem,
  })
}

function saveNewPlannerItem(apiItem) {
  return axios({
    method: 'post',
    url: '/api/v1/planner_notes',
    data: apiItem,
  })
}

export const getNextOpportunities = () => {
  return (dispatch, getState) => {
    dispatch(startLoadingOpportunities())
    if (getState().opportunities.nextUrl) {
      axios({
        method: 'get',
        url: getState().opportunities.nextUrl,
      })
        .then(response => {
          if (parseLinkHeader(getResponseHeader(response, 'link')).next) {
            dispatch(
              addOpportunities({
                items: response.data,
                nextUrl: parseLinkHeader(getResponseHeader(response, 'link')).next.url,
              })
            )
          } else {
            dispatch(addOpportunities({items: response.data, nextUrl: null}))
          }
        })
        .catch(_ex => {
          alert(I18n.t('Failed to load opportunities'), true)
        })
    } else {
      dispatch(allOpportunitiesLoaded())
    }
  }
}

export const getInitialOpportunities = () => {
  return (dispatch, getState) => {
    dispatch(startLoadingOpportunities())

    // eslint-disable-next-line @typescript-eslint/no-shadow
    const {courses, selectedObservee} = getState()
    const url =
      getState().opportunities.nextUrl ||
      buildURL('/api/v1/users/self/missing_submissions', {
        include: ['planner_overrides'],
        filter: ['submittable', 'current_grading_period'],
        observed_user_id: selectedObservee,
        course_ids: selectedObservee
          ? courses.map(c => c.id).sort((a, b) => a.localeCompare(b, 'en', {numeric: true}))
          : undefined,
      })
    const request = asAxios(getPrefetchedXHR(url)) || axios({method: 'get', url})

    request
      .then(response => {
        const next = parseLinkHeader(getResponseHeader(response, 'link')).next
        dispatch(addOpportunities({items: response.data, nextUrl: next ? next.url : null}))
      })
      .catch(_ex => {
        alert(I18n.t('Failed to load opportunities'), true)
      })
  }
}

export const dismissOpportunity = (id, plannerOverride) => {
  return dispatch => {
    dispatch(startDismissingOpportunity(id))
    const apiOverride = {...plannerOverride}
    apiOverride.dismissed = true
    apiOverride.plannable_id = id
    apiOverride.plannable_type = 'assignment'
    let promise = apiOverride.id
      ? saveExistingPlannerOverride(apiOverride)
      : saveNewPlannerOverride(apiOverride)
    promise = promise
      .then(response => {
        dispatch(dismissedOpportunity(response.data))
      })
      .catch(() => {
        alert(I18n.t('An error occurred attempting to dismiss the opportunity.'), true)
      })
    return promise
  }
}

export const savePlannerItem = plannerItem => {
  return (dispatch, getState) => {
    const isNewItem = !plannerItem.id
    const overrideData = getOverrideDataOnItem(plannerItem)
    dispatch(savingPlannerItem({item: plannerItem, isNewItem}))
    let apiItem = transformInternalToApiItem(plannerItem)
    let promise = isNewItem ? saveNewPlannerItem(apiItem) : saveExistingPlannerItem(apiItem)
    promise = promise
      .then(response => {
        apiItem = transformPlannerNoteApiToInternalItem(
          response.data,
          getState().courses,
          getState().timeZone
        )
        return {
          item: updateOverrideDataOnItem(apiItem, overrideData),
          isNewItem,
        }
      })
      .catch(() => alert(I18n.t('Failed to save to do'), true))
    dispatch(clearUpdateTodo())
    dispatch(savedPlannerItem(promise))
    return promise
  }
}

export const deletePlannerItem = plannerItem => {
  return (dispatch, getState) => {
    dispatch(deletingPlannerItem(plannerItem))
    const promise = axios({
      method: 'delete',
      url: `/api/v1/planner_notes/${plannerItem.id}`,
    })
      .then(response =>
        transformPlannerNoteApiToInternalItem(
          response.data,
          getState().courses,
          getState().timeZone
        )
      )
      .catch(() => alert(I18n.t('Failed to delete to do'), true))
    dispatch(clearUpdateTodo())
    dispatch(deletedPlannerItem(promise))
    dispatch(maybeUpdateTodoSidebar(promise))
    return promise
  }
}

export const canceledEditingPlannerItem = createAction('CANCELED_EDITING_PLANNER_ITEM')

export const cancelEditingPlannerItem = () => {
  return dispatch => {
    dispatch(clearUpdateTodo())
    dispatch(canceledEditingPlannerItem())
  }
}

function saveExistingPlannerOverride(apiOverride) {
  return axios({
    method: 'put',
    url: `/api/v1/planner/overrides/${apiOverride.id}`,
    data: apiOverride,
  })
}

function saveNewPlannerOverride(apiOverride) {
  return axios({
    method: 'post',
    url: '/api/v1/planner/overrides',
    data: apiOverride,
  })
}

export const togglePlannerItemCompletion = plannerItem => {
  return (dispatch, getState) => {
    const savingItem = {...plannerItem, toggleAPIPending: true, show: true}
    dispatch(savingPlannerItem({item: savingItem, isNewItem: false, wasToggled: true}))
    const apiOverride = transformInternalToApiOverride(plannerItem, getState().currentUser.id)
    apiOverride.marked_complete = !apiOverride.marked_complete
    let promise = apiOverride.id
      ? saveExistingPlannerOverride(apiOverride)
      : saveNewPlannerOverride(apiOverride)
    promise = promise
      .then(response => ({
        item: updateOverrideDataOnItem(plannerItem, response.data),
        isNewItem: false,
        wasToggled: true,
      }))
      .catch(() => {
        alert(I18n.t('Unable to mark as complete.'), true)
        return {
          item: plannerItem,
          isNewItem: false,
          wasToggled: true,
        }
      })
    dispatch(savedPlannerItem(promise))
    dispatch(maybeUpdateTodoSidebar(promise))
    return promise
  }
}

export const sidebarCompleteItem = item => {
  return togglePlannerItemCompletion(item)
}

function updateOverrideDataOnItem(plannerItem, apiOverride) {
  const updatedItem = {...plannerItem}
  updatedItem.overrideId = apiOverride.id
  updatedItem.completed = apiOverride.marked_complete
  updatedItem.show = true
  return updatedItem
}

function getOverrideDataOnItem(plannerItem) {
  return {
    id: plannerItem.overrideId,
    marked_complete: plannerItem.completed,
  }
}

export const clearItems = () => {
  return (dispatch, getState) => {
    if (getState().weeklyDashboard) {
      dispatch(clearWeeklyItems())
    }
    dispatch(clearCourses(getState().singleCourse))
    dispatch(clearOpportunities())
    dispatch(clearDays())
    dispatch(clearSidebar())
    dispatch(clearLoading())
  }
}

export const reloadWithObservee = observeeId => {
  return (dispatch, getState) => {
    if (getState().selectedObservee !== observeeId) {
      dispatch(selectedObservee(observeeId))
      dispatch(clearItems())
      if (getState().weeklyDashboard) {
        return dispatch(getWeeklyPlannerItems(getState().today)).then(() => {
          dispatch(startLoadingAllOpportunities())
        })
      } else {
        return dispatch(getPlannerItems(getState().today)).then(() => {
          dispatch(startLoadingAllOpportunities())
          if (getState().ui.gradesTrayOpen) {
            dispatch(startLoadingGradesSaga(observeeId))
          }
        })
      }
    }
  }
}
