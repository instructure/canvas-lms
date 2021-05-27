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

import React, {useEffect, useRef, useState} from 'react'
import PropTypes from 'prop-types'

import {
  createPlannerApp,
  createPlannerPreview,
  renderWeeklyPlannerHeader,
  JumpToHeaderButton
} from '@instructure/canvas-planner'

import EmptyDashboardState from '@canvas/k5/react/EmptyDashboardState'

const SchedulePage = ({
  plannerEnabled,
  plannerInitialized,
  timeZone,
  userHasEnrollments,
  visible
}) => {
  const [isPlannerCreated, setPlannerCreated] = useState(false)
  const plannerApp = useRef()

  useEffect(() => {
    if (plannerInitialized) {
      plannerApp.current = createPlannerApp()
      setPlannerCreated(true)
    }
  }, [plannerInitialized])

  let content = <></>
  if (plannerInitialized && isPlannerCreated) {
    content = (
      <>
        {renderWeeklyPlannerHeader({visible})}
        {plannerApp.current}
        <JumpToHeaderButton />
      </>
    )
  } else if (!userHasEnrollments) {
    content = <EmptyDashboardState />
  } else if (!plannerEnabled) {
    content = createPlannerPreview(timeZone)
  }

  return (
    <section
      id="dashboard_page_schedule"
      style={{
        display: visible ? 'flex' : 'none',
        flexDirection: 'column'
      }}
      aria-hidden={!visible}
    >
      {content}
    </section>
  )
}

SchedulePage.propTypes = {
  plannerEnabled: PropTypes.bool.isRequired,
  plannerInitialized: PropTypes.oneOfType([PropTypes.bool, PropTypes.object]).isRequired,
  timeZone: PropTypes.string.isRequired,
  userHasEnrollments: PropTypes.bool.isRequired,
  visible: PropTypes.bool.isRequired
}

export default SchedulePage
