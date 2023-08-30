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

import React from 'react'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEndLine} from '@instructure/ui-icons'
import type {Module} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

// Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Item: FlexItem} = Flex as any

export interface PrerequisiteSelectorProps {
  selection: string
  options: Module[]
  onDropPrerequisite: (index: number) => void
  onUpdatePrerequisite: (module: Module, index: number) => void
  index: number
}

export default function PrerequisiteSelector({
  selection,
  options,
  onDropPrerequisite,
  onUpdatePrerequisite,
  index,
}: PrerequisiteSelectorProps) {
  return (
    <Flex direction="row">
      <FlexItem shouldGrow={true} shouldShrink={true}>
        <CanvasSelect
          id="prerequisite"
          value={selection}
          label={<ScreenReaderContent>{I18n.t('Select Prerequisite')}</ScreenReaderContent>}
          onChange={(event, value) =>
            onUpdatePrerequisite({id: event.target.id, name: value}, index)
          }
        >
          {options.map(module => {
            return (
              <CanvasSelect.Option key={module.name} id={module.id} value={module.name}>
                {module.name}
              </CanvasSelect.Option>
            )
          })}
        </CanvasSelect>
      </FlexItem>
      <FlexItem margin="0 0 0 medium">
        <IconButton
          renderIcon={<IconEndLine color="secondary" />}
          onClick={() => onDropPrerequisite(index)}
          screenReaderLabel={I18n.t('Remove Prerequisite')}
          withBackground={false}
          withBorder={false}
        />
      </FlexItem>
    </Flex>
  )
}
