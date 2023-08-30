// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import canvas from '@instructure/canvas-theme'
import canvasHighContrast from '@instructure/canvas-high-contrast-theme'
import {Flex} from '@instructure/ui-flex'
import {NumberInput} from '@instructure/ui-number-input'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_paces_flaggable_number_input')

const baseTheme = ENV.use_high_contrast ? canvasHighContrast : canvas
const borderRadiusMedium = baseTheme.variables.borders.radiusMedium

interface ComponentProps {
  readonly label: React.ReactNode | string
  readonly interaction?: 'enabled' | 'disabled' | 'readonly'
  readonly value: string | number
  readonly onChange: (e: React.FormEvent<HTMLInputElement>, value: string) => void
  readonly onBlur?: (e: React.FormEvent<HTMLInputElement>) => void
  readonly onDecrement: (_e: React.FormEvent<HTMLInputElement>, direction: number) => void
  readonly onIncrement: (_e: React.FormEvent<HTMLInputElement>, direction: number) => void
  readonly showTooltipOn?: 'click' | 'hover' | 'focus' | ('click' | 'hover' | 'focus')[]
  readonly showFlag?: boolean
}

export const FlaggableNumberInput = ({
  label,
  interaction,
  value,
  onChange,
  onBlur,
  onDecrement,
  onIncrement,
  showTooltipOn,
  showFlag = false,
}: ComponentProps) => {
  return (
    <Flex as="div" wrap="no-wrap" justifyItems="end">
      {showFlag && (
        <Flex.Item align="stretch">
          <AccessibleContent alt={I18n.t('Unsaved change')}>
            <View
              as="div"
              display="inline-block"
              background="brand"
              width="11px"
              height="100%"
              borderRadius="medium 0 0 medium"
              borderWidth="small 0 small small"
            />
          </AccessibleContent>
        </Flex.Item>
      )}
      <Flex.Item>
        <Tooltip
          placement="top"
          color="primary"
          renderTip={I18n.t('You cannot edit a locked pace')}
          on={showTooltipOn}
        >
          <NumberInput
            renderLabel={label}
            interaction={interaction}
            width="5.5rem"
            value={value}
            onChange={onChange}
            onBlur={onBlur}
            onDecrement={onDecrement}
            onIncrement={onIncrement}
            display="inline-block"
            themeOverride={{
              borderRadius: showFlag
                ? `0 ${borderRadiusMedium} ${borderRadiusMedium} 0`
                : undefined,
            }}
            data-testid="flaggable-number-input"
          />
        </Tooltip>
      </Flex.Item>
    </Flex>
  )
}
