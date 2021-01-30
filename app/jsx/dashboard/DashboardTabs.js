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

import React from 'react'
import PropTypes from 'prop-types'
import classnames from 'classnames'
import I18n from 'i18n!dashboard'
import {Tabs} from '@instructure/ui-tabs'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconHomeLine,
  IconStarLightLine
} from '@instructure/ui-icons'

export const TAB_IDS = {
  HOMEROOM: 'tab-homeroom',
  SCHEDULE: 'tab-schedule',
  GRADES: 'tab-grades',
  RESOURCES: 'tab-resources'
}

const TABS = {
  [TAB_IDS.HOMEROOM]: {
    icon: IconHomeLine,
    label: I18n.t('Homeroom')
  },
  [TAB_IDS.SCHEDULE]: {
    icon: IconCalendarMonthLine,
    label: I18n.t('Schedule')
  },
  [TAB_IDS.GRADES]: {
    icon: IconStarLightLine,
    label: I18n.t('Grades')
  },
  [TAB_IDS.RESOURCES]: {
    icon: IconBankLine,
    label: I18n.t('Resources')
  }
}

const DashboardIconTab = ({icon: Icon, label, selected}) => (
  <span className={classnames('ic-Dashboard-tabs__tab', {selected})}>
    <Icon />
    {label}
  </span>
)

DashboardIconTab.propTypes = {
  icon: PropTypes.elementType.isRequired,
  label: PropTypes.string.isRequired,
  selected: PropTypes.bool.isRequired
}

const DashboardTabs = ({currentTab, onRequestTabChange, tabsRef}) => {
  return (
    <div className="ic-Dashboard-tabs">
      <Tabs elementRef={tabsRef} onRequestTabChange={onRequestTabChange} tabOverflow="scroll">
        {Object.keys(TABS).map(id => (
          <Tabs.Panel
            id={id}
            key={id}
            renderTitle={
              <DashboardIconTab
                icon={TABS[id].icon}
                label={TABS[id].label}
                selected={currentTab === id}
              />
            }
            selected={currentTab === id}
          >
            <span />
          </Tabs.Panel>
        ))}
      </Tabs>
    </div>
  )
}

DashboardTabs.propTypes = {
  currentTab: PropTypes.string.isRequired,
  onRequestTabChange: PropTypes.func.isRequired,
  tabsRef: PropTypes.func
}

export {DashboardIconTab}
export default DashboardTabs
