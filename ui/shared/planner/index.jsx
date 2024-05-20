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

import React, {Suspense} from 'react'
import ReactDOM from 'react-dom'
import {Provider} from 'react-redux'
import moment from 'moment-timezone'
import {Spinner} from '@instructure/ui-spinner'
import configureStore from './store/configureStore'
import {
  initialOptions,
  getPlannerItems,
  getWeeklyPlannerItems,
  preloadSurroundingWeeks,
  scrollIntoPast,
  loadFutureItems,
  loadThisWeekItems,
  startLoadingAllOpportunities,
  toggleMissingItems,
  reloadWithObservee,
  getInitialOpportunities,
} from './actions'
import {registerScrollEvents} from './utilities/scrollUtils'
import {initialize as initializeAlerts} from './utilities/alertUtils'
import {initializeContent} from './utilities/contentUtils'
import {initializeDateTimeFormatters} from './utilities/dateUtils'
import {DynamicUiManager, DynamicUiProvider, specialFallbackFocusId} from './dynamic-ui'
import responsiviser from './components/responsiviser'

const PlannerPreview = React.lazy(() => import('./components/PlannerPreview'))
const ToDoSidebar = React.lazy(() => import('./components/ToDoSidebar'))
const PlannerApp = React.lazy(() => import('./components/PlannerApp'))
const PlannerHeader = React.lazy(() => import('./components/PlannerHeader'))
const WeeklyPlannerHeader = React.lazy(() => import('./components/WeeklyPlannerHeader'))

export * from './components'

export {loadThisWeekItems, toggleMissingItems}

export {responsiviser}

export function createPlannerPreview(timeZone, singleCourse) {
  return (
    <Suspense fallback={loading()}>
      <PlannerPreview timeZone={timeZone} singleCourse={singleCourse} />
    </Suspense>
  )
}

let externalPlannerActive
const plannerActive = () => (externalPlannerActive ? externalPlannerActive() : false)

const dynamicUiManager = new DynamicUiManager({plannerActive})
export const store = configureStore(dynamicUiManager)

function handleScrollIntoPastAttempt() {
  if (!plannerActive()) return
  if (
    !store.getState().loading.loadingPast &&
    !store.getState().loading.loadingFuture &&
    !store.getState().loading.allPastItemsLoaded
  ) {
    store.dispatch(scrollIntoPast())
  }
}

function handleScrollIntoFutureAttempt() {
  if (!plannerActive()) return
  if (
    !store.getState().loading.loadingPast &&
    !store.getState().loading.loadingFuture &&
    !store.getState().loading.allFutureItemsLoaded
  ) {
    store.dispatch(loadFutureItems())
  }
}

function externalFocusableWrapper(externalFallbackFocusable) {
  return {
    getFocusable() {
      return externalFallbackFocusable
    },
    getScrollable() {
      return externalFallbackFocusable
    },
  }
}

const defaultOptions = {
  getActiveApp: () => '',
  stickyZIndex: 3,
}

const defaultEnv = {}

const plannerHeaderId = 'dashboard_header_container'
const plannerNewActivityButtonId = 'new_activity_button'
const weeklyPlannerHeaderId = 'weekly_planner_header'

function mergeDefaultOptions(options) {
  const newOpts = {...defaultOptions, ...options}
  newOpts.env = {...defaultEnv, ...options.env}

  // special handling for these env vars because sometimes they come in
  // explicitly set to false instead of just not being defined in options.env
  if (!newOpts.env.STUDENT_PLANNER_COURSES) newOpts.env.STUDENT_PLANNER_COURSES = []
  if (!newOpts.env.STUDENT_PLANNER_GROUPS) newOpts.env.STUDENT_PLANNER_GROUPS = []
  return newOpts
}

function getCourseColor(
  {assetString, color},
  {K5_USER, K5_SUBJECT_COURSE, PREFERENCES: {custom_colors = {}}}
) {
  if (K5_USER || K5_SUBJECT_COURSE) {
    return color || '#394B58'
  } else {
    return custom_colors[assetString]
  }
}

function initializeCourseAndGroupColors(options) {
  if (!options.env.PREFERENCES) return
  options.env.STUDENT_PLANNER_COURSES = options.env.STUDENT_PLANNER_COURSES.map(dc => ({
    ...dc,
    color: getCourseColor(dc, options.env),
  }))
  options.env.STUDENT_PLANNER_GROUPS = options.env.STUDENT_PLANNER_GROUPS.map(dg => ({
    ...dg,
    color: options.env.PREFERENCES.custom_colors[dg.assetString] || '#666666',
  }))
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
let initializedOptions = null
export async function initializePlanner(options) {
  return new Promise((resolve, reject) => {
    try {
      if (initializedOptions) throw new Error('initializePlanner may not be called more than once')

      options = mergeDefaultOptions(options)

      if (!(options.env.MOMENT_LOCALE && options.env.TIMEZONE)) {
        throw new Error(
          'env.MOMENT_LOCALE and env.TIMEZONE are required options for initializePlanner'
        )
      }

      const {flashError, flashMessage, srFlashMessage} = options
      if (!(flashError && flashMessage && srFlashMessage)) {
        throw new Error('flash message callbacks are required options for initializePlanner')
      }

      if (!options.convertApiUserContent) {
        throw new Error('convertApiUserContent is a required option for initializePlanner')
      }

      externalPlannerActive = () => options.getActiveApp() === 'planner'

      moment.locale(options.env.MOMENT_LOCALE)
      moment.tz.setDefault(options.env.TIMEZONE)
      initializeAlerts({
        visualSuccessCallback: flashMessage,
        visualErrorCallback: flashError,
        srAlertCallback: srFlashMessage,
      })
      initializeContent(options)
      initializeDateTimeFormatters(options.dateTimeFormatters)

      options.plannerNewActivityButtonId = plannerNewActivityButtonId
      if (options.env.K5_USER || options.env.K5_SUBJECT_COURSE) {
        dynamicUiManager.setOffsetElementIds(weeklyPlannerHeaderId, null)
      } else {
        dynamicUiManager.setOffsetElementIds(plannerHeaderId, plannerNewActivityButtonId)
      }

      if (options.externalFallbackFocusable) {
        dynamicUiManager.registerAnimatable(
          'item',
          externalFocusableWrapper(options.externalFallbackFocusable),
          -1,
          [specialFallbackFocusId('item')]
        )
      }

      initializeCourseAndGroupColors(options)

      initializedOptions = options
      store.dispatch(initialOptions(options))
      resolve(initializedOptions)
    } catch (err) {
      reject(err)
    }
  })
}

export function resetPlanner() {
  initializedOptions = null
}

function loading() {
  return <Spinner renderTitle="Loading..." size="small" />
}

export function createPlannerApp() {
  if (!store.getState().weeklyDashboard) {
    // disable load on scroll for weekly dashboard
    if (!createPlannerApp.scrollEventsRegistered) {
      // register events only once
      registerScrollEvents({
        scrollIntoPast: handleScrollIntoPastAttempt,
        scrollIntoFuture: handleScrollIntoFutureAttempt,
        scrollPositionChange: pos => dynamicUiManager.handleScrollPositionChange(pos),
      })
      createPlannerApp.scrollEventsRegistered = true
    }

    store
      .dispatch(getPlannerItems(moment.tz(initializedOptions.env.timeZone).startOf('day')))
      .then(() => {
        store.dispatch(getInitialOpportunities())
      })
  } else {
    store
      .dispatch(getWeeklyPlannerItems(moment.tz(initializedOptions.env.timeZone).startOf('day')))
      .then(() => {
        store.dispatch(startLoadingAllOpportunities())
      })
  }

  return (
    <DynamicUiProvider manager={dynamicUiManager}>
      <Provider store={store}>
        <Suspense fallback={loading()}>
          <PlannerApp
            appRef={app => dynamicUiManager.setApp(app)}
            changeDashboardView={initializedOptions.changeDashboardView}
            plannerActive={plannerActive}
            currentUser={store.getState().currentUser}
            focusFallback={() => dynamicUiManager.focusFallback('item')}
            k5Mode={initializedOptions.env.K5_USER || initializedOptions.env.K5_SUBJECT_COURSE}
            isWeekly={initializedOptions.env.K5_USER || initializedOptions.env.K5_SUBJECT_COURSE}
          />
        </Suspense>
      </Provider>
    </DynamicUiProvider>
  )
}
createPlannerApp.scrollEventsRegistered = false

function renderApp(element) {
  ReactDOM.render(createPlannerApp(), element)
}

// This method allows you to render the header items into a separate DOM node
function renderHeader(element, auxElement) {
  const ariaHideElement = document.getElementById('application')

  // Using this pattern because default params don't merge objects
  ReactDOM.render(
    <DynamicUiProvider manager={dynamicUiManager}>
      <Provider store={store}>
        <Suspense fallback={loading()}>
          <PlannerHeader
            stickyZIndex={initializedOptions.stickyZIndex}
            stickyButtonId={initializedOptions.plannerNewActivityButtonId}
            timeZone={initializedOptions.env.TIMEZONE}
            locale={initializedOptions.env.MOMENT_LOCALE}
            ariaHideElement={ariaHideElement}
            auxElement={auxElement}
          />
        </Suspense>
      </Provider>
    </DynamicUiProvider>,
    element
  )
}

// This method allows you to render the To Do Sidebar into a separate DOM node
export function renderToDoSidebar(element) {
  if (!initializedOptions)
    throw new Error('initializePlanner must be called before renderToDoSidebar')

  const env = initializedOptions.env
  const additionalTitleContext =
    initializedOptions.env.FEATURES?.render_both_to_do_lists &&
    initializedOptions.env.current_user_roles &&
    initializedOptions.env.current_user_roles.includes('teacher') &&
    initializedOptions.env.current_user_roles.includes('student')

  ReactDOM.render(
    <Provider store={store}>
      <Suspense fallback={loading()}>
        <ToDoSidebar
          timeZone={env.TIMEZONE}
          locale={env.MOMENT_LOCALE}
          changeDashboardView={initializedOptions.changeDashboardView}
          forCourse={initializedOptions.forCourse}
          additionalTitleContext={additionalTitleContext}
        />
      </Suspense>
    </Provider>,
    element
  )
}

export function renderWeeklyPlannerHeader(props) {
  return (
    <DynamicUiProvider manager={dynamicUiManager}>
      <Provider store={store}>
        <Suspense fallback={loading()}>
          <WeeklyPlannerHeader {...props} />
        </Suspense>
      </Provider>
    </DynamicUiProvider>
  )
}

export function loadPlannerDashboard() {
  if (!initializedOptions)
    throw new Error('initializePlanner must be called before loadPlannerDashboard')

  const element = document.getElementById('dashboard-planner')
  const headerElement = document.getElementById('dashboard-planner-header')
  const headerAuxElement = document.getElementById('dashboard-planner-header-aux')

  if (element) {
    renderApp(element)
  }

  if (headerElement) {
    renderHeader(headerElement, headerAuxElement)
  }
}

// Allows you to defer preloading surrounding weeks' items until the user is more
// likely to use them (in weekly-planner mode)
export function preloadInitialItems() {
  if (!initializedOptions)
    throw new Error('initializePlanner must be called before preloadInitialItems')

  if (store.getState().weeklyDashboard) {
    store.dispatch(preloadSurroundingWeeks())
  }
}

// Call with student id to load planner scoped to
// one of an observer's students
export function reloadPlannerForObserver(newObserveeId) {
  if (!initializedOptions)
    throw new Error('initializePlanner must be called before reloadPlannerForObserver')

  // if observer is observing themselves, then we're not really observing
  const observeeId =
    !newObserveeId || newObserveeId === store.getState().currentUser.id ? null : newObserveeId

  if (observeeId !== store.getState().selectedObservee) {
    store.dispatch(reloadWithObservee(observeeId))
  }
}
