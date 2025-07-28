/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {NumberInput} from '@instructure/ui-number-input'
import {Flex} from '@instructure/ui-flex'
import {useScope as createI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import NumberHelper from '@canvas/i18n/numberHelper'

const I18n = createI18nScope('speed_grader')

function defaultDurationLate(interval: string, secondsLate: number): number {
  let durationLate = secondsLate / 3600

  if (interval === 'day') {
    durationLate /= 24
  }

  return round(durationLate, 2)
}

type Props = {
  disabled?: boolean
  lateSubmissionInterval: 'day' | 'hour'
  locale: string
  renderLabelBefore: boolean
  secondsLate: number
  onSecondsLateUpdated: (submission: {
    latePolicyStatus: 'late'
    secondsLateOverride: number
  }) => void
  width: string
  visible?: boolean
}

export default function TimeLateInput({
  disabled = false,
  lateSubmissionInterval,
  locale,
  renderLabelBefore,
  secondsLate,
  onSecondsLateUpdated,
  width,
  visible = true,
}: Props) {
  const [numberInputValue, setNumberInputValue] = useState(
    defaultDurationLate(lateSubmissionInterval, secondsLate),
  )
  const [numberInputValueSinceBlur, setNumberInputValueSinceBlur] = useState(numberInputValue)

  const numberInputLabel =
    lateSubmissionInterval === 'day' ? I18n.t('Days late') : I18n.t('Hours late')

  const numberInputText =
    lateSubmissionInterval === 'day'
      ? I18n.t('late_input.days', {one: 'Day', other: 'Days'}, {count: numberInputValue})
      : I18n.t('late_input.hours', {one: 'Hour', other: 'Hours'}, {count: numberInputValue})

  if (!visible) {
    return null
  }

  const handleNumberInputBlur = ({target: {value}}: React.FocusEvent<HTMLInputElement>) => {
    if (!NumberHelper.validate(value)) {
      return
    }

    const parsedValue = NumberHelper.parse(value)
    const roundedValue = round(parsedValue, 2)

    const hasChanged = roundedValue !== numberInputValueSinceBlur
    if (!hasChanged) {
      return
    }

    setNumberInputValueSinceBlur(roundedValue)

    let secondsLateOverride = parsedValue * 3600
    if (lateSubmissionInterval === 'day') {
      secondsLateOverride *= 24
    }

    onSecondsLateUpdated({
      latePolicyStatus: 'late',
      secondsLateOverride: Math.trunc(secondsLateOverride),
    })
  }

  return (
    <span className="NumberInput__Container NumberInput__Container-LeftIndent">
      <Flex direction={renderLabelBefore ? 'row-reverse' : 'row'}>
        <Flex.Item>
          <NumberInput
            allowStringValue={true}
            value={numberInputValue}
            interaction={disabled ? 'disabled' : 'enabled'}
            display="inline-block"
            renderLabel={<ScreenReaderContent>{numberInputLabel}</ScreenReaderContent>}
            min="0"
            onBlur={handleNumberInputBlur}
            onChange={(_e, value) => {
              const inputValue = parseInt(value, 10)
              setNumberInputValue(Number.isNaN(inputValue) ? 0 : inputValue)
            }}
            showArrows={false}
            width={width}
          />
        </Flex.Item>
        <Flex.Item>
          <PresentationContent>
            <View as="div" margin="0 small">
              <Text>{numberInputText}</Text>
            </View>
          </PresentationContent>
        </Flex.Item>
      </Flex>
    </span>
  )
}
