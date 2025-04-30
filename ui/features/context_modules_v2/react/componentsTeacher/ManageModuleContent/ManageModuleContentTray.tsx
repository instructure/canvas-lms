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
import {ModuleAction} from '../../utils/types'
import {queryClient} from '@canvas/query'
import {useModules} from '../../hooks/queries/useModules'
import {useModuleItems} from '../../hooks/queries/useModuleItems'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useContextModule} from '../../hooks/useModuleContext'
import {
  createModuleItemOrder,
  createModuleContentsOrder,
  createModuleOrder,
  getTrayTitle,
  getErrorMessage,
} from '../../handlers/manageModuleContentsHandlers'

import ModuleSelect from './ModuleSelect'
import PositionSelect from './PositionSelect'
import ReferenceSelect from './ReferenceSelect'
import TrayFooter from './TrayFooter'

const I18n = createI18nScope('context_modules_v2')

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
  const [selectedModule, setSelectedModule] = useState<string>('')
  const [selectedPosition, setSelectedPosition] = useState<string>('top')
  const [selectedItem, setSelectedItem] = useState<string>('')
  const [itemTitle, setItemTitle] = useState<string>('')

  const {courseId} = useContextModule()

  const {data: modulesData} = useModules(courseId || '')

  const {data: moduleItemsData} = useModuleItems(
    selectedModule,
    !!selectedModule &&
      (moduleAction === 'move_module_item' ||
        moduleAction === 'move_module_contents' ||
        moduleAction === 'move_module'),
  )
  // Also fetch module items for the source module when moving module contents
  // or when moving an individual module item (to get its source module)
  const {data: sourceModuleItemsData} = useModuleItems(
    sourceModuleId,
    !!sourceModuleId &&
      (moduleAction === 'move_module_contents' || moduleAction === 'move_module_item'),
  )

  // Reset selections when tray opens
  useEffect(() => {
    if (isOpen) {
      setSelectedModule('')
      setSelectedPosition('top')
      setSelectedItem('')

      if (moduleAction === 'move_module_item') {
        setItemTitle(moduleItemTitle || '')
      } else if (moduleAction === 'move_module') {
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
        moduleAction === 'move_module_item' ||
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
          (moduleAction === 'move_module_item' || moduleAction === 'move_module_contents') &&
          (!moduleItemsData?.moduleItems || moduleItemsData.moduleItems.length === 0)
        ) {
          setSelectedPosition('top')
        }

        // If we're moving a module and the position is 'before' or 'after',
        // we need to set the selected module as the target module
        if (
          moduleAction === 'move_module' &&
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
    const sourceItems: string[] = sourceModuleItemsData?.moduleItems
      ? sourceModuleItemsData.moduleItems.map(item => item._id)
      : []
    return createModuleContentsOrder(
      sourceItems,
      moduleItemsData.moduleItems,
      selectedPosition,
      selectedItem,
    )
  }, [
    moduleItemsData?.moduleItems,
    sourceModuleItemsData?.moduleItems,
    selectedPosition,
    selectedItem,
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

  const invalidateApplicableQueries = () => {
    if (!courseId) return

    if (moduleAction === 'move_module_item' || moduleAction === 'move_module_contents') {
      queryClient.invalidateQueries({queryKey: ['moduleItems', selectedModule]})
      if (sourceModuleId !== selectedModule) {
        queryClient.invalidateQueries({queryKey: ['moduleItems', sourceModuleId]})
      }
    } else if (moduleAction === 'move_module') {
      queryClient.invalidateQueries({queryKey: ['modules', courseId]})
    }
  }

  const handleMove = async () => {
    try {
      if (moduleAction === 'move_module_item') {
        await submitReorderRequest(
          `${ENV.CONTEXT_URL_ROOT}/modules/${selectedModule}/reorder`,
          moduleItemOrder,
        )
        showFlashSuccess(I18n.t('Item moved successfully'))
      } else if (moduleAction === 'move_module_contents') {
        await submitReorderRequest(
          `${ENV.CONTEXT_URL_ROOT}/modules/${selectedModule}/reorder`,
          moduleContentsOrder,
        )
        showFlashSuccess(I18n.t('Module contents moved successfully'))
      } else if (moduleAction === 'move_module') {
        await submitReorderRequest(`${ENV.CONTEXT_URL_ROOT}/modules/reorder`, moduleOrder)
        showFlashSuccess(I18n.t('Module moved successfully'))
      }

      invalidateApplicableQueries()
      onClose()
    } catch {
      showFlashError(getErrorMessage(moduleAction))
    }
  }

  const getTitle = useMemo(() => getTrayTitle(moduleAction || null), [moduleAction])

  return (
    <Tray label={getTitle} open={isOpen} onDismiss={onClose} placement="end" size="small">
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
        {moduleAction !== 'move_module' && (
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
