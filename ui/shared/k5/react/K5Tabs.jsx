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
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import classnames from 'classnames'
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {getK5ThemeVars} from './k5-theme'

const k5ThemeVariables = getK5ThemeVars()

const I18n = useI18nScope('k5_tabs')

export const scrollElementIntoViewIfCoveredByHeader = tabsRef => e => {
  const elementY = e.target.getBoundingClientRect().y
  const headerHeight = tabsRef.getBoundingClientRect().y + tabsRef.getBoundingClientRect().height
  // If the focused element is positioned higher than the sticky header, scroll the window by
  // the difference in height (plus a little extra for legibility)
  if (headerHeight && elementY && elementY < headerHeight) {
    window.scrollBy(0, elementY - headerHeight - 30)
  }
}

const K5IconTab = ({icon: Icon, label, selected, courseContext}) => (
  <span className={classnames('ic-Dashboard-tabs__tab', {selected})}>
    <Icon />
    {courseContext ? (
      <AccessibleContent alt={I18n.t('%{courseContext} %{label}', {courseContext, label})}>
        {label}
      </AccessibleContent>
    ) : (
      label
    )}
  </span>
)

K5IconTab.propTypes = {
  icon: PropTypes.elementType.isRequired,
  label: PropTypes.string.isRequired,
  selected: PropTypes.bool.isRequired,
  courseContext: PropTypes.string,
}

const K5Tabs = ({children, currentTab, onTabChange, tabs, tabsRef, courseContext}) => {
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
      style={{backgroundColor: k5ThemeVariables.colors.background.backgroundLightest}}
    >
      <View as="div" borderWidth="none none small none">
        {children(sticky)}
        <Tabs
          elementRef={tabsRef}
          onRequestTabChange={(_, {id}) => onTabChange(id)}
          themeOverride={{tabVerticalOffset: '0'}}
        >
          {tabs.map(({id, icon, label}) => (
            <Tabs.Panel
              id={id}
              key={id}
              renderTitle={
                <K5IconTab
                  icon={icon}
                  label={label}
                  selected={currentTab === id}
                  courseContext={courseContext}
                />
              }
              isSelected={currentTab === id}
            >
              <span />
            </Tabs.Panel>
          ))}
        </Tabs>
      </View>
    </div>
  )
}

K5Tabs.propTypes = {
  children: PropTypes.func,
  currentTab: PropTypes.string.isRequired,
  onTabChange: PropTypes.func.isRequired,
  tabs: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      icon: PropTypes.elementType.isRequired,
      label: PropTypes.string.isRequired,
    })
  ).isRequired,
  tabsRef: PropTypes.func,
  courseContext: PropTypes.string,
}

export {K5IconTab}
export default K5Tabs
