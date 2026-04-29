/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import type {DashboardTab, TabId} from '../types'
import {TAB_IDS} from '../constants'
import {useTabState} from '../hooks/useTabState'
import {useWidgetDashboard} from '../hooks/useWidgetDashboardContext'
import DashboardTabContent from './DashboardTab'
import CoursesTab from './CoursesTab'

const I18n = createI18nScope('widget_dashboard')

const DASHBOARD_TABS: DashboardTab[] = [
  {
    id: TAB_IDS.DASHBOARD,
    label: I18n.t('Dashboard'),
  },
  {
    id: TAB_IDS.COURSES,
    label: I18n.t('Courses'),
  },
]

const DashboardTabs: React.FC = () => {
  const {preferences} = useWidgetDashboard()
  const {currentTab, handleTabChange} = useTabState(
    preferences?.learner_dashboard_tab_selection || TAB_IDS.DASHBOARD,
  )

  const handleTabSelect = (_event: any, tabData: {index: number; id?: string}) => {
    if (tabData.id) {
      handleTabChange(tabData.id as TabId)
    }
  }

  const renderTabContent = (tabId: TabId) => {
    switch (tabId) {
      case TAB_IDS.DASHBOARD:
        return <DashboardTabContent />
      case TAB_IDS.COURSES:
        return <CoursesTab />
      default:
        return null
    }
  }

  const renderTabTitle = (tabId: string, label: string) => (
    <span data-testid={`tab-${tabId}`}>{label}</span>
  )

  return (
    <View as="div" data-testid="dashboard-tabs">
      <Tabs onRequestTabChange={handleTabSelect}>
        {DASHBOARD_TABS.map(tab => (
          <Tabs.Panel
            key={tab.id}
            id={tab.id}
            renderTitle={renderTabTitle(tab.id, tab.label)}
            isSelected={currentTab === tab.id}
          >
            {renderTabContent(tab.id)}
          </Tabs.Panel>
        ))}
      </Tabs>
    </View>
  )
}

export default DashboardTabs
