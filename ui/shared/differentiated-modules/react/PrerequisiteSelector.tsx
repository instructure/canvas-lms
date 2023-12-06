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

import React, {useEffect, useRef} from 'react'
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconTrashLine} from '@instructure/ui-icons'
import type {Module} from './types'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('differentiated_modules')

export interface PrerequisiteSelectorProps {
  selection: string
  options: Module[]
  onDropPrerequisite: (index: number) => void
  onUpdatePrerequisite: (module: Module, index: number) => void
  index: number
  focusDropdown?: boolean
  focusDeleteButton?: boolean
}

export default function PrerequisiteSelector({
  selection,
  options,
  onDropPrerequisite,
  onUpdatePrerequisite,
  index,
  focusDropdown = false,
  focusDeleteButton = false,
}: PrerequisiteSelectorProps) {
  const removeButton = useRef<Element | null>(null)
  const dropdown = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    // @ts-expect-error
    focusDeleteButton && removeButton.current?.focus()
  }, [focusDeleteButton, removeButton])

  useEffect(() => {
    focusDropdown && dropdown.current?.focus()
  }, [focusDropdown, dropdown])

  return (
    <Flex direction="row">
      <Flex.Item shouldGrow={true} shouldShrink={true}>
        <CanvasSelect
          id={`prerequisite-${index}`}
          // @ts-expect-error
          inputRef={el => (dropdown.current = el)}
          value={selection}
          label={<ScreenReaderContent>{I18n.t('Select Prerequisite')}</ScreenReaderContent>}
          onChange={(event, value) => {
            const moduleItem = options.find(item => item.name === value)!
            onUpdatePrerequisite(moduleItem, index)
          }}
        >
          {options.map(module => {
            return (
              <CanvasSelect.Option key={module.id} id={module.id} value={module.name}>
                {module.name}
              </CanvasSelect.Option>
            )
          })}
        </CanvasSelect>
      </Flex.Item>
      <Flex.Item margin="0 0 0 medium">
        <IconButton
          elementRef={el => (removeButton.current = el)}
          renderIcon={<IconTrashLine color="error" />}
          onClick={() => onDropPrerequisite(index)}
          screenReaderLabel={I18n.t('Remove %{name} Prerequisite', {
            name: selection,
          })}
          withBackground={false}
          withBorder={false}
        />
      </Flex.Item>
    </Flex>
  )
}
