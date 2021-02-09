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
import {Provider} from 'react-redux'
import I18n from 'i18n!k5_dashboard'
import PropTypes from 'prop-types'
import $ from 'jquery'
import {initializePlanner, responsiviser, store} from '@instructure/canvas-planner'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'

import apiUserContent from 'compiled/str/apiUserContent'
import DashboardTabs, {TAB_IDS} from './DashboardTabs'
import HomeroomPage from './pages/HomeroomPage'
import loadCardDashboard from '../bundles/dashboard_card'
import {showFlashAlert, showFlashError} from '../shared/FlashAlert'
import SchedulePage from 'jsx/dashboard/pages/SchedulePage'
import {theme} from './k5-theme'

const getInitialTab = defaultTab => {
  if (window.location.hash) {
    const newTab = window.location.hash.replace('#', 'tab-')
    if (Object.values(TAB_IDS).includes(newTab)) {
      return newTab
    }
  }
  return defaultTab
}

export const K5Dashboard = ({
  currentUser: {display_name},
  env,
  defaultTab = 'tab-homeroom',
  plannerEnabled = false,
  responsiveSize = 'large'
}) => {
  // This ref is used to pass the current tab to the planner's getActiveApp()
  // function-- we can't use currentTab directly because that gets stuck in
  // a stale closure within the effect where it is referenced.
  const activeTab = useRef()
  // This is the tab we started on when the dashboard is mounted-- either the
  // defaultTab or the tab specified in the URL (so we can go back to it via history)
  const [initialTab] = useState(() => getInitialTab(defaultTab))
  const [currentTab, setCurrentTab] = useState(initialTab)
  const [cards, setCards] = useState(null)
  const [plannerInitialized, setPlannerInitialized] = useState(false)
  const [tabsRef, setTabsRef] = useState(null)

  const handlePopstate = ({state}) => {
    if (state && Object.values(TAB_IDS).includes(state.id)) {
      setCurrentTab(state.id)
    } else {
      setCurrentTab(initialTab)
    }
  }

  useEffect(() => {
    if (plannerEnabled) {
      initializePlanner({
        getActiveApp: () => (activeTab.current === TAB_IDS.SCHEDULE ? 'planner' : ''),
        flashError: message => showFlashAlert({message, type: 'error'}),
        flashMessage: message => showFlashAlert({message, type: 'info'}),
        srFlashMessage: message => showFlashAlert({message, type: 'info', srOnly: true}),
        convertApiUserContent: apiUserContent.convert,
        dateTimeFormatters: {
          dateString: $.dateString,
          timeString: $.timeString,
          datetimeString: $.datetimeString
        },
        externalFallbackFocusable: tabsRef,
        env
      })
        .then(setPlannerInitialized)
        .catch(showFlashError(I18n.t('Failed to load the schedule tab')))
    }
    window.onpopstate = handlePopstate
    return () => (window.onpopstate = undefined)
    // This should only run on mount/unmount, so it shouldn't depend on anything
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  useEffect(() => {
    activeTab.current = currentTab
    if (currentTab === TAB_IDS.HOMEROOM && !cards) {
      loadCardDashboard(setCards)
    }
  }, [cards, currentTab])

  const handleRequestTabChange = id => {
    setCurrentTab(id)
    if (window.history.replaceState) {
      let newUrl = window.location.href
      if (window.location.hash) {
        newUrl = newUrl.replace(window.location.hash, '')
      }
      window.history.replaceState({id}, null, `${newUrl}#${id.replace('tab-', '')}`)
    }
  }

  return (
    <ApplyTheme theme={theme}>
      <Provider store={store}>
        <View as="section">
          <Heading level="h1" margin="medium 0 small 0">
            {I18n.t('Welcome, %{name}!', {name: display_name})}
          </Heading>
          <DashboardTabs
            currentTab={currentTab}
            onRequestTabChange={(_, {id}) => handleRequestTabChange(id)}
            tabsRef={setTabsRef}
          />
          {cards && (
            <HomeroomPage
              cards={cards}
              isStudent={plannerEnabled}
              requestTabChange={handleRequestTabChange}
              responsiveSize={responsiveSize}
              visible={currentTab === TAB_IDS.HOMEROOM}
            />
          )}
          {plannerInitialized && <SchedulePage visible={currentTab === TAB_IDS.SCHEDULE} />}
        </View>
      </Provider>
    </ApplyTheme>
  )
}

K5Dashboard.displayName = 'K5Dashboard'
K5Dashboard.propTypes = {
  currentUser: PropTypes.shape({
    display_name: PropTypes.string
  }).isRequired,
  env: PropTypes.object.isRequired,
  defaultTab: PropTypes.string,
  plannerEnabled: PropTypes.bool,
  responsiveSize: PropTypes.string
}

export default responsiviser()(K5Dashboard)
