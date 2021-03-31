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
import React, {useState, useEffect, useRef} from 'react'
import {connect, Provider} from 'react-redux'
import I18n from 'i18n!k5_course'
import PropTypes from 'prop-types'

import {
  createTeacherPreview,
  startLoadingAllOpportunities,
  store
} from '@instructure/canvas-planner'
import {
  IconCalendarMonthLine,
  IconHomeLine,
  IconModuleLine,
  IconStarLightLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Heading} from '@instructure/ui-heading'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'

import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import K5Tabs from '@canvas/k5/react/K5Tabs'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import {TAB_IDS} from '@canvas/k5/react/utils'
import k5Theme, {theme} from '@canvas/k5/react/k5-theme'

const DEFAULT_COLOR = k5Theme.variables.colors.backgroundMedium
const HERO_HEIGHT_PX = 400

const COURSE_TABS = [
  {
    id: TAB_IDS.OVERVIEW,
    icon: IconHomeLine,
    label: I18n.t('Overview')
  },
  {
    id: TAB_IDS.SCHEDULE,
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule')
  },
  {
    id: TAB_IDS.MODULES,
    icon: IconModuleLine,
    label: I18n.t('Modules')
  },
  {
    id: TAB_IDS.GRADES,
    icon: IconStarLightLine,
    label: I18n.t('Grades')
  }
]

export function CourseHeaderHero({name, image, backgroundColor}) {
  return (
    <div
      style={{
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'flex-end',
        backgroundColor: !image && backgroundColor,
        backgroundImage: image && `url(${image})`,
        backgroundSize: 'cover',
        backgroundPosition: 'center center',
        backgroundRepeat: 'no-repeat',
        borderRadius: '8px',
        minHeight: '25vh',
        maxHeight: `${HERO_HEIGHT_PX}px`,
        marginBottom: '1rem',
        marginTop: '-1.25rem'
      }}
      aria-hidden="true"
      data-testid="k5-course-header-hero"
    >
      <div
        style={{
          background: 'linear-gradient(90deg, rgba(0, 0, 0, 0.7), transparent)',
          borderBottomLeftRadius: '8px',
          borderBottomRightRadius: '8px',
          padding: '1rem'
        }}
      >
        <Heading as="h1" color="primary-inverse">
          <TruncateText>{name}</TruncateText>
        </Heading>
      </div>
    </div>
  )
}

export function K5Course({
  assignmentsDueToday,
  assignmentsMissing,
  assignmentsCompletedForToday,
  imageUrl,
  loadAllOpportunities,
  name,
  timeZone,
  defaultTab = TAB_IDS.OVERVIEW,
  plannerEnabled = false
}) {
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    callback: () => loadAllOpportunities(),
    singleCourse: true
  })

  const modulesRef = useRef(null)
  useEffect(() => {
    modulesRef.current = document.getElementById('k5-modules-container')
  }, [])

  useEffect(() => {
    if (modulesRef.current) {
      modulesRef.current.style.display = currentTab === TAB_IDS.MODULES ? 'block' : 'none'
    }
  }, [currentTab])

  return (
    <K5DashboardContext.Provider
      value={{
        assignmentsDueToday,
        assignmentsMissing,
        assignmentsCompletedForToday,
        isStudent: plannerEnabled
      }}
    >
      <View as="section">
        <K5Tabs
          currentTab={currentTab}
          onTabChange={handleTabChange}
          tabs={COURSE_TABS}
          tabsRef={setTabsRef}
        >
          <CourseHeaderHero name={name} image={imageUrl} backgroundColor={DEFAULT_COLOR} />
        </K5Tabs>
        {plannerInitialized && <SchedulePage visible={currentTab === TAB_IDS.SCHEDULE} />}
        {!plannerEnabled && currentTab === TAB_IDS.SCHEDULE && createTeacherPreview(timeZone)}
      </View>
    </K5DashboardContext.Provider>
  )
}

K5Course.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  loadAllOpportunities: PropTypes.func.isRequired,
  name: PropTypes.string.isRequired,
  timeZone: PropTypes.string.isRequired,
  defaultTab: PropTypes.string,
  imageUrl: PropTypes.string,
  plannerEnabled: PropTypes.bool
}

const WrappedK5Course = connect(mapStateToProps, {
  loadAllOpportunities: startLoadingAllOpportunities
})(K5Course)

export default props => (
  <ApplyTheme theme={theme}>
    <Provider store={store}>
      <WrappedK5Course {...props} />
    </Provider>
  </ApplyTheme>
)
