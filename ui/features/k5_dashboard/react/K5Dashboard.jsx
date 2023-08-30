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
import React, {useCallback, useEffect, useState, useLayoutEffect} from 'react'
import {connect, Provider} from 'react-redux'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'

import {responsiviser, store} from '@canvas/planner'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconCheckDarkSolid,
  IconHomeLine,
  IconMoreLine,
  IconStarLightLine,
  IconCalendarReservedLine,
} from '@instructure/ui-icons'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Menu} from '@instructure/ui-menu'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'

import K5Tabs, {scrollElementIntoViewIfCoveredByHeader} from '@canvas/k5/react/K5Tabs'
import {GradesPage} from './GradesPage'
import HomeroomPage from './HomeroomPage'
import {TodosPage} from './TodosPage'
import K5DashboardContext from '@canvas/k5/react/K5DashboardContext'
import {CardDashboardLoader} from '@canvas/dashboard-card'
import {mapStateToProps} from '@canvas/k5/redux/redux-helpers'
import SchedulePage from '@canvas/k5/react/SchedulePage'
import ResourcesPage from '@canvas/k5/react/ResourcesPage'
import {
  groupAnnouncementsByHomeroom,
  saveElementaryDashboardPreference,
  TAB_IDS,
  MOBILE_NAV_BREAKPOINT_PX,
} from '@canvas/k5/react/utils'
import {getK5ThemeOverrides} from '@canvas/k5/react/k5-theme'
import useFetchApi from '@canvas/use-fetch-api-hook'
import usePlanner from '@canvas/k5/react/hooks/usePlanner'
import useTabState from '@canvas/k5/react/hooks/useTabState'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import ImportantDates from './ImportantDates'
import ObserverOptions, {ObservedUsersListShape} from '@canvas/observer-picker'
import {savedObservedId} from '@canvas/observer-picker/ObserverGetObservee'
import {fetchShowK5Dashboard} from '@canvas/observer-picker/react/utils'

const componentOverrides = getK5ThemeOverrides()

const I18n = useI18nScope('k5_dashboard')

const DASHBOARD_TABS = [
  {
    id: TAB_IDS.HOMEROOM,
    icon: IconHomeLine,
    label: I18n.t('Homeroom'),
  },
  {
    id: TAB_IDS.SCHEDULE,
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule'),
  },
  {
    id: TAB_IDS.GRADES,
    icon: IconStarLightLine,
    label: I18n.t('Grades'),
  },
  {
    id: TAB_IDS.RESOURCES,
    icon: IconBankLine,
    label: I18n.t('Resources'),
  },
  {
    id: TAB_IDS.TODO,
    icon: IconCheckDarkSolid,
    label: I18n.t('To Do'),
  },
]

const K5DashboardOptionsMenu = ({onDisableK5Dashboard}) => {
  return (
    <Menu
      trigger={
        <IconButton
          renderIcon={IconMoreLine}
          withBackground={false}
          withBorder={false}
          data-testid="k5-dashboard-options"
          screenReaderLabel={I18n.t('Dashboard Options')}
        />
      }
    >
      <Menu.Group
        label={I18n.t('Dashboard View')}
        onSelect={onDisableK5Dashboard}
        selected={['elementary']}
      >
        <Menu.Item value="classic">{I18n.t('Classic View')}</Menu.Item>
        <Menu.Item value="elementary">{I18n.t('Homeroom View')}</Menu.Item>
      </Menu.Group>
    </Menu>
  )
}

const toRenderTabs = (currentUserRoles, hideGradesTabForStudents, selectedSelfUser) =>
  DASHBOARD_TABS.filter(({id}) => {
    switch (id) {
      case TAB_IDS.TODO:
        return currentUserRoles.includes('teacher')
      case TAB_IDS.GRADES:
        return (
          currentUserRoles.includes('teacher') ||
          currentUserRoles.includes('admin') ||
          (currentUserRoles.includes('student') && !hideGradesTabForStudents) ||
          (currentUserRoles.includes('observer') && !selectedSelfUser)
        )
      default:
        return true
    }
  })

const getWindowSize = () => ({
  width: window.innerWidth,
  height: window.innerHeight,
})

const K5Dashboard = ({
  assignmentsDueToday,
  assignmentsMissing,
  assignmentsCompletedForToday,
  createPermission,
  restrictCourseCreation,
  currentUser,
  currentUserRoles,
  timeZone,
  defaultTab = TAB_IDS.HOMEROOM,
  plannerEnabled = false,
  responsiveSize = 'large',
  hideGradesTabForStudents = false,
  selectedContextCodes,
  selectedContextsLimit,
  observedUsersList,
  canAddObservee,
  openTodosInNewTab,
  loadingOpportunities,
  accountCalendarContexts,
}) => {
  const initialObservedId = observedUsersList.find(o => o.id === savedObservedId(currentUser.id))
    ? savedObservedId(currentUser.id)
    : undefined
  const [observedUserId, setObservedUserId] = useState(initialObservedId)
  const observerMode = currentUserRoles.includes('observer')
  const selectedSelfUser = observerMode && currentUser.id === observedUserId

  const availableTabs = toRenderTabs(currentUserRoles, hideGradesTabForStudents, selectedSelfUser)
  const {activeTab, currentTab, handleTabChange} = useTabState(defaultTab, availableTabs)
  const [cards, setCards] = useState(null)
  const [cardsSettled, setCardsSettled] = useState(false)
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([])
  const [subjectAnnouncements, setSubjectAnnouncements] = useState([])
  const [loadingAnnouncements, setLoadingAnnouncements] = useState(true)
  const [tabsRef, setTabsRef] = useState(null)
  const [trayOpen, setTrayOpen] = useState(false)
  const [, setCardDashboardLoader] = useState(null)
  const plannerInitialized = usePlanner({
    plannerEnabled,
    isPlannerActive: () => activeTab.current === TAB_IDS.SCHEDULE,
    focusFallback: tabsRef,
    observedUserId: initialObservedId,
    isObserver: currentUserRoles.includes('observer'),
  })
  const canDisableElementaryDashboard =
    currentUserRoles.some(r => ['admin', 'teacher'].includes(r)) &&
    (!observerMode || observedUserId === currentUser.id)
  const useImportantDatesTray = responsiveSize !== 'large'

  const [windowSize, setWindowSize] = useState(() => getWindowSize())
  useLayoutEffect(() => {
    const updateWindowSize = () => setWindowSize(getWindowSize())
    window.addEventListener('resize', updateWindowSize)
    return () => window.removeEventListener('resize', updateWindowSize)
  }, [])
  const showingMobileNav = windowSize.width < MOBILE_NAV_BREAKPOINT_PX

  // If the view width increases while the tray is open, change the state to close the tray
  if (trayOpen && !useImportantDatesTray) {
    setTrayOpen(false)
  }

  const loadCardDashboardCallBack = (dc, cardsFinishedLoading) => {
    const activeCards = dc.filter(({enrollmentState}) => enrollmentState !== 'invited')
    setCards(activeCards)
    if (cardsFinishedLoading) {
      setCardsSettled(true)
    }
    if (cardsFinishedLoading && activeCards?.length === 0) {
      setLoadingAnnouncements(false)
      setHomeroomAnnouncements([])
      setSubjectAnnouncements([])
    }
  }

  const updateDashboardForObserverCallback = id => {
    setCardDashboardLoader(null)
    setCardsSettled(false)
    setObservedUserId(id)
  }

  const handleChangeObservedUser = id => {
    if (id !== observedUserId) {
      fetchShowK5Dashboard(id)
        .then(response => {
          if (response.show_k5_dashboard && response.use_classic_font === ENV.USE_CLASSIC_FONT) {
            updateDashboardForObserverCallback(id)
          } else {
            window.location.reload()
          }
        })
        .catch(err => showFlashError(I18n.t('Unable to switch students'))(err))
    }
  }

  useEffect(() => {
    // don't call on the initial load when we know we're in observer mode but don't have the ID yet
    if (!observerMode || (observerMode && observedUserId)) {
      const dcl = new CardDashboardLoader()
      dcl.loadCardDashboard(loadCardDashboardCallBack, observerMode ? observedUserId : undefined)
      setCardDashboardLoader(dcl)
    }
  }, [observedUserId, observerMode])

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
      per_page: '100',
    },
  })

  const handleDisableK5Dashboard = (e, [newView]) => {
    if (newView === 'classic') {
      saveElementaryDashboardPreference(true)
        .then(() => window.location.reload())
        .catch(showFlashError(I18n.t('Failed to opt-out of the Canvas for Elementary dashboard')))
    }
  }

  const renderDashboardHeader = sticky => {
    const showingAdditionalOptions =
      useImportantDatesTray || canDisableElementaryDashboard || observerMode
    const placeAdditionalOptionsAbove = observerMode && showingMobileNav
    const additionalOptions = (
      <>
        {observerMode && (
          <Flex.Item
            as="div"
            size={placeAdditionalOptionsAbove ? undefined : '16em'}
            shouldGrow={placeAdditionalOptionsAbove}
            margin="0 x-small 0 0"
          >
            <ObserverOptions
              observedUsersList={observedUsersList}
              currentUser={currentUser}
              handleChangeObservedUser={handleChangeObservedUser}
              canAddObservee={canAddObservee}
              currentUserRoles={currentUserRoles}
            />
          </Flex.Item>
        )}
        {useImportantDatesTray && (
          <Flex.Item>
            <IconButton
              screenReaderLabel={I18n.t('View Important Dates')}
              onClick={() => setTrayOpen(true)}
              renderIcon={IconCalendarReservedLine}
              withBackground={false}
              withBorder={false}
            />
          </Flex.Item>
        )}
        {canDisableElementaryDashboard && (
          <Flex.Item>
            <K5DashboardOptionsMenu onDisableK5Dashboard={handleDisableK5Dashboard} />
          </Flex.Item>
        )}
      </>
    )
    const welcomeMessage = I18n.t('Welcome, %{name}!', {name: currentUser.display_name})
    return (
      <View as="div" margin={`medium 0 ${sticky && showingAdditionalOptions ? '0' : 'small'} 0`}>
        {placeAdditionalOptionsAbove && (
          <Flex margin={`0 0 ${sticky ? 'small' : 'medium'} 0`}>
            {/* place the Welcome... heading above the observer picker when necessary (observer mode with mobile view) */}
            <ScreenReaderContent>
              <Heading as="span" level="h1">
                {welcomeMessage}
              </Heading>
            </ScreenReaderContent>
            {additionalOptions}
          </Flex>
        )}
        <Flex alignItems="center">
          <Flex.Item shouldGrow={true} shouldShrink={true} margin="0 small 0 0">
            <Heading
              as="span"
              aria-hidden={placeAdditionalOptionsAbove}
              level={sticky ? 'h2' : 'h1'}
            >
              {welcomeMessage}
            </Heading>
          </Flex.Item>
          {!placeAdditionalOptionsAbove && additionalOptions}
        </Flex>
      </View>
    )
  }

  const importantDatesContexts = cards
    ?.filter(c => c.isK5Subject || c.isHomeroom)
    .map(c => ({assetString: c.assetString, color: c.color, name: c.shortName}))
    .concat(
      accountCalendarContexts.map(c => ({
        assetString: c.asset_string,
        name: c.name,
      }))
    )

  const importantDates = (
    <ImportantDates
      timeZone={timeZone}
      contexts={importantDatesContexts}
      handleClose={useImportantDatesTray ? () => setTrayOpen(false) : undefined}
      selectedContextCodes={selectedContextCodes}
      selectedContextsLimit={selectedContextsLimit}
      observedUserId={observedUserId}
    />
  )

  return (
    <>
      <Flex as="section" alignItems="start">
        <Flex.Item
          shouldGrow={true}
          shouldShrink={true}
          padding="x-small medium medium medium"
          onFocus={scrollElementIntoViewIfCoveredByHeader(tabsRef)}
        >
          <K5DashboardContext.Provider
            value={{
              assignmentsDueToday,
              assignmentsMissing,
              assignmentsCompletedForToday,
              loadingAnnouncements,
              isStudent: plannerEnabled,
              responsiveSize,
              subjectAnnouncements,
              loadingOpportunities,
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
              createPermission={createPermission}
              restrictCourseCreation={restrictCourseCreation}
              homeroomAnnouncements={homeroomAnnouncements}
              loadingAnnouncements={loadingAnnouncements}
              visible={currentTab === TAB_IDS.HOMEROOM}
              loadingCards={!cardsSettled}
            />
            <SchedulePage
              plannerEnabled={plannerEnabled}
              plannerInitialized={plannerInitialized}
              timeZone={timeZone}
              userHasEnrollments={!!cards?.length}
              visible={currentTab === TAB_IDS.SCHEDULE}
              singleCourse={false}
              observedUserId={observedUserId}
            />
            <GradesPage
              visible={currentTab === TAB_IDS.GRADES}
              currentUserRoles={currentUserRoles}
              observedUserId={observerMode ? observedUserId : null}
              currentUser={currentUser}
            />
            {cards && (
              <ResourcesPage
                cards={cards}
                cardsSettled={cardsSettled}
                visible={currentTab === TAB_IDS.RESOURCES}
                showStaff={true}
                isSingleCourse={false}
              />
            )}
            {currentUserRoles.includes('teacher') && (
              <TodosPage
                timeZone={timeZone}
                openTodosInNewTab={openTodosInNewTab}
                visible={currentTab === TAB_IDS.TODO}
              />
            )}
          </K5DashboardContext.Provider>
        </Flex.Item>
        {!useImportantDatesTray && (
          <Flex.Item as="div" size="18rem" id="important-dates-sidebar">
            {importantDates}
          </Flex.Item>
        )}
      </Flex>
      {useImportantDatesTray && (
        <Tray
          label={I18n.t('Important Dates Tray')}
          open={trayOpen}
          placement="end"
          size="large"
          shouldCloseOnDocumentClick={true}
          onDismiss={() => setTrayOpen(false)}
        >
          <div id="important-dates-sidebar">{importantDates}</div>
        </Tray>
      )}
    </>
  )
}

K5Dashboard.displayName = 'K5Dashboard'
K5Dashboard.propTypes = {
  assignmentsDueToday: PropTypes.object.isRequired,
  assignmentsMissing: PropTypes.object.isRequired,
  assignmentsCompletedForToday: PropTypes.object.isRequired,
  loadingOpportunities: PropTypes.bool.isRequired,
  createPermission: PropTypes.oneOf(['admin', 'teacher', 'student', 'no_enrollments']),
  restrictCourseCreation: PropTypes.bool.isRequired,
  currentUser: PropTypes.shape({
    id: PropTypes.string,
    display_name: PropTypes.string,
    avatar_image_url: PropTypes.string,
  }).isRequired,
  currentUserRoles: PropTypes.arrayOf(PropTypes.string).isRequired,
  timeZone: PropTypes.string.isRequired,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  responsiveSize: PropTypes.string,
  hideGradesTabForStudents: PropTypes.bool,
  selectedContextCodes: PropTypes.arrayOf(PropTypes.string),
  selectedContextsLimit: PropTypes.number.isRequired,
  observedUsersList: ObservedUsersListShape.isRequired,
  canAddObservee: PropTypes.bool.isRequired,
  openTodosInNewTab: PropTypes.bool.isRequired,
  accountCalendarContexts: PropTypes.arrayOf(
    PropTypes.shape({
      asset_string: PropTypes.string.isRequired,
      name: PropTypes.string.isRequired,
    })
  ),
}

const WrappedK5Dashboard = connect(mapStateToProps)(responsiviser()(K5Dashboard))

export default props => (
  <InstUISettingsProvider theme={{componentOverrides}}>
    <Provider store={store}>
      <WrappedK5Dashboard {...props} />
    </Provider>
  </InstUISettingsProvider>
)
