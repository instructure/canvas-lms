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

import React, {useState, useEffect, useCallback, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tray} from '@instructure/ui-tray'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {CloseButton} from '@instructure/ui-buttons'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {ModuleAction, ModuleItem} from '../../utils/types'
import {queryClient} from '@canvas/query'
import {useModules} from '../../hooks/queries/useModules'
import {getModuleItems, useModuleItems} from '../../hooks/queries/useModuleItems'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useContextModule} from '../../hooks/useModuleContext'
import {
  createModuleItemOrder,
  createModuleContentsOrder,
  createModuleOrder,
  getTrayTitle,
  getErrorMessage,
} from '../../handlers/manageModuleContentsHandlers'
import {
  MODULE_ITEMS,
  MODULES,
  MOVE_MODULE_ITEM,
  MOVE_MODULE_CONTENTS,
  MOVE_MODULE,
} from '../../utils/constants'
import ModuleSelect from './ModuleSelect'
import PositionSelect from './PositionSelect'
import ReferenceSelect from './ReferenceSelect'
import TrayFooter from './TrayFooter'

const I18n = createI18nScope('context_modules_v2')

const MODULE_TARGET_ACTIONS = [MOVE_MODULE_ITEM, MOVE_MODULE_CONTENTS, MOVE_MODULE] as const
const SOURCE_MOVE_ACTIONS = [MOVE_MODULE_CONTENTS, MOVE_MODULE_ITEM] as const

type ModuleTargetAction = (typeof MODULE_TARGET_ACTIONS)[number]
type SourceMoveAction = (typeof SOURCE_MOVE_ACTIONS)[number]

interface ManageModuleContentTrayProps {
  sourceModuleId: string
  sourceModuleTitle: string
  isOpen: boolean
  onClose: () => void
  moduleAction: ModuleAction | null
  moduleItemId?: string
  moduleItemTitle?: string
  sourceModuleItemId?: string
}

const ManageModuleContentTray: React.FC<ManageModuleContentTrayProps> = ({
  sourceModuleId,
  sourceModuleTitle,
  isOpen,
  onClose,
  moduleAction,
  moduleItemId = '',
  moduleItemTitle = '',
  sourceModuleItemId = '',
}) => {
  const [allSourceModuleItems, setAllSourceModuleItems] = useState<ModuleItem[]>([])
  const [selectedModule, setSelectedModule] = useState<string>('')
  const [selectedPosition, setSelectedPosition] = useState<string>('top')
  const [selectedItem, setSelectedItem] = useState<string>('')
  const [itemTitle, setItemTitle] = useState<string>('')
  const {courseId} = useContextModule()
  const {data: modulesData} = useModules(courseId || '')
  const getTitle = useMemo(() => getTrayTitle(moduleAction || null), [moduleAction])

  const canTargetModule =
    !!selectedModule && MODULE_TARGET_ACTIONS.includes(moduleAction as ModuleTargetAction)
  const canFetchSourceItems =
    !!sourceModuleId && SOURCE_MOVE_ACTIONS.includes(moduleAction as SourceMoveAction)

  const {data: moduleItemsData} = useModuleItems(selectedModule, null, canTargetModule)

  // Also fetch module items for the source module when moving module contents
  // or when moving an individual module item (to get its source module)
  const {data: sourceModuleItemsData} = useModuleItems(sourceModuleId, null, canFetchSourceItems)

  useEffect(() => {
    if (!sourceModuleId || MOVE_MODULE_CONTENTS !== moduleAction) return

    let cancelled = false
    ;(async () => {
      let cursor: string | null = null
      const acc: ModuleItem[] = []

      while (!cancelled) {
        const {moduleItems, pageInfo} = await getModuleItems(sourceModuleId, cursor)
        acc.push(...moduleItems)

        if (!pageInfo.hasNextPage) break
        cursor = pageInfo.endCursor
      }

      if (!cancelled) setAllSourceModuleItems(acc)
    })()
    return () => {
      cancelled = true
    }
  }, [sourceModuleId, moduleAction])

  // Reset selections when tray opens
  useEffect(() => {
    if (isOpen) {
      setSelectedModule('')
      setSelectedPosition('top')
      setSelectedItem('')

      if (moduleAction === MOVE_MODULE_ITEM) {
        setItemTitle(moduleItemTitle || '')
      } else if (moduleAction === MOVE_MODULE) {
        setItemTitle(sourceModuleTitle || '')
      }
    }
  }, [isOpen, moduleAction, moduleItemTitle, sourceModuleTitle])

  useEffect(() => {
    if (
      isOpen &&
      modulesData?.pages?.[0]?.modules &&
      modulesData.pages[0].modules.length > 0 &&
      !selectedModule
    ) {
      if (
        moduleAction === MOVE_MODULE_ITEM ||
        (modulesData.pages[0].modules.length > 0 &&
          modulesData.pages[0].modules[0]._id !== sourceModuleId)
      ) {
        setSelectedModule(modulesData.pages[0].modules[0]._id)
      } else if (modulesData.pages[0].modules.length > 0) {
        setSelectedModule(modulesData.pages[0].modules[1]._id)
      } else {
        setSelectedModule('')
      }
    }
  }, [modulesData, selectedModule, sourceModuleId, moduleAction, isOpen])

  const handleModuleChange = useCallback(
    (_event: React.SyntheticEvent<Element, Event>, data: {value?: string | number}) => {
      if (data.value) {
        const moduleId = String(data.value)
        setSelectedModule(moduleId)
        setSelectedItem('')

        // If the selected module has no items, set position to 'top'
        if (
          (moduleAction === MOVE_MODULE_ITEM || moduleAction === MOVE_MODULE_CONTENTS) &&
          (!moduleItemsData?.moduleItems || moduleItemsData.moduleItems.length === 0)
        ) {
          setSelectedPosition('top')
        }

        // If we're moving a module and the position is 'before' or 'after',
        // we need to set the selected module as the target module
        if (
          moduleAction === MOVE_MODULE &&
          (selectedPosition === 'before' || selectedPosition === 'after')
        ) {
          setSelectedItem(moduleId)
        }
      }
    },
    [moduleAction, selectedPosition, moduleItemsData],
  )

  const handlePositionChange = useCallback(
    (_event: React.SyntheticEvent<Element, Event>, data: {value?: string | number}) => {
      if (data.value) {
        const position = String(data.value)
        setSelectedPosition(position)

        if (position === 'top' || position === 'bottom') {
          setSelectedItem('')
        }
      }
    },
    [],
  )

  const handleItemChange = useCallback(
    (_event: React.SyntheticEvent<Element, Event> | null, data: {value?: string | number}) => {
      if (data.value) {
        setSelectedItem(String(data.value))
      }
    },
    [],
  )
  const modules = useMemo(
    () => modulesData?.pages?.flatMap(page => page.modules) || [],
    [modulesData],
  )
  const moduleItemOrder = useMemo(() => {
    return moduleItemsData?.moduleItems
      ? createModuleItemOrder(
          moduleItemId,
          moduleItemsData.moduleItems,
          selectedPosition,
          selectedItem,
        )
      : []
  }, [moduleItemId, moduleItemsData?.moduleItems, selectedPosition, selectedItem])

  const moduleContentsOrder = useMemo(() => {
    if (!moduleItemsData?.moduleItems) return []
    const sourceItems: string[] = allSourceModuleItems.map(item => item._id)

    const order = createModuleContentsOrder(
      sourceItems,
      moduleItemsData?.moduleItems,
      selectedPosition,
      selectedItem,
    )
    return order
  }, [
    moduleItemsData?.moduleItems,
    sourceModuleItemsData?.moduleItems,
    selectedPosition,
    selectedItem,
    sourceModuleId,
  ])

  const moduleOrder = useMemo(() => {
    return createModuleOrder(sourceModuleId, modules, selectedPosition, selectedItem)
  }, [sourceModuleId, modules, selectedPosition, selectedItem])

  const submitReorderRequest = async (url: string, order: string[]) => {
    await doFetchApi({
      path: url,
      method: 'POST',
      body: {
        order: order.join(','),
      },
    })
  }

  const handleMove = async () => {
    try {
      if (moduleAction === MOVE_MODULE_ITEM) {
        await submitReorderRequest(
          `${ENV.CONTEXT_URL_ROOT}/modules/${selectedModule}/reorder`,
          moduleItemOrder,
        )
        showFlashSuccess(I18n.t('Item moved successfully'))
      }

      if (moduleAction === MOVE_MODULE_CONTENTS) {
        await submitReorderRequest(
          `${ENV.CONTEXT_URL_ROOT}/modules/${selectedModule}/reorder`,
          moduleContentsOrder,
        )
        showFlashSuccess(I18n.t('Module contents moved successfully'))
      }

      if (moduleAction === MOVE_MODULE) {
        await submitReorderRequest(`${ENV.CONTEXT_URL_ROOT}/modules/reorder`, moduleOrder)
        showFlashSuccess(I18n.t('Module moved successfully'))
      }

      if (moduleAction != MOVE_MODULE) {
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, sourceModuleId]})
        queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL', sourceModuleId]})
        queryClient.invalidateQueries({queryKey: [MODULE_ITEMS, selectedModule]})
        queryClient.invalidateQueries({queryKey: ['MODULE_ITEMS_ALL', selectedModule]})
        queryClient.invalidateQueries({queryKey: [MODULES, courseId]})
      }
      onClose()
    } catch {
      showFlashError(getErrorMessage(moduleAction))
    }
  }

  return (
    <Tray
      label={getTitle}
      open={isOpen}
      onDismiss={onClose}
      placement="end"
      size="small"
      data-testid="manage-module-content-tray"
    >
      <View as="div" padding="medium">
        <View as="div" textAlign="end">
          <CloseButton
            placement="end"
            offset="small"
            onClick={onClose}
            screenReaderLabel={I18n.t('Close')}
          />
        </View>

        <Heading as="h2" level="h3">
          {getTitle}
        </Heading>

        {/* Module Selection - only show for non-module moves */}
        {moduleAction !== MOVE_MODULE && (
          <ModuleSelect
            modules={modules}
            selectedModule={selectedModule}
            onModuleChange={handleModuleChange}
            sourceModuleId={sourceModuleId}
            moduleAction={moduleAction || ''}
          />
        )}

        {/* Position Selection */}
        {selectedModule && (
          <PositionSelect
            selectedPosition={selectedPosition}
            onPositionChange={handlePositionChange}
            hasItems={!!(moduleItemsData?.moduleItems && moduleItemsData.moduleItems.length > 0)}
            moduleAction={moduleAction || null}
            itemTitle={itemTitle || ''}
          />
        )}

        {/* Reference Selection - only show for before/after positions */}
        {/* Reference Selection - this is used for both modules and items */}
        {selectedModule && (selectedPosition === 'before' || selectedPosition === 'after') && (
          <ReferenceSelect
            moduleAction={moduleAction || null}
            selectedItem={selectedItem}
            onItemChange={handleItemChange}
            modules={modules}
            moduleItems={moduleItemsData?.moduleItems}
            sourceModuleId={sourceModuleId}
            selectedModule={selectedModule}
            sourceModuleItemId={sourceModuleItemId}
          />
        )}

        {/* Footer with Action Buttons */}
        <TrayFooter onClose={onClose} onMove={handleMove} />
      </View>
    </Tray>
  )
}

export default ManageModuleContentTray
