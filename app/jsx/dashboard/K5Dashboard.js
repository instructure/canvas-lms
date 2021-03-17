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
import React, {useEffect, useState} from 'react'
import {connect, Provider} from 'react-redux'
import I18n from 'i18n!k5_dashboard'
import PropTypes from 'prop-types'

import {
  createTeacherPreview,
  startLoadingAllOpportunities,
  responsiviser,
  store
} from '@instructure/canvas-planner'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconHomeLine,
  IconStarLightLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {View} from '@instructure/ui-view'

import K5Tabs from './K5Tabs'
import GradesPage from './pages/GradesPage'
import HomeroomPage from './pages/HomeroomPage'
import K5DashboardContext from './K5DashboardContext'
import loadCardDashboard from '../bundles/dashboard_card'
import {mapStateToProps} from './redux-helpers'
import SchedulePage from './pages/SchedulePage'
import ResourcesPage from './pages/ResourcesPage'
import {TAB_IDS} from './utils'
import {theme} from './k5-theme'
import useTabState from 'jsx/dashboard/hooks/useTabState'
import usePlanner from 'jsx/dashboard/hooks/usePlanner'

const DASHBOARD_TABS = [
  {
    id: TAB_IDS.HOMEROOM,
    icon: IconHomeLine,
    label: I18n.t('Homeroom')
  },
  {
    id: TAB_IDS.SCHEDULE,
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule')
  },
  {
    id: TAB_IDS.GRADES,
    icon: IconStarLightLine,
    label: I18n.t('Grades')
  },
  {
    id: TAB_IDS.RESOURCES,
    icon: IconBankLine,
    label: I18n.t('Resources')
  }
]

export const K5Dashboard = ({
  assignmentsDueToday,
  assignmentsMissing,
  assignmentsCompletedForToday,
  currentUser: {display_name},
  loadAllOpportunities,
  timeZone,
  defaultTab = TAB_IDS.HOMEROOM,
  plannerEnabled = false,
  responsiveSize = 'large'
}) => {
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab)
  const [cards, setCards] = useState(null)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    callback: () => loadAllOpportunities()
  })

  useEffect(() => {
    if (!cards && (currentTab === TAB_IDS.RESOURCES || currentTab === TAB_IDS.HOMEROOM)) {
      loadCardDashboard(setCards)
    }
  }, [cards, currentTab])

  return (
    <View as="section">
      <K5DashboardContext.Provider
        value={{
          assignmentsDueToday,
          assignmentsMissing,
          assignmentsCompletedForToday,
          isStudent: plannerEnabled,
          responsiveSize
        }}
      >
        <K5Tabs
          currentTab={currentTab}
          name={display_name}
          onTabChange={handleTabChange}
          tabs={DASHBOARD_TABS}
          tabsRef={setTabsRef}
        />
        {cards && (
          <HomeroomPage
            cards={cards}
            isStudent={plannerEnabled}
            requestTabChange={handleTabChange}
            responsiveSize={responsiveSize}
            visible={currentTab === TAB_IDS.HOMEROOM}
          />
        )}
        {plannerInitialized && <SchedulePage visible={currentTab === TAB_IDS.SCHEDULE} />}
        {!plannerEnabled && currentTab === TAB_IDS.SCHEDULE && createTeacherPreview(timeZone)}
        <GradesPage visible={currentTab === TAB_IDS.GRADES} />
        {cards && <ResourcesPage cards={cards} visible={currentTab === TAB_IDS.RESOURCES} />}
      </K5DashboardContext.Provider>
    </View>
  )
}

K5Dashboard.displayName = 'K5Dashboard'
K5Dashboard.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  currentUser: PropTypes.shape({
    display_name: PropTypes.string
  }).isRequired,
  loadAllOpportunities: PropTypes.func.isRequired,
  timeZone: PropTypes.string.isRequired,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  responsiveSize: PropTypes.string
}

const WrappedK5Dashboard = connect(mapStateToProps, {
  loadAllOpportunities: startLoadingAllOpportunities
})(responsiviser()(K5Dashboard))

export default props => (
  <ApplyTheme theme={theme}>
    <Provider store={store}>
      <WrappedK5Dashboard {...props} />
    </Provider>
  </ApplyTheme>
)
