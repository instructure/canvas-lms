/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useMemo} from 'react'
import {Tray} from '@instructure/ui-tray'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Spinner} from '@instructure/ui-spinner'
import {Tabs} from '@instructure/ui-tabs'
import {IconModuleSolid} from '@instructure/ui-icons'
import {calculatePanelHeight} from '../utils/miscHelpers'
import type {Module} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface DifferentiatedModulesTrayProps {
  onDismiss: () => void
  moduleElement: HTMLDivElement
  moduleId?: string
  initialTab?: 'settings' | 'assign-to'
  moduleName?: string
  unlockAt?: string
  prerequisites?: Module[]
  moduleList?: Module[]
  courseId: string
  addModuleUI?: (data: Record<string, any>, element: HTMLDivElement) => void
}

const SettingsPanel = React.lazy(() => import('./SettingsPanel'))
const AssignToPanel = React.lazy(() => import('./AssignToPanel'))

export default function DifferentiatedModulesTray({
  onDismiss,
  moduleElement,
  moduleId,
  initialTab = 'assign-to',
  courseId,
  ...settingsProps
}: DifferentiatedModulesTrayProps) {
  const [selectedTab, setSelectedTab] = useState<string | undefined>(initialTab)
  const headerLabel = moduleId ? I18n.t('Edit Module Settings') : I18n.t('Add Module')
  const panelHeight = useMemo(() => calculatePanelHeight(moduleId !== undefined), [moduleId])

  function customOnDismiss() {
    if (!moduleId) {
      // remove the temp module element on cancel
      moduleElement?.remove()
    }
    onDismiss()
  }

  function Header() {
    return (
      <View as="div" padding="small">
        <Flex as="div" margin="0 0 medium 0">
          <Flex.Item>
            <CloseButton
              onClick={customOnDismiss}
              screenReaderLabel={I18n.t('Close')}
              placement="end"
            />
          </Flex.Item>
          <Flex.Item>
            <IconModuleSolid size="x-small" />
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <Heading data-testid="header-label" as="h3">
              {headerLabel}
            </Heading>
          </Flex.Item>
        </Flex>
      </View>
    )
  }

  function Fallback() {
    return (
      <View as="div" textAlign="center">
        <Spinner renderTitle={I18n.t('Loading...')} />
      </View>
    )
  }

  function Body() {
    return (
      <React.Suspense fallback={<Fallback />}>
        {moduleId === undefined ? (
          <SettingsPanel
            height={panelHeight}
            onDismiss={onDismiss}
            moduleElement={moduleElement}
            enablePublishFinalGrade={ENV?.PUBLISH_FINAL_GRADE}
            {...settingsProps}
          />
        ) : (
          <Tabs onRequestTabChange={(_e: any, {id}: {id?: string}) => setSelectedTab(id)}>
            <Tabs.Panel
              id="settings"
              data-testid="settings-panel"
              renderTitle={I18n.t('Settings')}
              isSelected={selectedTab === 'settings'}
              padding="none"
            >
              <SettingsPanel
                height={panelHeight}
                onDismiss={onDismiss}
                moduleElement={moduleElement}
                moduleId={moduleId}
                enablePublishFinalGrade={ENV?.PUBLISH_FINAL_GRADE}
                {...settingsProps}
              />
            </Tabs.Panel>
            <Tabs.Panel
              id="assign-to"
              data-testid="assign-to-panel"
              renderTitle={I18n.t('Assign To')}
              isSelected={selectedTab === 'assign-to'}
              padding="none"
            >
              <AssignToPanel
                courseId={courseId}
                moduleId={moduleId}
                height={panelHeight}
                onDismiss={onDismiss}
              />
            </Tabs.Panel>
          </Tabs>
        )}
      </React.Suspense>
    )
  }

  return (
    <Tray open={true} label={headerLabel} placement="end" size="regular">
      <Header />
      <Body />
    </Tray>
  )
}
