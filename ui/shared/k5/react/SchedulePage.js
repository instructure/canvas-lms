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
  renderWeeklyPlannerHeader,
  JumpToHeaderButton
} from '@instructure/canvas-planner'

const SchedulePage = ({visible = false}) => {
  const [isPlannerCreated, setPlannerCreated] = useState(false)
  const plannerApp = useRef()

  useEffect(() => {
    plannerApp.current = createPlannerApp()
    setPlannerCreated(true)
  }, [])

  return (
    <section
      id="dashboard_page_schedule"
      style={{
        display: visible ? 'flex' : 'none',
        flexDirection: 'column'
      }}
      aria-hidden={!visible}
    >
      {renderWeeklyPlannerHeader({visible})}
      {isPlannerCreated && plannerApp.current}
      {isPlannerCreated && <JumpToHeaderButton />}
    </section>
  )
}

SchedulePage.propTypes = {
  visible: PropTypes.bool
}

export default SchedulePage
