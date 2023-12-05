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

import React, {useState, useMemo, useRef, useCallback} from 'react'
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
import type {AssigneeOption} from './AssigneeSelector'
import type {SettingsPanelState} from './settingsReducer'
import {createModule, updateModule} from './SettingsPanel'
import {type OptionValue, updateModuleAssignees} from './AssignToPanel'

const I18n = useI18nScope('differentiated_modules')

const SETTINGS_ID = 'settings'
const ASSIGN_TO_ID = 'assign-to'

type DifferentiatedModulesTrayTabId = typeof SETTINGS_ID | typeof ASSIGN_TO_ID

export type DifferentiatedModulesTrayProps = {
  onDismiss: () => void
  moduleElement: HTMLDivElement
  moduleId?: string
  initialTab?: DifferentiatedModulesTrayTabId
  moduleName?: string
  unlockAt?: string
  prerequisites?: Module[]
  moduleList?: Module[]
  courseId: string
  addModuleUI?: (data: Record<string, any>, element: HTMLDivElement) => void
}

const SettingsPanel = React.lazy(() => import('./SettingsPanel'))
const AssignToPanel = React.lazy(() => import('./AssignToPanel'))

function Header({
  moduleId,
  moduleElement,
  onDismiss,
  headerLabel,
}: {
  moduleId?: string
  moduleElement: HTMLDivElement
  onDismiss: () => void
  headerLabel: String
}) {
  const customOnDismiss = useCallback(() => {
    if (!moduleId) {
      // remove the temp module element on cancel
      moduleElement?.remove()
    }
    onDismiss()
  }, [moduleId, moduleElement, onDismiss])
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

function Body({
  onDismiss,
  moduleElement,
  moduleId,
  initialTab = ASSIGN_TO_ID,
  courseId,
  trayRef,
  ...settingsProps
}: DifferentiatedModulesTrayProps & {trayRef: React.RefObject<HTMLElement>}) {
  const [selectedTab, setSelectedTab] = useState<string | undefined>(initialTab)
  const changes = useRef<Set<string>>(new Set())
  const settingsData = useRef<SettingsPanelState | null>(null)
  const assignToData = useRef<{
    selectedOption: OptionValue
    selectedAssignees: AssigneeOption[]
  } | null>(null)

  const footerHeight = '63'
  const panelHeight = useMemo(
    (): string => calculatePanelHeight(moduleId !== undefined),
    [moduleId]
  )
  const bodyHeight = useMemo(
    (): string => `calc(${panelHeight} - ${footerHeight}px)`,
    [panelHeight]
  )

  const handleSubmitMissingTabs = () => {
    if (
      selectedTab === SETTINGS_ID &&
      changes.current.has(ASSIGN_TO_ID) &&
      assignToData.current &&
      moduleId
    ) {
      // eslint-disable-next-line promise/catch-or-return
      updateModuleAssignees({
        courseId,
        moduleId,
        moduleElement,
        selectedAssignees: assignToData.current?.selectedAssignees,
      }).finally(onDismiss)
    } else if (
      selectedTab === ASSIGN_TO_ID &&
      changes.current.has(SETTINGS_ID) &&
      settingsData.current
    ) {
      const performRequest = moduleId === undefined ? createModule : updateModule
      // eslint-disable-next-line promise/catch-or-return
      performRequest({
        moduleId,
        moduleElement,
        addModuleUI: settingsProps.addModuleUI,
        data: settingsData.current,
      }).finally(onDismiss)
    } else {
      onDismiss()
    }
  }

  return (
    <React.Suspense fallback={<Fallback />}>
      {moduleId === undefined ? (
        <SettingsPanel
          bodyHeight={bodyHeight}
          footerHeight={footerHeight}
          onDismiss={onDismiss}
          moduleElement={moduleElement}
          enablePublishFinalGrade={ENV?.PUBLISH_FINAL_GRADE}
          mountNodeRef={trayRef}
          updateParentData={newSettingsData => (settingsData.current = newSettingsData)}
          onDidSubmit={onDismiss}
          {...settingsProps}
          {...(settingsData.current ?? {})}
        />
      ) : (
        <Tabs onRequestTabChange={(_e: any, {id}: {id?: string}) => setSelectedTab(id)}>
          <Tabs.Panel
            id={SETTINGS_ID}
            data-testid="settings-panel"
            renderTitle={I18n.t('Settings')}
            isSelected={selectedTab === SETTINGS_ID}
            padding="none"
          >
            <SettingsPanel
              bodyHeight={bodyHeight}
              footerHeight={footerHeight}
              onDismiss={onDismiss}
              moduleElement={moduleElement}
              moduleId={moduleId}
              enablePublishFinalGrade={ENV?.PUBLISH_FINAL_GRADE}
              mountNodeRef={trayRef}
              updateParentData={(newSettingsData, changed) => {
                settingsData.current = newSettingsData
                changed && changes.current.add(SETTINGS_ID)
              }}
              onDidSubmit={handleSubmitMissingTabs}
              {...settingsProps}
              {...(settingsData.current ?? {})}
            />
          </Tabs.Panel>
          <Tabs.Panel
            id={ASSIGN_TO_ID}
            data-testid="assign-to-panel"
            renderTitle={I18n.t('Assign To')}
            isSelected={selectedTab === ASSIGN_TO_ID}
            padding="none"
          >
            <AssignToPanel
              bodyHeight={bodyHeight}
              footerHeight={footerHeight}
              courseId={courseId}
              moduleId={moduleId}
              mountNodeRef={trayRef}
              moduleElement={moduleElement}
              onDismiss={onDismiss}
              updateParentData={(newAssignToData, changed) => {
                assignToData.current = newAssignToData
                changed && changes.current.add(ASSIGN_TO_ID)
              }}
              defaultOption={assignToData.current?.selectedOption}
              defaultAssignees={assignToData.current?.selectedAssignees}
              onDidSubmit={handleSubmitMissingTabs}
            />
          </Tabs.Panel>
        </Tabs>
      )}
    </React.Suspense>
  )
}

export default function DifferentiatedModulesTray(props: DifferentiatedModulesTrayProps) {
  const {onDismiss, moduleElement, moduleId} = props
  const headerLabel = moduleId ? I18n.t('Edit Module Settings') : I18n.t('Add Module')
  const trayRef = useRef<HTMLElement | null>(null)

  return (
    <Tray
      open={true}
      label={headerLabel}
      placement="end"
      size="regular"
      contentRef={r => (trayRef.current = r)}
    >
      <Header
        moduleId={moduleId}
        moduleElement={moduleElement}
        onDismiss={onDismiss}
        headerLabel={headerLabel}
      />
      <Body {...props} trayRef={trayRef} />
    </Tray>
  )
}
