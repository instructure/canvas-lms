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
  loadThisWeekItems,
  startLoadingAllOpportunities,
  responsiviser,
  store,
  toggleMissingItems
} from '@instructure/canvas-planner'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconHomeLine,
  IconStarLightLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {View} from '@instructure/ui-view'

import K5Tabs from '@canvas/k5/react/K5Tabs'
import GradesPage from './GradesPage'
import HomeroomPage from './HomeroomPage'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import loadCardDashboard from '@canvas/dashboard-card'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import ResourcesPage from './ResourcesPage'
import {FOCUS_TARGETS, TAB_IDS} from '@canvas/k5/react/utils'
import {theme} from '@canvas/k5/react/k5-theme'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'

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
  loadingOpportunities,
  currentUser: {display_name},
  loadAllOpportunities,
  switchToToday,
  timeZone,
  toggleMissing,
  defaultTab = TAB_IDS.HOMEROOM,
  plannerEnabled = false,
  responsiveSize = 'large',
  canCreateCourses = false
}) => {
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab)
  const [cards, setCards] = useState(null)
  const [cardsSettled, setCardsSettled] = useState(false)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    callback: () => loadAllOpportunities()
  })

  useEffect(() => {
    if (!cards && (currentTab === TAB_IDS.HOMEROOM || currentTab === TAB_IDS.RESOURCES)) {
      loadCardDashboard((dc, cardsFinishedLoading) => {
        setCards(dc)
        setCardsSettled(cardsFinishedLoading)
      })
    }
  }, [cards, currentTab])

  const handleSwitchToToday = () => {
    handleTabChange(TAB_IDS.SCHEDULE, FOCUS_TARGETS.TODAY)
    switchToToday()
  }

  const handleSwitchToMissingItems = () => {
    toggleMissing({forceExpanded: true})
    handleTabChange(TAB_IDS.SCHEDULE, FOCUS_TARGETS.MISSING_ITEMS)
    switchToToday()
  }

  return (
    <View as="section">
      <K5DashboardContext.Provider
        value={{
          assignmentsDueToday,
          assignmentsMissing,
          assignmentsCompletedForToday,
          cardsSettled,
          loadingOpportunities,
          isStudent: plannerEnabled,
          responsiveSize,
          switchToMissingItems: handleSwitchToMissingItems,
          switchToToday: handleSwitchToToday
        }}
      >
        <K5Tabs
          currentTab={currentTab}
          name={display_name}
          onTabChange={handleTabChange}
          tabs={DASHBOARD_TABS}
          tabsRef={setTabsRef}
        />
        <HomeroomPage
          cards={cards}
          cardsSettled={cardsSettled}
          isStudent={plannerEnabled}
          responsiveSize={responsiveSize}
          visible={currentTab === TAB_IDS.HOMEROOM}
          canCreateCourses={canCreateCourses}
        />
        {plannerInitialized && <SchedulePage visible={currentTab === TAB_IDS.SCHEDULE} />}
        {!plannerEnabled && currentTab === TAB_IDS.SCHEDULE && createTeacherPreview(timeZone)}
        <GradesPage visible={currentTab === TAB_IDS.GRADES} />
        {cards && (
          <ResourcesPage
            cards={cards}
            cardsSettled={cardsSettled}
            visible={currentTab === TAB_IDS.RESOURCES}
          />
        )}
      </K5DashboardContext.Provider>
    </View>
  )
}

K5Dashboard.displayName = 'K5Dashboard'
K5Dashboard.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  loadingOpportunities: PropTypes.bool.isRequired,
  currentUser: PropTypes.shape({
    display_name: PropTypes.string
  }).isRequired,
  loadAllOpportunities: PropTypes.func.isRequired,
  switchToToday: PropTypes.func.isRequired,
  timeZone: PropTypes.string.isRequired,
  toggleMissing: PropTypes.func.isRequired,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  responsiveSize: PropTypes.string,
  canCreateCourses: PropTypes.bool
}

const mapDispatchToProps = {
  toggleMissing: toggleMissingItems,
  loadAllOpportunities: startLoadingAllOpportunities,
  switchToToday: loadThisWeekItems
}

const WrappedK5Dashboard = connect(
  mapStateToProps,
  mapDispatchToProps
)(responsiviser()(K5Dashboard))

export default props => (
  <ApplyTheme theme={theme}>
    <Provider store={store}>
      <WrappedK5Dashboard {...props} />
    </Provider>
  </ApplyTheme>
)
