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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Module} from '../../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleSelectProps {
  modules: Module[]
  selectedModule: string
  onModuleChange: (
    event: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number},
  ) => void
  sourceModuleId: string
  moduleAction: string
}

const ModuleSelect: React.FC<ModuleSelectProps> = ({
  modules,
  selectedModule,
  onModuleChange,
  sourceModuleId,
  moduleAction,
}) => {
  return (
    <View as="div" margin="medium 0 0 0">
      <SimpleSelect
        renderLabel={I18n.t('Modules')}
        assistiveText={I18n.t('Select a destination module')}
        value={selectedModule}
        onChange={onModuleChange}
      >
        {modules
          .filter(module => moduleAction === 'move_module_item' || module._id !== sourceModuleId)
          .map((module: Module) => (
            <SimpleSelect.Option key={module._id} id={module._id} value={module._id}>
              {module.name}
            </SimpleSelect.Option>
          ))}
      </SimpleSelect>
    </View>
  )
}

export default ModuleSelect
