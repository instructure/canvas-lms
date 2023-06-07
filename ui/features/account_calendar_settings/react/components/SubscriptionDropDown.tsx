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

import React, {useState, useEffect} from 'react'

import {Text} from '@instructure/ui-text'
import {Select} from '@instructure/ui-select'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('account_calendar_settings_account_calendar_item_dropdown')

const {Option} = Select as any

type SubscriptionOption = {
  id: string
  value: boolean
  label: string
  description: string
}

export type ComponentProps = {
  readonly accountId: number
  readonly autoSubscription: boolean
  readonly disabled: boolean
  readonly onChange: (id: number, autoSubscription: boolean) => void
}

const SUBSCRIPTION_OPTIONS: SubscriptionOption[] = [
  {
    id: '1',
    value: true,
    label: I18n.t('Auto subscribe'),
    description: I18n.t('Calendar automatically appears in user\'s "Other Calendars" list.'),
  },
  {
    id: '2',
    value: false,
    label: I18n.t('Manual subscribe'),
    description: I18n.t('Users can add this calendar to their "Other Calendars" list.'),
  },
]

const SubscriptionDropDown: React.FC<ComponentProps> = ({
  accountId,
  autoSubscription,
  disabled,
  onChange,
}) => {
  const [isShowingOptions, setIsShowingOptions] = useState(false)
  const [highlightedOptionId, setHighlightedOptionId] = useState<string | null>(null)
  const [selectedOption, setSelectedOption] = useState<SubscriptionOption>(SUBSCRIPTION_OPTIONS[1])

  useEffect(() => {
    const newSelectedOption =
      SUBSCRIPTION_OPTIONS.find(option => option.value === autoSubscription) ??
      SUBSCRIPTION_OPTIONS[1]
    setSelectedOption(newSelectedOption)
  }, [autoSubscription])

  const handleSelectOption = (e: any, {id}: {id: string}) => {
    const newSelectedOption =
      SUBSCRIPTION_OPTIONS.find(option => option.id === id) ?? SUBSCRIPTION_OPTIONS[1]
    setSelectedOption(newSelectedOption)
    onChange(accountId, newSelectedOption.value)
    setIsShowingOptions(false)
  }
  const handleHighlightOption = (e: any, {id}: {id: string}) => {
    setHighlightedOptionId(id)
  }

  return (
    <Select
      data-testid="subscription-dropdown"
      placement="bottom start"
      interaction={disabled ? 'disabled' : 'enabled'}
      isShowingOptions={isShowingOptions}
      inputValue={selectedOption.label}
      onRequestShowOptions={() => setIsShowingOptions(true)}
      onRequestHideOptions={() => setIsShowingOptions(false)}
      onRequestSelectOption={handleSelectOption}
      onRequestHighlightOption={handleHighlightOption}
      optionsMaxWidth="400px"
      width="190px"
      renderLabel={
        <ScreenReaderContent>{I18n.t('Calendar subscription options')}</ScreenReaderContent>
      }
    >
      {SUBSCRIPTION_OPTIONS.map(option => {
        return (
          <Option
            label=""
            id={option.id}
            key={option.id}
            isSelected={option.id === selectedOption.id}
            isHighlighted={option.id === highlightedOptionId}
          >
            <Text as="div">{option.label}</Text>
            <Text as="div" weight="light">
              {option.description}
            </Text>
          </Option>
        )
      })}
    </Select>
  )
}

export default SubscriptionDropDown
