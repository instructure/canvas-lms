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

import React, {useState, useRef, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  DragDropContext,
  Droppable,
  Draggable,
  DraggableProvided,
  DraggableStateSnapshot,
} from 'react-beautiful-dnd'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Button, IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {
  IconDragHandleLine,
  IconMoreSolid,
  IconXSolid,
  IconPlusSolid,
  IconUpdownLine,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import classnames from 'classnames'
import {Flex} from '@instructure/ui-flex'
import MoveItemTray from '@canvas/move-item-tray/react'
import {EnvCommon} from '@canvas/global/env/EnvCommon'
import {
  useTabListsStore,
  type MoveItemTrayResult,
  type NavigationTab,
} from '../store/useTabListsStore'

const I18n = createI18nScope('course_navigation_settings')

export interface CourseNavigationTabToSave {
  id: number | string
  hidden?: boolean
}

declare const ENV: EnvCommon & {
  COURSE_SETTINGS_NAVIGATION_TABS?: NavigationTab[]
}

/**
 * Navigation settings in Course Settings, where the teacher can reorder the
 * items ("tabs") which display in the Course Nav.
 */
export default function CourseNavigationSettings({
  onSubmit,
}: {
  onSubmit: (tabs: CourseNavigationTabToSave[]) => void
}): JSX.Element {
  const {enabledTabs, disabledTabs, moveTab, toggleTabEnabled, moveUsingTrayResult} =
    useTabListsStore()
  const [isSaving, setIsSaving] = useState(false)
  const [moveTrayItemId, setMoveTrayItemId] = useState<string | undefined>(undefined)
  const tabRefs = useRef<{[key: string]: HTMLDivElement | null}>({})
  const [isDragging, setIsDragging] = useState(false)

  useUpDownKeysChangeFocusHandler({enabledTabs, disabledTabs, isDragging, tabRefs})

  const handleSave = () => {
    setIsSaving(true)
    onSubmit([
      ...enabledTabs.map(tab => ({id: normalizeTabId(tab.id)})),
      ...disabledTabs.map(tab => ({id: normalizeTabId(tab.id), hidden: true})),
    ])
  }

  const renderTab = (tab: NavigationTab, index: number, isEnabled: boolean) => {
    const tabContent = (provided?: DraggableProvided, snapshot?: DraggableStateSnapshot) => (
      <div
        key={`tabdiv-${tab.id}`}
        ref={el => {
          if (provided?.innerRef) provided.innerRef(el)
          tabRefs.current[`tab-${tab.id}`] = el
        }}
        {...(provided?.draggableProps || {})}
        {...(!tab.immovable && provided?.dragHandleProps ? provided.dragHandleProps : {})}
        tabIndex={0}
        role="button"
        className={classnames({
          'course-nav-tab': true,
          'course-nav-tab-first': index === 0,
          'course-nav-tab-dragging': snapshot?.isDragging,
        })}
      >
        <NavItem
          tab={tab}
          isEnabled={isEnabled}
          onToggleEnabled={toggleTabEnabled}
          onMove={setMoveTrayItemId}
        />
      </div>
    )

    return tab.immovable ? (
      tabContent()
    ) : (
      <Draggable key={`tab-${tab.id}`} draggableId={`tab-${tab.id}`} index={index}>
        {tabContent}
      </Draggable>
    )
  }

  const isMoveTrayItemHidden = moveTrayItemId && disabledTabs.find(t => t.id === moveTrayItemId)

  return (
    <>
      {moveTrayItemId && (
        <MoveNavItemTray
          onExited={() => setMoveTrayItemId(undefined)}
          tabId={moveTrayItemId}
          tabsList={isMoveTrayItemHidden ? disabledTabs : enabledTabs}
          onMoveSuccess={moveUsingTrayResult}
        />
      )}

      <DragDropContext
        onDragStart={() => setIsDragging(true)}
        onDragEnd={result => {
          setIsDragging(false)
          moveTab(result)
        }}
      >
        <View as="div" padding="small 0 small 0">
          <Text>
            {ENV.K5_SUBJECT_COURSE
              ? I18n.t(
                  'help.edit_navigation_k5',
                  'Drag and drop items to reorder them in the subject navigation.',
                )
              : I18n.t(
                  'help.edit_navigation',
                  'Drag and drop items to reorder them in the course navigation.',
                )}
          </Text>
        </View>

        <ScreenReaderContent as="h3">{I18n.t('Enabled Links')}</ScreenReaderContent>
        <div>
          <Droppable droppableId="enabled-tabs">
            {(provided, _snapshot) => (
              <View
                elementRef={provided.innerRef}
                {...provided.droppableProps}
                className="course-nav-tabs-list"
              >
                {enabledTabs.map((tab, index) => renderTab(tab, index, true))}
                {provided.placeholder}
              </View>
            )}
          </Droppable>
        </div>

        <ScreenReaderContent as="h3">{I18n.t('Disabled Links')}</ScreenReaderContent>
        <div>
          <Droppable droppableId="disabled-tabs">
            {(provided, _snapshot) => (
              <View
                elementRef={provided.innerRef}
                {...provided.droppableProps}
                className="course-nav-tabs-list"
              >
                <View as="div" padding="medium 0 medium 0">
                  <Text>
                    {I18n.t('drag_to_hide', 'Drag items here to hide them from students.')}
                  </Text>
                  <View as="div">
                    <Text size="small">
                      {I18n.t(
                        'drag_details',
                        'Disabling most pages will cause students who visit those pages to be redirected to the course home page.',
                      )}
                    </Text>
                  </View>
                </View>
                {disabledTabs.map((tab, index) => renderTab(tab, index, false))}
                {provided.placeholder}
              </View>
            )}
          </Droppable>
        </div>

        <View as="div" margin="medium 0 0 0">
          <Button type="button" color="primary" onClick={handleSave} disabled={isSaving}>
            {isSaving ? I18n.t('Saving...') : I18n.t('buttons.save', 'Save')}
          </Button>
        </View>
      </DragDropContext>
    </>
  )
}

// The update_nav requires numeric IDs to of type number, not string, in the
// request JSON
function normalizeTabId(id: string): number | string {
  const idStr = String(id)
  return /^\d+$/.test(idStr) ? parseInt(idStr, 10) : idStr
}

/**
 * Item in the list of Course Nav tabs, with drag handle, label, and settings menu.
 */
const NavItem = React.memo(
  ({
    tab,
    isEnabled,
    onToggleEnabled,
    onMove,
  }: {
    tab: NavigationTab
    isEnabled: boolean
    onToggleEnabled: (tabId: string) => void
    onMove: (tabId: string) => void
  }) => {
    return (
      <View
        id={`nav_edit_tab_id_${tab.id}`}
        aria-label={tab.label}
        cursor={tab.immovable ? 'default' : 'grab'}
      >
        <Flex padding="xxx-small">
          <View as="div" padding="small" margin="0 medium 0 0" width="1.5rem" minWidth="1.5rem">
            {tab.immovable ? <span>&nbsp;</span> : <IconDragHandleLine size="x-small" />}
          </View>
          <View as="div" display="inline-block" padding="small 0" margin="0 auto 0 0">
            <Text>{tab.label}</Text>
            {!isEnabled && tab.disabled_message && (
              <View as="div">
                <Text size="small" fontStyle="italic">
                  {tab.disabled_message}
                </Text>
              </View>
            )}
          </View>
          {!tab.immovable && (
            <Menu
              trigger={
                <IconButton
                  screenReaderLabel={I18n.t('Settings for %{tabLabel}', {tabLabel: tab.label})}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  onKeyDown={e => {
                    if (e.key === ' ') {
                      // make space work to open menu
                      e.stopPropagation()
                    }
                  }}
                >
                  <IconMoreSolid />
                </IconButton>
              }
              placement="bottom"
              shouldHideOnSelect={true}
            >
              <Menu.Item onClick={() => onToggleEnabled(tab.id)} type="button">
                <Flex>
                  <Flex.Item padding="0 x-small 0 0" margin="0 0 xxx-small 0">
                    {isEnabled ? <IconXSolid /> : <IconPlusSolid />}
                  </Flex.Item>
                  <Flex.Item>{isEnabled ? I18n.t('Disable') : I18n.t('Enable')}</Flex.Item>
                </Flex>
              </Menu.Item>
              <Menu.Item onClick={() => onMove(tab.id)} type="button">
                <Flex>
                  <Flex.Item padding="0 x-small 0 0" margin="0 0 xxx-small 0">
                    <IconUpdownLine />
                  </Flex.Item>
                  <Flex.Item>{I18n.t('Move')}</Flex.Item>
                </Flex>
              </Menu.Item>
            </Menu>
          )}
        </Flex>
      </View>
    )
  },
)

NavItem.displayName = 'NavItem'

// Make up and down change focus in list. Moving items with keyboard is
// already handled by react-beautiful-dnd.
function useUpDownKeysChangeFocusHandler({
  enabledTabs,
  disabledTabs,
  isDragging,
  tabRefs,
}: {
  enabledTabs: NavigationTab[]
  disabledTabs: NavigationTab[]
  isDragging: boolean
  tabRefs: React.RefObject<{[key: string]: HTMLDivElement | null}>
}) {
  useKeyDownEventHandler(
    (e: KeyboardEvent) => {
      if (e.key !== 'ArrowUp' && e.key !== 'ArrowDown') return
      if (isDragging) return

      const currentTabId = (e.target as HTMLElement)
        .closest('.course-nav-tab')
        ?.querySelector('[id^="nav_edit_tab_id_"]')
        ?.id?.replace('nav_edit_tab_id_', '')

      if (!currentTabId) return

      const allTabs = [...enabledTabs, ...disabledTabs]
      const currentIndex = allTabs.findIndex(tab => tab.id.toString() === currentTabId)

      if (currentIndex === -1) return

      e.preventDefault()
      const nextIndex = currentIndex + (e.key === 'ArrowUp' ? -1 : 1)
      const nextTabId = allTabs[nextIndex]?.id
      if (nextTabId) {
        tabRefs.current?.[`tab-${nextTabId}`]?.focus()
      }
    },
    [enabledTabs, disabledTabs, isDragging],
  )
}

function useKeyDownEventHandler(handler: (e: KeyboardEvent) => void, deps: any[] = []) {
  useEffect(() => {
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, deps)
}

/*
 * Tray for moving a navigation item within its list (enabled tabs list or disabled tabs list).
 */
function MoveNavItemTray({
  tabsList,
  tabId,
  onExited,
  onMoveSuccess,
}: {
  tabsList: NavigationTab[]
  tabId: string
  onExited: () => void
  onMoveSuccess: (result: MoveItemTrayResult) => void
}) {
  const makeMoveTrayItem = (tab: NavigationTab) => ({id: tab.id, title: tab.label})
  const tabToMove = tabsList.find(t => t.id === tabId)
  if (!tabToMove) {
    return null
  }
  const siblingTabs = tabsList.filter(t => t.id !== tabId && !t.immovable)

  return (
    <MoveItemTray
      title={I18n.t('Move Navigation Item')}
      items={[makeMoveTrayItem(tabToMove)]}
      moveOptions={{siblings: siblingTabs.map(makeMoveTrayItem)}}
      onMoveSuccess={onMoveSuccess}
      onExited={onExited}
    />
  )
}
