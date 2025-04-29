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

import React, {useState, useEffect, useMemo, RefCallback} from 'react'
import {Tabs} from '@instructure/ui-tabs'

interface TabItem {
  id: string
  title: string
  contentMount: string
}

interface SettingsTabsProps {
  tabs: TabItem[]
}

export default function SettingsTabs({tabs = []}: SettingsTabsProps): JSX.Element {
  const initialTab = window.location.hash.slice(1).replace(/^tab-/, '') || tabs[0]?.id || ''

  const [selectedTab, setSelectedTab] = useState<string>(initialTab)

  const nodes = useMemo<Record<string, HTMLElement | null>>(() => {
    const m: Record<string, HTMLElement | null> = {}
    tabs.forEach(t => {
      m[t.id] = document.getElementById(t.contentMount)
    })
    return m
  }, [tabs])

  const handleTabChange = (
    _event: React.MouseEvent<any> | React.KeyboardEvent<any>,
    tabData: {index: number; id?: string},
  ): void => {
    const newId = tabs[tabData.index].id
    if (newId !== selectedTab) {
      window.history.pushState(null, '', `#tab-${newId}`)
      setSelectedTab(newId)
    }
  }

  useEffect(() => {
    const onHashChange = () => {
      const h = window.location.hash.slice(1).replace(/^tab-/, '')
      if (tabs.some(t => t.id === h)) {
        setSelectedTab(h)
      }
    }
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [tabs])

  return (
    <Tabs value={selectedTab} onRequestTabChange={handleTabChange}>
      {tabs.map(t => (
        <Tabs.Panel
          id={selectedTab === t.id ? `${t.id}-selected` : t.id}
          style={{display: selectedTab === t.id ? 'block' : 'none'}}
          key={t.id}
          value={t.id}
          renderTitle={() => t.title}
          isSelected={selectedTab === t.id}
        >
          <div
            ref={
              ((container: HTMLDivElement | null) => {
                const node = nodes?.[t.id]
                if (!container || !node) return
                container.innerHTML = ''
                container.appendChild(node)
              }) as RefCallback<HTMLDivElement>
            }
          />
        </Tabs.Panel>
      ))}
    </Tabs>
  )
}
