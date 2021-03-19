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
import classnames from 'classnames'
import I18n from 'i18n!dashboard'
import {Heading} from '@instructure/ui-heading'
import {
  IconBankLine,
  IconCalendarMonthLine,
  IconHomeLine,
  IconStarLightLine
} from '@instructure/ui-icons'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'

import k5Theme from 'jsx/dashboard/k5-theme'

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

const DashboardTabs = ({currentTab, name, onRequestTabChange, tabsRef}) => {
  const [sticky, setSticky] = useState(false)
  const containerRef = useRef(null)
  useEffect(() => {
    // Need to copy the value of containerRef on mount so it will still be
    // available when the cleanup function runs.
    const cachedRef = containerRef.current
    // This IntersectionObserver will let us know when position: sticky has kicked in
    // on the tabs. See https://developers.google.com/web/updates/2017/09/sticky-headers
    const observer = new IntersectionObserver(
      ([e]) => {
        setSticky(e.intersectionRatio < 1)
      },
      {threshold: [1]}
    )
    observer.observe(cachedRef)
    return () => observer.unobserve(cachedRef)
  }, [])

  return (
    <div
      className="ic-Dashboard-tabs"
      ref={containerRef}
      style={{backgroundColor: k5Theme.variables.colors.background.backgroundLightest}}
    >
      <View as="div" padding="medium 0 0 0" borderWidth="none none small none">
        <Heading as="h1" level={sticky ? 'h2' : 'h1'} margin="0 0 small 0">
          {I18n.t('Welcome, %{name}!', {name})}
        </Heading>
        <Tabs
          elementRef={tabsRef}
          onRequestTabChange={onRequestTabChange}
          theme={{tabVerticalOffset: '0'}}
        >
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
      </View>
    </div>
  )
}

DashboardTabs.propTypes = {
  currentTab: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  onRequestTabChange: PropTypes.func.isRequired,
  tabsRef: PropTypes.func
}

export {DashboardIconTab}
export default DashboardTabs
