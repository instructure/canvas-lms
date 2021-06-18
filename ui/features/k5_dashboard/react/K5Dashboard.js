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
import React, {useCallback, useEffect, useState} from 'react'
import {connect, Provider} from 'react-redux'
import I18n from 'i18n!k5_dashboard'
import PropTypes from 'prop-types'

import {startLoadingAllOpportunities, responsiviser, store} from '@instructure/canvas-planner'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconCheckDarkSolid,
  IconHomeLine,
  IconMoreLine,
  IconStarLightLine
} from '@instructure/ui-icons'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'

import K5Tabs from '@canvas/k5/react/K5Tabs'
import GradesPage from './GradesPage'
import HomeroomPage from './HomeroomPage'
import TodosPage from './TodosPage'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import loadCardDashboard from '@canvas/dashboard-card'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import ResourcesPage from '@canvas/k5/react/ResourcesPage'
import {
  groupAnnouncementsByHomeroom,
  saveElementaryDashboardPreference,
  TAB_IDS
} from '@canvas/k5/react/utils'
import {theme} from '@canvas/k5/react/k5-theme'
import useFetchApi from '@canvas/use-fetch-api-hook'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

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
  },
  {
    id: TAB_IDS.TODO,
    icon: IconCheckDarkSolid,
    label: I18n.t('To Do')
  }
]

const K5DashboardOptionsMenu = ({onDisableK5Dashboard}) => {
  return (
    <Menu
      trigger={
        <Button variant="icon" icon={IconMoreLine} data-testid="k5-dashboard-options">
          <ScreenReaderContent>{I18n.t('Dashboard Options')}</ScreenReaderContent>
        </Button>
      }
    >
      <Menu.Group
        label={I18n.t('Dashboard View')}
        onSelect={onDisableK5Dashboard}
        selected={['elementary']}
      >
        <Menu.Item value="classic">{I18n.t('Classic View')}</Menu.Item>
        <Menu.Item value="elementary">{I18n.t('Elementary View')}</Menu.Item>
      </Menu.Group>
    </Menu>
  )
}

export const K5Dashboard = ({
  assignmentsDueToday,
  assignmentsMissing,
  assignmentsCompletedForToday,
  createPermissions,
  currentUser: {display_name},
  currentUserRoles,
  loadingOpportunities,
  loadAllOpportunities,
  timeZone,
  defaultTab = TAB_IDS.HOMEROOM,
  plannerEnabled = false,
  responsiveSize = 'large'
}) => {
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab, DASHBOARD_TABS)
  const [cards, setCards] = useState(null)
  const [cardsSettled, setCardsSettled] = useState(false)
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])
  const [subjectAnnouncements, setSubjectAnnouncements] = useState([])
  const [loadingAnnouncements, setLoadingAnnouncements] = useState(true)
  const [tabsRef, setTabsRef] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    callback: () => loadAllOpportunities()
  })
  const canDisableElementaryDashboard = currentUserRoles.some(r => ['admin', 'teacher'].includes(r))
  const availableTabs = DASHBOARD_TABS.filter(
    ({id}) => id !== TAB_IDS.TODO || currentUserRoles.includes('teacher')
  )

  useEffect(() => {
    if (!cards && [TAB_IDS.HOMEROOM, TAB_IDS.SCHEDULE, TAB_IDS.RESOURCES].includes(currentTab)) {
      loadCardDashboard((dc, cardsFinishedLoading) => {
        const activeCards = dc.filter(({enrollmentState}) => enrollmentState !== 'invited')
        setCards(activeCards)
        setCardsSettled(cardsFinishedLoading)
        if (cardsFinishedLoading && activeCards?.length === 0) {
          setLoadingAnnouncements(false)
          setHomeroomAnnouncements([])
          setSubjectAnnouncements([])
        }
      })
    }
  }, [cards, currentTab])

  useFetchApi({
    path: '/api/v1/announcements',
    loading: setLoadingAnnouncements,
    success: useCallback(
      data => {
        if (data) {
          const groupedAnnouncements = groupAnnouncementsByHomeroom(data, cards)
          setHomeroomAnnouncements(groupedAnnouncements.true)
          setSubjectAnnouncements(groupedAnnouncements.false)
        }
      },
      [cards]
    ),
    error: useCallback(err => {
      // Don't show an error if user doesn't have permission to read announcements - this is a
      // permission that can be set.
      if (err?.response?.status === 401) {
        return
      }
      showFlashError(I18n.t('Failed to load announcements.'))(err)
    }, []),
    // This is a bit hacky, but we need to wait to fetch the announcements until the cards have
    // settled and there is at least 1 card because the announcements API requires context_codes.
    // Setting forceResult skips the fetch until it changes to undefined.
    forceResult: cardsSettled && cards?.length ? undefined : false,
    fetchAllPages: true,
    params: {
      active_only: true,
      context_codes: cards && cards.map(({id}) => `course_${id}`),
      latest_only: true,
      per_page: '100'
    }
  })

  const handleDisableK5Dashboard = (e, [newView]) => {
    if (newView === 'classic') {
      saveElementaryDashboardPreference(true)
        .then(() => window.location.reload())
        .catch(showFlashError(I18n.t('Failed to opt-out of the Canvas for Elementary dashboard')))
    }
  }

  const renderDashboardHeader = sticky => (
    <Flex as="section">
      <Flex.Item shouldGrow>
        <Heading as="h1" level={sticky ? 'h2' : 'h1'} margin="medium 0 small 0">
          {I18n.t('Welcome, %{name}!', {name: display_name})}
        </Heading>
      </Flex.Item>
      {canDisableElementaryDashboard && (
        <Flex.Item>
          <K5DashboardOptionsMenu onDisableK5Dashboard={handleDisableK5Dashboard} />
        </Flex.Item>
      )}
    </Flex>
  )

  return (
    <View as="section">
      <K5DashboardContext.Provider
        value={{
          assignmentsDueToday,
          assignmentsMissing,
          assignmentsCompletedForToday,
          loadingAnnouncements,
          loadingOpportunities,
          isStudent: plannerEnabled,
          responsiveSize,
          subjectAnnouncements
        }}
      >
        {currentTab && (
          <K5Tabs
            currentTab={currentTab}
            onTabChange={handleTabChange}
            tabs={availableTabs}
            tabsRef={setTabsRef}
          >
            {renderDashboardHeader}
          </K5Tabs>
        )}
        <HomeroomPage
          cards={cards}
          createPermissions={createPermissions}
          homeroomAnnouncements={homeroomAnnouncements}
          loadingAnnouncements={loadingAnnouncements}
          visible={currentTab === TAB_IDS.HOMEROOM}
        />
        <SchedulePage
          plannerEnabled={plannerEnabled}
          plannerInitialized={plannerInitialized}
          timeZone={timeZone}
          userHasEnrollments={!!cards?.length}
          visible={currentTab === TAB_IDS.SCHEDULE}
        />
        <GradesPage visible={currentTab === TAB_IDS.GRADES} currentUserRoles={currentUserRoles} />
        {cards && (
          <ResourcesPage
            cards={cards}
            cardsSettled={cardsSettled}
            visible={currentTab === TAB_IDS.RESOURCES}
            showStaff
            filterToHomerooms
          />
        )}
        {currentUserRoles.includes('teacher') && (
          <TodosPage timeZone={timeZone} visible={currentTab === TAB_IDS.TODO} />
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
  createPermissions: PropTypes.oneOf(['admin', 'teacher', 'none']).isRequired,
  currentUser: PropTypes.shape({
    display_name: PropTypes.string
  }).isRequired,
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired,
  loadingOpportunities: PropTypes.bool.isRequired,
  loadAllOpportunities: PropTypes.func.isRequired,
  timeZone: PropTypes.string.isRequired,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  responsiveSize: PropTypes.string
}

const mapDispatchToProps = {
  loadAllOpportunities: startLoadingAllOpportunities
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
