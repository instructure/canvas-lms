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
import ApplyTheme from '@instructure/ui-themeable/lib/components/ApplyTheme';
import i18n from './i18n';
import configureStore from './store/configureStore';
import {
  initialOptions, getPlannerItems, scrollIntoPast, loadFutureItems,

 } from './actions';
import { registerScrollEvents } from './utilities/scrollUtils';
import { initialize as initializeAlerts } from './utilities/alertUtils';
import moment from 'moment-timezone';
import {DynamicUiManager, DynamicUiProvider, specialFallbackFocusId} from './dynamic-ui';

const defaultOptions = {
  locale: 'en',
  timeZone: moment.tz.guess(),
  currentUser: {},
  theme: 'canvas',
  courses: [],
  groups: [],
  stickyOffset: 0,
  stickyZIndex: 5,
};

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

export function render (element, options) {
  // Using this pattern because default params don't merge objects
  const opts = { ...defaultOptions, ...options };
  i18n.init(opts.locale);
  moment.locale(opts.locale);
  moment.tz.setDefault(opts.timeZone);
  dynamicUiManager.setStickyOffset(opts.stickyOffset);
  dynamicUiManager.registerAnimatable(
    'item', externalFocusableWrapper(options.externalFallbackFocusable), -1, [specialFallbackFocusId('item')]
  );
  registerScrollEvents({
    scrollIntoPast: handleScrollIntoPastAttempt,
    scrollIntoFuture: handleScrollIntoFutureAttempt,
    scrollPositionChange: pos => dynamicUiManager.handleScrollPositionChange(pos),
  });
  if (!opts.flashAlertFunctions) {
    throw new Error('You must provide callbacks to handle flash messages');
  }
  initializeAlerts(opts.flashAlertFunctions);

  store.dispatch(initialOptions(opts));
  store.dispatch(getPlannerItems(moment.tz(opts.timeZone).startOf('day')));

  ReactDOM.render(applyTheme(
    <DynamicUiProvider manager={dynamicUiManager} >
      <Provider store={store}>
        <PlannerApp
          appRef={app => dynamicUiManager.setApp(app)}
          stickyOffset={opts.stickyOffset}
          changeDashboardView={opts.changeDashboardView}
          plannerActive={plannerActive}
          currentUser={opts.currentUser}
          focusFallback={() => dynamicUiManager.focusFallback('item')}
        />
      </Provider>
    </DynamicUiProvider>
  , opts.theme), element);
}

// This method allows you to render the header items into a separate DOM node
export function renderHeader (element, auxElement, options) {
  // Using this pattern because default params don't merge objects
  const opts = { ...defaultOptions, ...options };
  ReactDOM.render(applyTheme(
    <DynamicUiProvider manager={dynamicUiManager} >
      <Provider store={store}>
        <PlannerHeader
          stickyZIndex={opts.stickyZIndex}
          timeZone={opts.timeZone}
          locale={opts.locale}
          ariaHideElement={opts.ariaHideElement}
          auxElement={auxElement}
        />
      </Provider>
    </DynamicUiProvider>
  , opts.theme), element);
}

// This method allows you to render the To Do Sidebar into a separate DOM node
export function renderToDoSidebar (element, options) {
  ReactDOM.render(
    <Provider store={store}>
      <ToDoSidebar
        courses={options.courses || window.ENV.STUDENT_PLANNER_COURSES}
        timeZone={ENV.TIMEZONE}
        locale={ENV.LOCALE}
        changeDashboardView={options.changeDashboardView}
        forCourse={options.forCourse}
      />
    </Provider>
  , element);
}

function applyTheme (el, theme) {
  return theme ? (
    <ApplyTheme
      theme={ApplyTheme.generateTheme(theme.key)}
      immutable={theme.accessible}
    >
      {el}
    </ApplyTheme>
  ): el;
}

export default function loadPlannerDashboard ({changeDashboardView, getActiveApp, flashError, flashMessage, srFlashMessage, externalFallbackFocusable, env}) {
  const element = document.getElementById('dashboard-planner');
  const headerElement = document.getElementById('dashboard-planner-header');
  const headerAuxElement = document.getElementById('dashboard-planner-header-aux');
  const stickyElement = document.getElementById('dashboard_header_container');
  const courses = env.STUDENT_PLANNER_COURSES.map(dc => ({
    ...dc,
    color: env.PREFERENCES.custom_colors[dc.assetString]
  }));

  const groups = env.STUDENT_PLANNER_GROUPS ?
    env.STUDENT_PLANNER_GROUPS.map(dg => ({
      ...dg,
      color: env.PREFERENCES.custom_colors[dg.assetString] || '#666666'
    })) : [];

  const stickyElementRect = stickyElement.getBoundingClientRect();
  const stickyOffset = stickyElementRect.bottom - stickyElementRect.top + 24;
  externalPlannerActive = () => getActiveApp() === 'planner';

  const options = {
    flashAlertFunctions: {
      visualErrorCallback: flashError,
      visualSuccessCallback: flashMessage,
      srAlertCallback: srFlashMessage
    },
    externalFallbackFocusable,
    locale: env.LOCALE,
    timeZone: env.TIMEZONE,
    currentUser: {
      id: env.current_user.id,
      displayName: env.current_user.display_name,
      avatarUrl: env.current_user.avatar_image_url,
      color: env.PREFERENCES.custom_colors[`user_${env.current_user.id}`]
    },
    ariaHideElement: document.getElementById('application'),
    theme: '',
    stickyZIndex: 3,
    stickyOffset: stickyOffset,
    courses: courses,
    groups: groups,
    changeDashboardView,
  };

  if (element) {
    render(element, options);
  }

  if (headerElement) {
    renderHeader(headerElement, headerAuxElement, options);
  }
}
