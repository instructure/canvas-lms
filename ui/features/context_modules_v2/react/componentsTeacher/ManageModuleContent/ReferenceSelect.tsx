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

import React, {useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Module, ModuleItem, ModuleAction} from '../../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface ReferenceSelectProps {
  moduleAction: ModuleAction | null
  selectedItem: string
  onItemChange: (
    event: React.SyntheticEvent<Element, Event> | null,
    data: {value?: string | number},
  ) => void
  modules: Module[]
  moduleItems?: ModuleItem[]
  sourceModuleId: string
  selectedModule: string
  sourceModuleItemId: string
}

const ReferenceSelect: React.FC<ReferenceSelectProps> = ({
  moduleAction,
  selectedItem,
  onItemChange,
  modules,
  moduleItems,
  sourceModuleId,
  selectedModule,
  sourceModuleItemId,
}) => {
  useEffect(() => {
    if (moduleAction !== 'move_module' && !moduleItems?.find(item => item._id === selectedItem)) {
      onItemChange(null, {
        value: moduleItems?.filter(item => !(item._id === sourceModuleItemId))[0]?._id || '',
      })
    } else if (
      moduleAction === 'move_module' &&
      !modules?.find(module => module._id === selectedItem)
    ) {
      onItemChange(null, {
        value: modules?.filter(module => !(module._id === sourceModuleId))[0]?._id || '',
      })
    }
  }, [
    moduleItems,
    modules,
    selectedItem,
    sourceModuleId,
    selectedModule,
    sourceModuleItemId,
    moduleAction,
    onItemChange,
  ])
  const hasItems = moduleItems && moduleItems.length > 0

  return (
    <View as="div" margin="medium 0 0 0">
      {/* When moving a module, show modules as options
         When moving items or contents, show module items as options*/}
      {moduleAction === 'move_module' ? (
        <SimpleSelect
          renderLabel={hasItems && I18n.t('Select Reference Module')}
          assistiveText={I18n.t('Select a module')}
          value={selectedItem}
          onChange={onItemChange}
        >
          {modules
            .filter(module => module._id !== sourceModuleId)
            .map((module: Module) => (
              <SimpleSelect.Option key={module._id} id={module._id} value={module._id}>
                {module.name}
              </SimpleSelect.Option>
            ))}
        </SimpleSelect>
      ) : (
        hasItems && (
          <SimpleSelect
            renderLabel={hasItems && I18n.t('Select Reference Item')}
            assistiveText={I18n.t('Select an item')}
            value={selectedItem}
            onChange={onItemChange}
          >
            {moduleItems
              // Filter out the source item when in the same module
              .filter(item => !(item._id === sourceModuleItemId))
              .map((item: ModuleItem) => (
                <SimpleSelect.Option key={item._id} id={item._id} value={item._id}>
                  {item.content?.title || 'Untitled Item'}
                </SimpleSelect.Option>
              ))}
          </SimpleSelect>
        )
      )}
    </View>
  )
}

export default ReferenceSelect
