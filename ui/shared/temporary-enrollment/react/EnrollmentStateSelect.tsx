/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {uid} from '@instructure/uid'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconInfoLine} from '@instructure/ui-icons'
import ToolTipWrapper from './ToolTipWrapper'
import {Flex} from '@instructure/ui-flex'
import {MODULE_NAME, TOOLTIP_MAX_WIDTH} from './types'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {createAnalyticPropsGenerator} from './util/analytics'

const I18n = useI18nScope('temporary_enrollment')

// initialize analytics props
const analyticProps = createAnalyticPropsGenerator(MODULE_NAME)

export type EnrollmentStateOption = 'deleted' | 'completed' | 'inactive'
type EnrollmentState = {
  value: EnrollmentStateOption
  label: string
}
export const enrollmentStates: EnrollmentState[] = [
  {value: 'deleted', label: I18n.t('Deleted')},
  {value: 'completed', label: I18n.t('Completed')},
  {value: 'inactive', label: I18n.t('Inactive')},
]
export function getLabelForState(value: EnrollmentStateOption): string {
  return enrollmentStates.find(state => state.value === value)?.label || value
}

interface SelectData {
  value?: string | number
  id?: string
}

interface Props {
  label?: string
  placeholder?: string
  onChange?: (selectedOption: EnrollmentStateOption) => void
  value?: EnrollmentStateOption
}

export default function EnrollmentStateSelect(props: Props) {
  const placeholder = props.placeholder || I18n.t('Begin typing to search')
  const [selectedOption, setSelectedOption] = useState<EnrollmentStateOption>(
    props.value || 'deleted'
  )

  const handleSelect = (event: React.SyntheticEvent, data: SelectData) => {
    const selectedValue = data.value as EnrollmentStateOption
    const selectedState = enrollmentStates.find(state => state.value === selectedValue)

    if (selectedState) {
      setSelectedOption(selectedState.value)
      props.onChange?.(selectedState.value)
    }
  }

  const tipText = (
    <View as="div" textAlign="center" maxWidth={TOOLTIP_MAX_WIDTH}>
      <Text size="small">
        {I18n.t('The desired enrollment state to apply after the “Until” date and time passes.')}
      </Text>
    </View>
  )

  const renderLabel = () => {
    return (
      <Flex alignItems="start" gap="x-small">
        <Flex.Item shouldShrink={true}>{props.label}</Flex.Item>
        <Flex.Item>
          <ToolTipWrapper positionTop="-.25em">
            <Tooltip renderTip={tipText} on={['click', 'hover', 'focus']} placement="top">
              <IconButton
                renderIcon={IconInfoLine}
                size="small"
                margin="none"
                withBackground={false}
                withBorder={false}
                screenReaderLabel={I18n.t('Toggle tooltip')}
                {...analyticProps('TooltipState')}
              />
            </Tooltip>
          </ToolTipWrapper>
        </Flex.Item>
      </Flex>
    )
  }

  return (
    <SimpleSelect
      renderLabel={renderLabel}
      placeholder={placeholder}
      assistiveText={I18n.t('Use arrow keys to navigate options')}
      value={selectedOption}
      onChange={handleSelect}
    >
      {enrollmentStates.map((state, index) => (
        <SimpleSelect.Option key={uid(`opt-${index}`)} id={`opt-${index}`} value={state.value}>
          {state.label}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}
