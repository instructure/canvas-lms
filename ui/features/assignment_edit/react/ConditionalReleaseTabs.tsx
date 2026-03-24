/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {forwardRef, useCallback, useEffect, useImperativeHandle, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tabs} from '@instructure/ui-tabs'

const I18n = createI18nScope('assignmentsEditHeaderView')

const PANEL_IDS = ['edit_assignment_wrapper', 'mastery-paths-editor'] as const

export interface ConditionalReleaseTabsHandle {
  setActiveIndex: (index: number) => void
  setDisabledIndices: (indices: number[]) => void
}

interface ConditionalReleaseTabsProps {
  onTabChange: () => void
}

function syncPanelVisibility(activeIndex: number) {
  PANEL_IDS.forEach((id, i) => {
    const el = document.getElementById(id)
    if (el) {
      el.style.display = i === activeIndex ? '' : 'none'
    }
  })
}

const ConditionalReleaseTabs = forwardRef<
  ConditionalReleaseTabsHandle,
  ConditionalReleaseTabsProps
>(function ConditionalReleaseTabs({onTabChange}, ref) {
  const [selectedIndex, setSelectedIndex] = useState(0)
  const [disabledIndices, setDisabledIndices] = useState<Array<number>>([])

  useEffect(() => {
    syncPanelVisibility(selectedIndex)
  }, [selectedIndex])

  useImperativeHandle(
    ref,
    () => ({
      setActiveIndex(index: number) {
        setSelectedIndex(index)
      },
      setDisabledIndices(indices: number[]) {
        setDisabledIndices(indices)
      },
    }),
    [],
  )

  const handleTabChange = useCallback(
    (_event: unknown, {index}: {index: number}) => {
      if (!disabledIndices.includes(index)) {
        setSelectedIndex(index)
        onTabChange()
      }
    },
    [disabledIndices, onTabChange],
  )

  return (
    <Tabs onRequestTabChange={handleTabChange}>
      <Tabs.Panel
        id="details-tab-panel"
        renderTitle={I18n.t('Details')}
        isSelected={selectedIndex === 0}
        isDisabled={disabledIndices.includes(0)}
      >
        {/* Content managed externally via #edit_assignment_wrapper */}
      </Tabs.Panel>
      <Tabs.Panel
        id="mastery-paths-tab-panel"
        renderTitle={I18n.t('Mastery Paths')}
        isSelected={selectedIndex === 1}
        isDisabled={disabledIndices.includes(1)}
      >
        {/* Content managed externally via #mastery-paths-editor */}
      </Tabs.Panel>
    </Tabs>
  )
})

export default ConditionalReleaseTabs
