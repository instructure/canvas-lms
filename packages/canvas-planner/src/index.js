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

// runtimes and polyfills that need to be imported first
import 'regenerator-runtime/runtime';

import React from 'react';
import ReactDOM from 'react-dom';
import { Provider } from 'react-redux';
import PlannerApp from './components/PlannerApp';
import PlannerHeader from './components/PlannerHeader';
import ToDoSidebar from './components/ToDoSidebar';
import i18n from './i18n';
import configureStore from './store/configureStore';
import {
  initialOptions, getPlannerItems, scrollIntoPast, loadFutureItems,

 } from './actions';
import { registerScrollEvents } from './utilities/scrollUtils';
import { initialize as initializeAlerts } from './utilities/alertUtils';
import { initializeContent } from './utilities/contentUtils';
import { initializeDateTimeFormatters } from './utilities/dateUtils';
import moment from 'moment-timezone';
import {DynamicUiManager, DynamicUiProvider, specialFallbackFocusId} from './dynamic-ui';

let externalPlannerActive;
const plannerActive = () => externalPlannerActive ? externalPlannerActive() : false;

const dynamicUiManager = new DynamicUiManager({plannerActive});
export const store = configureStore(dynamicUiManager);

function handleScrollIntoPastAttempt () {
  if (!plannerActive()) return;
  if (!store.getState().loading.loadingPast && !store.getState().loading.loadingFuture && !store.getState().loading.allPastItemsLoaded) {
    store.dispatch(scrollIntoPast());
  }
}

function handleScrollIntoFutureAttempt () {
  if (!plannerActive()) return;
  if (!store.getState().loading.loadingPast && !store.getState().loading.loadingFuture && !store.getState().loading.allFutureItemsLoaded) {
    store.dispatch(loadFutureItems());
  }
}

function externalFocusableWrapper (externalFallbackFocusable) {
  return {
    getFocusable () { return externalFallbackFocusable; },
    getScrollable () { return externalFallbackFocusable; },
  };
}

const defaultOptions = {
  getActiveApp: () => '',
  stickyZIndex: 3,
};

const defaultEnv = {};

const plannerHeaderId = "dashboard_header_container";
const plannerNewActivityButtonId = "new_activity_button"

function mergeDefaultOptions (options) {
  const newOpts = {...defaultOptions, ...options};
  newOpts.env = {...defaultEnv, ...options.env};

  // special handling for these env vars because sometimes they come in
  // explicitly set to false instead of just not being defined in options.env
  if (!newOpts.env.STUDENT_PLANNER_COURSES) newOpts.env.STUDENT_PLANNER_COURSES = [];
  if (!newOpts.env.STUDENT_PLANNER_GROUPS) newOpts.env.STUDENT_PLANNER_GROUPS = [];
  return newOpts;
}

function initializeCourseAndGroupColors (options) {
  if (!options.env.PREFERENCES) return;
  options.env.STUDENT_PLANNER_COURSES = options.env.STUDENT_PLANNER_COURSES.map(dc => ({
    ...dc,
    color: options.env.PREFERENCES.custom_colors[dc.assetString]
  }));
  options.env.STUDENT_PLANNER_GROUPS = options.env.STUDENT_PLANNER_GROUPS.map(dg => ({
    ...dg,
    color: options.env.PREFERENCES.custom_colors[dg.assetString] || '#666666'
  }));
}

// You have to call this first, before you call loadPlannerDashboard or renderToDoSidebar
// options: {
// env: {                       <required: ENV from Canvas>
//   MOMENT_LOCALE,             <required>
//   TIMEZONE,                  <required>
//   current_user: {            <required>
//     id,
//     display_name,
//     avatar_image_url,
//   }
//   PREFERENCES: {             <optional>
//     custom_colors,
//   },
//   STUDENT_PLANNER_COURSES,   <default: []>
//   STUDENT_PLANNER_GROUPS,    <default: []>
// }
// flashError,                  <required>
// flashMessage,                <required>
// srFlashMessage,              <required>
// convertApiUserContent,       <required - conversion to make user content from api work properly>
// dateTimeFormatters: {        <optional - canvas methods for date and time formatting>
//   dateString,                <optional>
//   timeString,                <optional>
//   datetimeString,            <optional>
// },
// externalFallbackFocusable,   <optional - element where focus goes when it should go before planner>
// getActiveApp,                <optional - method to get the current dashboard>
// changeDashboardView,         <optional - method to change the current dashboard>
// forCourse,                   <optional - course id if this is a sidebar for a specific course page>
let initializedOptions = null;
export function initializePlanner (options) {
  if (initializedOptions) throw new Error('initializePlanner may not be called more than once');

  options = mergeDefaultOptions(options);

  if (!(options.env.MOMENT_LOCALE && options.env.TIMEZONE)) {
    throw new Error('env.MOMENT_LOCALE and env.TIMEZONE are required options for initializePlanner');
  }

  const {flashError, flashMessage, srFlashMessage} = options;
  if (!(flashError && flashMessage && srFlashMessage)) {
    throw new Error('flash message callbacks are required options for initializePlanner');
  }

  if (!options.convertApiUserContent) {
    throw new Error('convertApiUserContent is a required option for initializePlanner');
  }

  externalPlannerActive = () => options.getActiveApp() === 'planner';

  i18n.init(options.env.MOMENT_LOCALE);
  moment.locale(options.env.MOMENT_LOCALE);
  moment.tz.setDefault(options.env.TIMEZONE);
  initializeAlerts({
    visualSuccessCallback: flashMessage,
    visualErrorCallback: flashError,
    srAlertCallback: srFlashMessage,
  });
  initializeContent(options);
  initializeDateTimeFormatters(options.dateTimeFormatters);

  options.plannerNewActivityButtonId = plannerNewActivityButtonId;
  dynamicUiManager.setOffsetElementIds(plannerHeaderId, plannerNewActivityButtonId);
    
  if (options.externalFallbackFocusable) {
    dynamicUiManager.registerAnimatable(
      'item', externalFocusableWrapper(options.externalFallbackFocusable), -1, [specialFallbackFocusId('item')]
    );
  }

  initializeCourseAndGroupColors(options);

  initializedOptions = options;
  store.dispatch(initialOptions(options));
}

export function resetPlanner () {
  initializedOptions = null;
}

function render (element) {
  registerScrollEvents({
    scrollIntoPast: handleScrollIntoPastAttempt,
    scrollIntoFuture: handleScrollIntoFutureAttempt,
    scrollPositionChange: pos => dynamicUiManager.handleScrollPositionChange(pos),
  });

  ReactDOM.render(
    <DynamicUiProvider manager={dynamicUiManager} >
      <Provider store={store}>
        <PlannerApp
          appRef={app => dynamicUiManager.setApp(app)}
          changeDashboardView={initializedOptions.changeDashboardView}
          plannerActive={plannerActive}
          currentUser={store.getState().currentUser}
          focusFallback={() => dynamicUiManager.focusFallback('item')}
        />
      </Provider>
    </DynamicUiProvider>, element);

  store.dispatch(getPlannerItems(moment.tz(initializedOptions.env.timeZone).startOf('day')));
}

// This method allows you to render the header items into a separate DOM node
function renderHeader (element, auxElement) {
  const ariaHideElement = document.getElementById('application');

  // Using this pattern because default params don't merge objects
  ReactDOM.render(
    <DynamicUiProvider manager={dynamicUiManager} >
      <Provider store={store}>
        <PlannerHeader
          stickyZIndex={initializedOptions.stickyZIndex}
          stickyButtonId={initializedOptions.plannerNewActivityButtonId}
          timeZone={initializedOptions.env.TIMEZONE}
          locale={initializedOptions.env.MOMENT_LOCALE}
          ariaHideElement={ariaHideElement}
          auxElement={auxElement}
        />
      </Provider>
    </DynamicUiProvider>, element);
}

// This method allows you to render the To Do Sidebar into a separate DOM node
export function renderToDoSidebar (element) {
  if (!initializedOptions) throw new Error('initializePlanner must be called before renderToDoSidebar');

  const env = initializedOptions.env;

  ReactDOM.render(
    <Provider store={store}>
      <ToDoSidebar
        courses={env.STUDENT_PLANNER_COURSES}
        timeZone={env.TIMEZONE}
        locale={env.MOMENT_LOCALE}
        changeDashboardView={initializedOptions.changeDashboardView}
        forCourse={initializedOptions.forCourse}
      />
    </Provider>
  , element);
}

export function loadPlannerDashboard () {
  if (!initializedOptions) throw new Error('initializePlanner must be called before loadPlannerDashboard');

  const element = document.getElementById('dashboard-planner');
  const headerElement = document.getElementById('dashboard-planner-header');
  const headerAuxElement = document.getElementById('dashboard-planner-header-aux');

  if (element) {
    render(element);
  }

  if (headerElement) {
    renderHeader(headerElement, headerAuxElement);
  }
}
