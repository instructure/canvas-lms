/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {dateString, datetimeString, timeString} from '@canvas/datetime/date-functions'

import apiUserContent from '@canvas/util/jquery/apiUserContent'
import {initializePlanner} from '@canvas/planner'
import {showFlashAlert, showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('k5_use_planner')

/**
 * A hook for setting up the planner prior to first rendering it. This function is
 * mostly responsible for setting up the correct initial options and notifying the
 * caller when that initialization is complete.
 *
 * @param {Object} config - An object containing configuration options for this hook.
 * @param {boolean} config.plannerEnabled - Whether or not to load the planner at all.
 *        Right now we only load the planner for students.
 * @param {function(): boolean} config.isPlannerActive - Passed-in function to determine
 *        when the planner should be rendered on the page. Takes no arguments and returns
 *        a boolean.
 * @param {React.MutableRefObject<Node>} [config.focusFallback] - Element ref where focus goes when it should
 *        go before planner.
 * @param {function} [config.callback] - Passed-in function that is triggered when the
 *        planner has finished initializing. Receives an object containing the full
 *        set of initialized configuration that the planner is using.
 * @param {boolean} singleCourse - Whether or not to render the planner in single-course mode.
 * @returns {(boolean|Object)} - Returns an object containing the initialized configuration
 *        information, or false if the planner has not been initialized yet.
 */
export default function usePlanner({
  plannerEnabled,
  isPlannerActive,
  focusFallback,
  singleCourse = false,
  observedUserId,
  isObserver = false,
}) {
  const [plannerInitializing, setPlannerInitializing] = useState(false)
  const [plannerInitialized, setPlannerInitialized] = useState(false)

  useEffect(() => {
    if (
      plannerEnabled &&
      !plannerInitializing &&
      !plannerInitialized &&
      (!isObserver || !!observedUserId)
    ) {
      setPlannerInitializing(true)
      initializePlanner({
        getActiveApp: () => (isPlannerActive() ? 'planner' : ''),
        flashError: message => showFlashAlert({message, type: 'error'}),
        flashMessage: message => showFlashAlert({message, type: 'info'}),
        srFlashMessage: message => showFlashAlert({message, type: 'info', srOnly: true}),
        convertApiUserContent: apiUserContent.convert,
        dateTimeFormatters: {dateString, timeString, datetimeString},
        externalFallbackFocusable: focusFallback,
        env: window.ENV,
        singleCourse,
        observedUserId,
      })
        .then(val => {
          setPlannerInitialized(val)
        })
        .catch(_ex => {
          showFlashError(I18n.t('Failed to load the schedule tab'))()
        })
    }
    // The rest of the dependencies don't change
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isObserver, observedUserId])

  return plannerInitialized
}
