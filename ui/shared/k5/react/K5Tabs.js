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
import {Tabs} from '@instructure/ui-tabs'
import {View} from '@instructure/ui-view'

import k5Theme from './k5-theme'

const K5IconTab = ({icon: Icon, label, selected}) => (
  <span className={classnames('ic-Dashboard-tabs__tab', {selected})}>
    <Icon />
    {label}
  </span>
)

K5IconTab.propTypes = {
  icon: PropTypes.elementType.isRequired,
  label: PropTypes.string.isRequired,
  selected: PropTypes.bool.isRequired
}

const K5Tabs = ({children, currentTab, name, onTabChange, tabs, tabsRef}) => {
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
        {name && (
          <Heading as="h1" level={sticky ? 'h2' : 'h1'} margin="0 0 small 0">
            {I18n.t('Welcome, %{name}!', {name})}
          </Heading>
        )}
        {children}
        <Tabs
          elementRef={tabsRef}
          onRequestTabChange={(_, {id}) => onTabChange(id)}
          theme={{tabVerticalOffset: '0'}}
        >
          {tabs.map(({id, icon, label}) => (
            <Tabs.Panel
              id={id}
              key={id}
              renderTitle={<K5IconTab icon={icon} label={label} selected={currentTab === id} />}
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

K5Tabs.propTypes = {
  children: PropTypes.node,
  currentTab: PropTypes.string.isRequired,
  name: PropTypes.string,
  onTabChange: PropTypes.func.isRequired,
  tabs: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      icon: PropTypes.elementType.isRequired,
      label: PropTypes.string.isRequired
    })
  ).isRequired,
  tabsRef: PropTypes.func
}

export {K5IconTab}
export default K5Tabs
