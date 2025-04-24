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

import React, {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ModuleAction} from '../../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface PositionSelectProps {
  selectedPosition: string
  onPositionChange: (
    event: React.SyntheticEvent<Element, Event>,
    data: {value?: string | number},
  ) => void
  hasItems: boolean
  moduleAction: ModuleAction | null
  itemTitle: string
}

const PositionSelect: React.FC<PositionSelectProps> = ({
  selectedPosition,
  onPositionChange,
  hasItems,
  moduleAction,
  itemTitle,
}) => {
  const title = useMemo(() => {
    if (moduleAction === 'move_module_item') {
      return I18n.t('Place "%{itemTitle}"', {itemTitle: itemTitle || I18n.t('Item')})
    } else if (moduleAction === 'move_module_contents') {
      return I18n.t('Place Contents')
    } else if (moduleAction === 'move_module') {
      return I18n.t('Place "%{moduleName}"', {moduleName: itemTitle || I18n.t('Module')})
    } else {
      return I18n.t('Place Module')
    }
  }, [moduleAction, itemTitle])

  return (
    <View as="div" margin="medium 0 0 0">
      {(moduleAction === 'move_module' || hasItems) && (
        <SimpleSelect
          renderLabel={hasItems ? title : ''}
          assistiveText={I18n.t('Select position')}
          value={selectedPosition}
          onChange={onPositionChange}
        >
          <SimpleSelect.Option id="top" value="top">
            {I18n.t('At the top')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="before" value="before">
            {I18n.t('Before...')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="after" value="after">
            {I18n.t('After...')}
          </SimpleSelect.Option>
          <SimpleSelect.Option id="bottom" value="bottom">
            {I18n.t('At the bottom')}
          </SimpleSelect.Option>
        </SimpleSelect>
      )}
    </View>
  )
}

export default PositionSelect
