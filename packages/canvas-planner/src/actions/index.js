/*
 * Copyright (C) 2017 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that they will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
import { createActions, createAction } from 'redux-actions';
import axios from 'axios';
import configureAxios from '../utilities/configureAxios';
import { alert } from '../utilities/alertUtils';
import formatMessage from '../format-message';
import parseLinkHeader from 'parse-link-header';
import { makeEndOfDayIfMidnight } from '../utilities/dateUtils';
import { maybeUpdateTodoSidebar } from './sidebar-actions';

import {
  transformInternalToApiItem,
  transformInternalToApiOverride,
  transformPlannerNoteApiToInternalItem
} from '../utilities/apiUtils';

configureAxios(axios);

export const {
  initialOptions,
  addOpportunities,
  startLoadingOpportunities,
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
  scrollToNewActivity,
  scrollToToday,
} = createActions(
  'INITIAL_OPTIONS',
  'ADD_OPPORTUNITIES',
  'START_LOADING_OPPORTUNITIES',
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
  'SCROLL_TO_NEW_ACTIVITY',
  'SCROLL_TO_TODAY',
);

export * from './loading-actions';
export * from './sidebar-actions';

function saveExistingPlannerItem (apiItem) {
  return axios({
    method: 'put',
    url: `api/v1/planner_notes/${apiItem.id}`,
    data: apiItem,
  });
}

function saveNewPlannerItem (apiItem) {
  return axios({
    method: 'post',
    url: 'api/v1/planner_notes',
    data: apiItem,
  });
}

export const getNextOpportunities = () => {
  return (dispatch, getState) => {
    dispatch(startLoadingOpportunities());
    if(getState().opportunities.nextUrl) {
      axios({
        method: 'get',
        url: getState().opportunities.nextUrl,
      }).then(response => {
        if(parseLinkHeader(response.headers.link).next) {
          dispatch(addOpportunities({items: response.data, nextUrl: parseLinkHeader(response.headers.link).next.url }));
        }else {
          dispatch(addOpportunities({items: response.data, nextUrl: null}));
        }
      }).catch(() => alert(formatMessage('Failed to load opportunities'), true));
    } else {
      dispatch(allOpportunitiesLoaded());
    }
  };
};

export const getInitialOpportunities = () => {
  return (dispatch, getState) => {
    dispatch(startLoadingOpportunities());

    axios({
      method: 'get',
      url: getState().opportunities.nextUrl || '/api/v1/users/self/missing_submissions?include[]=planner_overrides&filter[]=submittable',
    }).then(response => {
      if(parseLinkHeader(response.headers.link).next) {
        dispatch(addOpportunities({items: response.data, nextUrl: parseLinkHeader(response.headers.link).next.url }));
      }else {
        dispatch(addOpportunities({items: response.data, nextUrl: null}));
      }
    }).catch(() => alert(formatMessage('Failed to load opportunities'), true));
  };
};

export const dismissOpportunity = (id, plannerOverride) => {
  return (dispatch, getState) => {
    dispatch(startDismissingOpportunity(id));
    const apiOverride = Object.assign({}, plannerOverride);
    apiOverride.dismissed = true;
    apiOverride.plannable_id = id;
    apiOverride.plannable_type = 'assignment';
    let promise = apiOverride.id ?
      saveExistingPlannerOverride(apiOverride) :
      saveNewPlannerOverride(apiOverride);
    promise = promise.then(response => {
      dispatch(dismissedOpportunity(response.data));

      // TODO: When splitting into dismissed not dismissed tabs this needs to change
      if(!getState().loading.allOpportunitiesLoaded && !getState().loading.loadingOpportunities && getState().opportunities.items.filter((opp) => {
        return opp.planner_override && !opp.planner_override.dismissed;
      }).length < 10)
        dispatch(getNextOpportunities());
    })
    .catch((error) => {
      alert(formatMessage('An error occurred attempting to dismiss the opportunity.'), true);
    });
    return promise;
  };
};

export const savePlannerItem = (plannerItem) => {
  return (dispatch, getState) => {
    plannerItem.date = makeEndOfDayIfMidnight(plannerItem.date, getState().timeZone);
    plannerItem.date = plannerItem.date.toISOString();

    const isNewItem = !plannerItem.id;
    const overrideData = getOverrideDataOnItem(plannerItem);
    dispatch(savingPlannerItem({item: plannerItem, isNewItem}));
    const apiItem = transformInternalToApiItem(plannerItem);
    let promise = isNewItem ?
      saveNewPlannerItem(apiItem) :
      saveExistingPlannerItem(apiItem);
    promise = promise
      .then(response => {
        const apiItem = transformPlannerNoteApiToInternalItem(response.data, getState().courses, getState().timeZone);
        return {
          item: updateOverrideDataOnItem(apiItem, overrideData),
          isNewItem
        };
      })
      .catch(() => alert(formatMessage('Failed to save to do'), true));
    dispatch(clearUpdateTodo());
    dispatch(savedPlannerItem(promise));
    return promise;
  };
};

export const deletePlannerItem = (plannerItem) => {
  return (dispatch, getState) => {
    dispatch(deletingPlannerItem(plannerItem));
    const promise = axios({
      method: 'delete',
      url: `api/v1/planner_notes/${plannerItem.id}`,
    }).then(response => transformPlannerNoteApiToInternalItem(response.data, getState().courses, getState().timeZone))
      .catch(() => alert(formatMessage('Failed to delete to do'), true));
    dispatch(clearUpdateTodo());
    dispatch(deletedPlannerItem(promise));
    dispatch(maybeUpdateTodoSidebar(promise));
    return promise;
  };
};

export const canceledEditingPlannerItem = createAction('CANCELED_EDITING_PLANNER_ITEM');

export const cancelEditingPlannerItem = () => {
  return (dispatch, getState) => {
    dispatch(clearUpdateTodo());
    dispatch(canceledEditingPlannerItem());
  };
};

function saveExistingPlannerOverride (apiOverride) {
  return axios({
    method: 'put',
    url: `api/v1/planner/overrides/${apiOverride.id}`,
    data: apiOverride,
  });
}

function saveNewPlannerOverride (apiOverride) {
  return axios({
    method: 'post',
    url: 'api/v1/planner/overrides',
    data: apiOverride,
  });
}

export const togglePlannerItemCompletion = (plannerItem) => {
  return (dispatch, getState) => {
    const savingItem = {...plannerItem, toggleAPIPending: true, show: true};
    dispatch(savingPlannerItem({item: savingItem, isNewItem: false, wasToggled: true}));
    const apiOverride = transformInternalToApiOverride(plannerItem, getState().currentUser.id);
    apiOverride.marked_complete = !apiOverride.marked_complete;
    let promise = apiOverride.id ?
      saveExistingPlannerOverride(apiOverride) :
      saveNewPlannerOverride(apiOverride);
    promise = promise.then(response => ({
      item: updateOverrideDataOnItem(plannerItem, response.data),
      isNewItem: false,
      wasToggled: true,
    })).catch(response => {
      alert(formatMessage('Unable to mark as complete.'), true);
      return ({
        item: plannerItem,
        isNewItem: false,
        wasToggled: true,
      });
    });
    dispatch(savedPlannerItem(promise));
    dispatch(maybeUpdateTodoSidebar(promise));
    return promise;
  };
};

function updateOverrideDataOnItem (plannerItem, apiOverride) {
  let updatedItem = {...plannerItem};
  updatedItem.overrideId = apiOverride.id;
  updatedItem.completed = apiOverride.marked_complete;
  updatedItem.show = true;
  return updatedItem;
}

function getOverrideDataOnItem (plannerItem) {
  return {
    id: plannerItem.overrideId,
    marked_complete: plannerItem.completed
  };
}
